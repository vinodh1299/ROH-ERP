require('dotenv').config();
require('./ops/production_guard')('clean_for_demo.js');

const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');

const DB_CONFIG = {
  host: process.env.DB_HOST || '127.0.0.1',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'roh_erp'
};

async function cleanForDemo() {
  console.log('🔄 Connecting to MySQL roh_erp...');
  const conn = await mysql.createConnection(DB_CONFIG);

  try {
    console.log('🧹 Disabling foreign keys and clearing tables...');
    await conn.query('SET FOREIGN_KEY_CHECKS = 0;');

    const tablesToTruncate = [
      'audit_logs',
      'notifications',
      'parental_consents',
      'password_reset_requests',
      'daily_data_sheets',
      'vb_assessments',
      'preference_assessments',
      'iep_reports',
      'therapy_sessions',
      'director_appointments',
      'guardians',
      'medications',
      'medical_histories',
      'session_report_versions',
      'student_therapists',
      'parent_profiles',
      'therapist_profiles',
      'students'
    ];

    for (const tbl of tablesToTruncate) {
      try {
        await conn.query(`TRUNCATE TABLE \`${tbl}\``);
        console.log(`  ✓ Truncated ${tbl}`);
      } catch (err) {
        console.warn(`  ! Could not truncate ${tbl}: ${err.message}`);
      }
    }

    // Clean users table: keep baseline accounts for all 4 roles
    console.log('\n👤 Resetting users table (preserving clean baseline accounts for Admin, Director, Therapist, Parent)...');
    await conn.query('DELETE FROM users');
    await conn.query('ALTER TABLE users AUTO_INCREMENT = 1');

    const adminPass = await bcrypt.hash('admin123', 10);
    const directorPass = await bcrypt.hash('director123', 10);
    const therapistPass = await bcrypt.hash('therapist123', 10);
    const parentPass = await bcrypt.hash('parent123', 10);

    await conn.query(
      `INSERT INTO users (id, name, email, password, role, status, phone) VALUES 
       (1, 'System Administrator', 'admin@roh.com', ?, 'admin', 'Active', '+1 (800) 234-0101'),
       (2, 'Dr. Sterling Vance (BCBA-D)', 'director@roh.com', ?, 'director', 'Active', '+1 (800) 234-0102'),
       (3, 'Dr. Sarah Lee (Lead BCBA)', 'therapist@roh.com', ?, 'therapist', 'Active', '+1 (800) 234-0103'),
       (4, 'Mr. John Wilson', 'parent@roh.com', ?, 'parent', 'Active', '+1 (800) 234-0104')`,
      [adminPass, directorPass, therapistPass, parentPass]
    );
    console.log('  ✓ Preserved baseline accounts:');
    console.log('    - Admin: admin@roh.com / admin123');
    console.log('    - Director: director@roh.com / director123');
    console.log('    - Therapist: therapist@roh.com / therapist123');
    console.log('    - Parent: parent@roh.com / parent123');

    // Ensure clinical_governance_settings has default entry
    const [gov] = await conn.query('SELECT COUNT(*) as c FROM clinical_governance_settings');
    if (gov[0].c === 0) {
      await conn.query(`
        INSERT INTO clinical_governance_settings 
        (id, setting_key, target_mastery_criteria, require_two_therapists, reassessment_frequency, stagnation_alert_days, supervision_ratio_target, dual_signoff_crisis, director_signature_name, director_title, director_bacb_cert, updated_by)
        VALUES 
        (1, 'primary_center_config', '80% across 3 consecutive sessions', 1, 'Every 6 Months', 21, '5.00', 1, 'Dr. Sterling Vance', 'BCBA-D, Clinical Director', 'BACB # 1-19-38291', 2)
      `);
      console.log('  ✓ Initialized default clinical_governance_settings');
    } else {
      console.log('  ✓ clinical_governance_settings intact');
    }

    await conn.query('SET FOREIGN_KEY_CHECKS = 1;');
    console.log('\n✨ Database is now 100% clean and prepared for fresh demo deployment!');

    // Print summary verification
    console.log('\n📊 Current Table Row Counts:');
    const [allTables] = await conn.query('SHOW TABLES');
    for (const t of allTables) {
      const name = Object.values(t)[0];
      const [[{ count }]] = await conn.query(`SELECT COUNT(*) as count FROM \`${name}\``);
      console.log(`  - ${name.padEnd(30)}: ${count} rows`);
    }

  } catch (error) {
    console.error('Error during cleanup:', error);
  } finally {
    await conn.end();
  }
}

cleanForDemo();
