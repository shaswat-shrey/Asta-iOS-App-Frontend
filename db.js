const { Pool } = require("pg");

const pool = new Pool({
  user: "postgres",
  host: "astahealth-database.clw6w66qo9az.ap-south-1.rds.amazonaws.com",
  database: "hospital_db",
  password: "astahealth3440",
  port: 5432,
  ssl: {
    rejectUnauthorized: false,
  }
});


module.exports = pool;
