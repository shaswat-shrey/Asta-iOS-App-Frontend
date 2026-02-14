const express = require("express");
const cors = require("cors");
const jwt = require("jsonwebtoken");

const bcrypt = require("bcrypt");
const { exec } = require("child_process");
const fs = require("fs");
const path = require("path");
const axios = require("axios");
const ffmpeg = require("fluent-ffmpeg");
const ffmpegPath = require("ffmpeg-static");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const crypto = require("crypto");

dotenv.config();
// const jwt = require("jsonwebtoken");
// require("dotenv").config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL pool
const pool = require("./db");

/* =============================
   Authentication Middleware
============================= */
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  console.log("AUTH HEADER:", req.headers.authorization);

  if (!authHeader) {
    return res.status(401).json({ error: "No token provided" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // attach user info to request
    next();
  } catch (err) {
    return res.status(403).json({ error: "Invalid or expired token" });
  }
}


/* =============================
   MongoDB Connection
============================= */

mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log("MongoDB Connected Successfully");
})
  .catch((err) => {
    console.error("MongoDB Connection Error:", err);
});

app.listen(3000, () => {
  console.log("Server is running on port 3000");
});

const RecentImage = require("./models/RecentImage");

app.get("/test-images", async (req, res) => {
  try {
    const images = await RecentImage.find().limit(5);
    res.json(images);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =============================
   Login & Ward APIs
============================= */

app.post("/login", async (req, res) => {
    const { email, password } = req.body;

    try {
        // Find user + password hash
        const result = await pool.query(`
            SELECT 
                u.id AS user_id,
                u.display_name,
                a.hashed_password
            FROM "User" u
            JOIN "Account" a
            ON u.id = a.user_id
            WHERE u.email = $1
        `, [email]);

        if (result.rows.length === 0) {
            return res.status(401).json({ error: "User not found" });
        }

        const user = result.rows[0];

        // Compare password
        const validPassword = await bcrypt.compare(
            password,
            user.hashed_password
        );

        if (!validPassword) {
            return res.status(401).json({ error: "Invalid password" });
        }

        // Get organisation of user
        const orgResult = await pool.query(`
            SELECT org_id
            FROM "UserRoleOrg"
            WHERE user_id = $1
        `, [user.user_id]);

        if (orgResult.rows.length === 0) {
            return res.status(403).json({ error: "User not assigned to organisation" });
        }

        const org_id = orgResult.rows[0].org_id; 

        // Return login success
        const token = jwt.sign(
            {
                user_id: user.user_id,
                org_id: org_id,
                display_name: user.display_name
            },
            process.env.JWT_SECRET,
            { expiresIn: "8h" }
        );

        res.json({
        message: "Login successful",
        token
        });

    } catch (err) {
        console.error("Login error:", err);
        res.status(500).json({ error: "Server error" });
    }
});

/* =============================
   Ward & Video APIs
============================= */

app.get("/wards", authMiddleware, async (req, res) => {
    const orgId  = req.user.org_id;

    try {
        const result = await pool.query(`
            SELECT ward_id, name, type, capacity, floor
            FROM "Ward"
            WHERE org_id = $1
        `, [orgId]);

        res.json(result.rows);

    } catch (err) {
        console.error("Error fetching wards:", err);
        res.status(500).json({ error: "Server error" });
    }
});

app.get("/ward-details/:wardId", authMiddleware, async (req, res) => {
    const { wardId } = req.params;
    const orgId = req.user.org_id;

    try {
        const result = await pool.query(`
            SELECT 
                b.bed_id,
                b.bed_number,
                b.status AS bed_status,

                p.id AS patient_id,
                p.name AS patient_name,

                rv.id AS vital_id,
                rv."heartRate",
                rv."SpO2",
                rv."NBPSystolic",
                rv."NBPDiastolic",
                rv."respirationRate",
                rv.pulse,
                rv."PVC",
                rv.image

            FROM "Bed" b

            JOIN "Ward" w
                ON b.ward_id = w.ward_id

            LEFT JOIN "Patient" p
                ON b.patient_id = p.id

            LEFT JOIN LATERAL (
                SELECT *
                FROM "RecentVital"
                WHERE "patientId" = p.id
                ORDER BY created_at DESC
                LIMIT 1
            ) rv ON true

            WHERE b.ward_id = $1
            AND w.org_id = $2
            ORDER BY b.bed_number ASC;
        `, [wardId, orgId]);

        res.json(result.rows);

    } catch (err) {
        console.error("Ward details error:", err);
        res.status(500).json({ error: "Server error" });
    }
});

/* =============================
   Video Generation APIs
============================= */

app.post("/generate-video-mongo", authMiddleware, async (req, res) => {
  const { patientId, minutes, frameDuration, quality } = req.body;

  try {
    const fromTime = new Date(Date.now() - minutes * 60 * 1000);

    // Fetch image URLs from Mongo
    const images = await RecentImage.find({
      patientId,
      createdAt: { $gte: fromTime }
    }).sort({ createdAt: 1 });

    if (!images.length) {
      return res.status(404).json({ message: "No images found" });
    }

    //Create temp folder
    const tempDir = path.join(__dirname, "tmp", Date.now().toString());
    fs.mkdirSync(tempDir, { recursive: true });


    // Download each S3 image
    for (let i = 0; i < images.length; i++) {
      const imageUrl = images[i].image;

      const response = await axios({
        url: imageUrl,
        method: "GET",
        responseType: "arraybuffer"
      });

      const frameNumber = String(i + 1).padStart(4, "0");
      fs.writeFileSync(
        path.join(tempDir, `frame_${frameNumber}.jpg`),
        response.data
        );
    //   fs.writeFileSync(
    //     path.join(tempDir, `frame_${i+1}.jpg`),
    //     response.data
    //   );
    }

    // Ensure videos folder exists
    const videosDir = path.join(__dirname, "videos");
    if (!fs.existsSync(videosDir)) {
      fs.mkdirSync(videosDir);
    }

    const outputFileName = `video_${Date.now()}.mp4`;
    const outputPath = path.join(videosDir, outputFileName);

    console.log("frameDuration:", frameDuration);
    console.log("quality:", quality);


    // Generate video using FFmpeg
    // Convert frame duration to fps
    const duration = Number(frameDuration) || 2; // default 2s
    const fps = duration >= 1 ? 1 / duration : 1;
    console.log("calculated fps:", 1 / duration);
    // Set quality level
    let crfValue;

    switch (quality) {
    case "high":
        crfValue = 18;
        break;
    case "medium":
        crfValue = 23;
        break;
    case "low":
        crfValue = 30;
        break;
    default:
        crfValue = 23;
    }
    console.log("TempDir:", tempDir);
    console.log("Files:", fs.readdirSync(tempDir));

    ffmpeg()
      .input(path.join(tempDir, "frame_%04d.jpg"))
      .inputOptions([
        "-f image2",
        `-framerate ${fps}`,
        "-start_number 1"
    ]) // adjust FPS if needed
      .outputOptions([
        "-c:v libx264",
        `-crf ${crfValue}`,
        "-pix_fmt yuv420p",
        "-movflags +faststart",
        "-vf",
        `scale=trunc(iw/2)*2:trunc(ih/2)*2,setpts=${frameDuration}*PTS`
      ])
      .setFfmpegPath(ffmpegPath)
      .on("start", (commandLine) => {
          console.log("FFmpeg command:", commandLine);
      })
      .on("stderr", (stderrLine) => {
            console.log("FFmpeg stderr:", stderrLine);
      })
      .on("error", (err) => {
            console.error("FFmpeg Error:", err.message);

            if (!res.headersSent) {
            return res.status(500).json({ error: "Video generation failed" });
            }
     })
      .on("end", () => {
        fs.rmSync(tempDir, { recursive: true, force: true });

        if (!res.headersSent) {
        res.json({
            videoUrl: `http://localhost:3000/videos/${outputFileName}`
        });
        }
        // Auto delete video after 10 minutes
        const DELETE_AFTER = 10 * 60 * 1000; // 10 minutes

        setTimeout(() => {
            const fullPath = path.join(videosDir, outputFileName);

            if (fs.existsSync(fullPath)) {
            fs.unlinkSync(fullPath);
            console.log(`Deleted video: ${outputFileName}`);
             }
        }, DELETE_AFTER);
     })
      .save(outputPath);
  } catch (error) {
    console.error("Server Error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.use("/videos", express.static(path.join(__dirname, "videos")));
//#######################################################################################################################
/* =============================
   Discharge Patient API
============================= */

app.post("/discharge", authMiddleware, async (req, res) => {
  const { bedNumber } = req.body;
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    // 1️⃣ Remove patient from bed
    const result = await client.query(
      `
      UPDATE "Bed"
      SET patient_id = NULL,
          status = 'available'
      WHERE bed_number = $1
      RETURNING *
      `,
      [bedNumber]
    );

    if (result.rowCount === 0) {
      throw new Error("Bed not found");
    }

    await client.query("COMMIT");

    res.json({ message: "Patient discharged successfully" });

  } catch (err) {
    await client.query("ROLLBACK");
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

/* =============================
    Add Mock Patient API
============================= */



// app.post("/add-patient", async (req, res) => {
//   const { bedNumber, issueText, hospitalId, wardId } = req.body;
//   const client = await pool.connect();

//   try {
//     await client.query("BEGIN");

//     if (!hospitalId) {
//       throw new Error("Hospital ID is required");
//     }

//     const patientId = crypto.randomUUID();

//     // 2️⃣ Create Mock Patient (let DB generate id + timestamps)
//     const patientInsert = await client.query(
//       `
//       INSERT INTO "Patient" (
//         id,
//         hospital_id,
//         name,
//         dob,
//         "genderId",
//         "aadhar_Number",
//         phone_number
//       )
//       VALUES (
//         $1,
//         $2,
//         'Jane Smith',
//         '2000-01-01',
//         1,
//         '000003200000',
//         '9999999999'
//       )
//       RETURNING id
//       `,
//       [patientId, hospitalId]
//     );
//     const allergyId = crypto.randomUUID();
//     // 3️⃣ Create Allergy (let DB generate allergy_id)
//     const allergyInsert = await client.query(
//       `
//       INSERT INTO "Allergy" (
//         allergy_id,
//         name,
//         description,
//         severity
//       )
//       VALUES (
//         $1,
//         'Custom Issue',
//         $2,
//         'Unknown'
//       )
//       RETURNING allergy_id
//       `,
//       [allergyId, issueText]
//     );
//     const patientAllergyId = crypto.randomUUID();
//     // 4️⃣ Create PatientAllergy relation
//     await client.query(
//       `
//       INSERT INTO "PatientAllergy" (
//         pa_id,
//         patient_id,
//         allergy_id
//       )
//       VALUES ($1, $2, $3)
//       `,
//       [patientAllergyId, patientId, allergyId]
//     );

//     // 5️⃣ Assign Bed
//     const bedUpdate = await client.query(
//     `
//     UPDATE "Bed"
//     SET patient_id = $1,
//         status = 'occupied'
//     WHERE bed_number = $2
//         AND ward_id = $3
//         AND patient_id IS NULL
//     RETURNING *
//     `,
//     [patientId, bedNumber, wardId]
//     );

//     if (bedUpdate.rowCount === 0) {
//     throw new Error("Bed already occupied or not found in this ward");
//     }

//     await client.query("COMMIT");

//     res.json({
//       message: "Patient added successfully",
//       patientId: patientId
//     });

//   } catch (err) {
//     await client.query("ROLLBACK");
//     console.error("🔥 ADD PATIENT FULL ERROR:");
//     console.error("ADD PATIENT ERROR:", err);
//     res.status(500).json({ error: err.message });
//   } finally {
//     client.release();
//   }
// });
