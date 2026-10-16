// ============================================================================
// ROH-ERP — Database initializer
// Creates any missing tables from schema.sql in the database named in .env.
// Safe to run repeatedly: existing tables and data are never dropped.
//
//   node init_db.js
//
// Optional first admin (only created when no admin account exists yet):
//   ADMIN_NAME="Center Admin" ADMIN_EMAIL=admin@example.org ADMIN_PASSWORD='...' node init_db.js
// ============================================================================

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');

(async () => {
  for (const key of ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME']) {
    if (!process.env[key]) {
      console.error(`❌ ${key} is not set in .env`);
      process.exit(1);
    }
  }

  const conn = await mysql.createConnection({
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '3306'),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    multipleStatements: true,
  });
  console.log(`✅ Connected to ${process.env.DB_NAME} on ${process.env.DB_HOST}`);

  const [before] = await conn.query('SHOW TABLES');
  await conn.query(fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8'));
  const [after] = await conn.query('SHOW TABLES');
  console.log(`📦 Tables: ${before.length} before → ${after.length} after`);

  const { ADMIN_NAME, ADMIN_EMAIL, ADMIN_PASSWORD } = process.env;
  if (ADMIN_EMAIL && ADMIN_PASSWORD) {
    const [admins] = await conn.query("SELECT id FROM users WHERE role = 'admin' LIMIT 1");
    if (admins.length) {
      console.log('ℹ️  An admin account already exists — skipping admin creation.');
    } else {
      const hash = await bcrypt.hash(ADMIN_PASSWORD, 10);
      await conn.query(
        "INSERT INTO users (name, email, password, role, status) VALUES (?, ?, ?, 'admin', 'Active')",
        [ADMIN_NAME || 'System Admin', ADMIN_EMAIL.trim().toLowerCase(), hash]
      );
      console.log(`👤 Created admin account ${ADMIN_EMAIL}`);
    }
  }

  await conn.end();
})().catch(err => {
  console.error('❌ Database init failed:', err.message);
  process.exit(1);
});
