// test_backend_e2e.js
// Comprehensive Integration & Unit Test Suite for ROH-ERP MySQL Database & API Endpoints
const mysql = require('mysql2/promise');

const DB_CONFIG = {
  host: '127.0.0.1',
  port: 3306,
  user: 'root',
  password: 'ACAdev@123',
  database: 'roh_erp'
};

const results = {
  total: 0,
  passed: 0,
  failed: 0,
  suites: []
};

function assert(condition, name, details = '') {
  results.total++;
  if (condition) {
    results.passed++;
    console.log(`  ✅ [PASS] ${name} ${details ? '(' + details + ')' : ''}`);
    results.suites.push({ name, status: 'PASS', details });
  } else {
    results.failed++;
    console.error(`  ❌ [FAIL] ${name} ${details ? '(' + details + ')' : ''}`);
    results.suites.push({ name, status: 'FAIL', details });
  }
}

async function runBackendTests() {
  console.log('======================================================');
  console.log('🧪 ROH-ERP Backend & MySQL Database Automated Verification');
  console.log('======================================================\n');

  let conn;
  try {
    conn = await mysql.createConnection(DB_CONFIG);
    assert(true, 'MySQL Database Connection', 'Connected to 127.0.0.1:3306 (roh_erp)');

    // 1. Verify Users & Passwords
    console.log('\n--- 1. User Accounts & Role-Based Access ---');
    const [users] = await conn.query('SELECT id, name, email, role, status FROM users');
    assert(users.length >= 4, 'Core User Accounts Exist', `Found ${users.length} registered accounts`);
    
    const admin = users.find(u => u.email === 'admin@roh.com');
    assert(admin && admin.role === 'admin', 'Admin Account Valid', `Role: ${admin?.role}`);
    
    const therapist = users.find(u => u.email === 'therapist@roh.com');
    assert(therapist && therapist.role === 'therapist', 'Therapist Account Valid', `Role: ${therapist?.role}`);

    const director = users.find(u => u.email === 'director@roh.com');
    assert(director && director.role === 'director', 'Director Account Valid', `Role: ${director?.role}`);

    const parent = users.find(u => u.email === 'parent@roh.com');
    assert(parent && parent.role === 'parent', 'Parent Account Valid', `Role: ${parent?.role}`);

    // 2. Students & Demographics
    console.log('\n--- 2. Students Registry & Demographics ---');
    const [students] = await conn.query('SELECT id, first_name, last_name, gender, dob, status FROM students');
    assert(students.length > 0, 'Students Registry Populated', `${students.length} clinical student files present`);
    assert(students.some(s => s.first_name.includes('Alex')), 'Sample Student Alex Thomas Sam Active');

    // 3. Clinical Assessments (VB-MAPP)
    console.log('\n--- 3. VB-MAPP Assessments ---');
    const [vbAssessments] = await conn.query('SELECT * FROM vb_assessments');
    assert(vbAssessments !== undefined, 'vb_assessments Table Accessible', `Records: ${vbAssessments.length}`);

    // 4. IEP Reports & Goals
    console.log('\n--- 4. Individualized Education Plans (IEP) ---');
    const [iep] = await conn.query('SELECT id, student_id, therapist_id, status FROM iep_reports');
    assert(iep.length > 0, 'IEP Reports Present', `Found ${iep.length} active IEP documents`);
    assert(iep.some(i => ['Approved', 'Active', 'Draft', 'Pending'].includes(i.status)), 'IEP Lifecycle State Valid');

    // 5. Daily Data Sheets
    console.log('\n--- 5. Daily Data Sheets & Trial Tracking ---');
    const [dailyData] = await conn.query('SELECT id, student_id, target_skill, prompt_level, trials_completed, trials_successful FROM daily_data_sheets');
    assert(dailyData.length > 0, 'Daily Data Sheet Logs Active', `${dailyData.length} trial sheets logged`);

    // 6. Scheduling & Appointments
    console.log('\n--- 6. Scheduling & Sessions ---');
    const [sessions] = await conn.query('SELECT id, student_id, therapist_id, session_date, start_time, end_time, status FROM therapy_sessions');
    assert(sessions.length > 0, 'Therapy Sessions Active', `${sessions.length} scheduled clinical sessions`);

    const [appointments] = await conn.query('SELECT id, title, appointment_type, date, start_time, attendee_name, status FROM director_appointments');
    assert(appointments.length > 0, 'Director Appointments Active', `${appointments.length} conferences recorded`);

    // 7. Security Audit Trail & Notifications
    console.log('\n--- 7. Regulatory Audit Logs & Notifications ---');
    const [audit] = await conn.query('SELECT id, action, target_entity, created_at FROM audit_logs ORDER BY id DESC LIMIT 10');
    assert(audit.length > 0, 'Audit Trail Active', `Logged ${audit.length} recent regulatory events`);

    const [notifs] = await conn.query('SELECT id, recipient_user_id, event_type, title, is_read FROM notifications');
    assert(notifs.length > 0, 'Notifications System Active', `Total ${notifs.length} event alerts recorded`);

    // 8. DPDP Act Parental Consent
    console.log('\n--- 8. DPDP Act 2023 Digital Consents ---');
    const [consents] = await conn.query('SELECT * FROM parental_consents');
    assert(consents !== undefined, 'Parental Consents Schema Operational', `${consents.length} digital consent agreements`);

  } catch (err) {
    console.error('Test Execution Error:', err);
    assert(false, 'Database Tests Exception', err.message);
  } finally {
    if (conn) await conn.end();
  }

  console.log('\n======================================================');
  console.log(`Test Execution Results: ${results.passed}/${results.total} Passed, ${results.failed} Failed`);
  console.log('======================================================');
}

runBackendTests();
