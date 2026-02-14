const mongoose = require("mongoose");

const RecentImageSchema = new mongoose.Schema(
  {
    image: {
      type: String,
      required: true,
    },
    patientId: {
      type: String,
      required: true,
    },
    hospitalId: {
      type: String,
      required: true,
    },
    orignalImage: {
      type: String,
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// TTL index (48 hours)
RecentImageSchema.index(
  { createdAt: 1 },
  { expireAfterSeconds: 172800 }
);

module.exports = mongoose.model("RecentImage", RecentImageSchema);
