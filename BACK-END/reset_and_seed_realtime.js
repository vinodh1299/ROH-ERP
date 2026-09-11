// reset_and_seed_realtime.js
// Completely purges all data from all tables, resets auto-increment counters,
// and inserts fresh, realistic real-time clinical production data.
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');

const DB_CONFIG = {
  host: '127.0.0.1',
  port: 3306,
  user: 'root',
  password: 'ACAdev@123',
  database: 'roh_erp'
};

async function resetAndSeed() {
  console.log('🔄 Connecting to MySQL roh_erp database...');
  const conn = await mysql.createConnection(DB_CONFIG);

  try {
    console.log('🧹 Disabling foreign key checks and truncating all tables...');
    await conn.query('SET FOREIGN_KEY_CHECKS = 0;');

    const tables = [
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
      'students',
      'users'
    ];

    for (const table of tables) {
      try {
        await conn.query(`TRUNCATE TABLE \`${table}\``);
        console.log(`  ✓ Truncated ${table}`);
      } catch (e) {
        console.warn(`  ! Note on ${table}: ${e.message}`);
      }
    }

    await conn.query('SET FOREIGN_KEY_CHECKS = 1;');
    console.log('✨ All tables cleared successfully.\n');

    // ----------------------------------------------------
    // 1. FRESH CORE USERS (Bcrypt Hashed)
    // ----------------------------------------------------
    console.log('👤 Seeding fresh verified users with secure Bcrypt credentials...');
    const adminPass = await bcrypt.hash('admin123', 10);
    const directorPass = await bcrypt.hash('director123', 10);
    const therapistPass = await bcrypt.hash('therapist123', 10);
    const parentPass = await bcrypt.hash('parent123', 10);

    // ID 1: Admin
    await conn.query(
      `INSERT INTO users (id, name, email, password, role, status, phone) VALUES 
       (1, 'System Administrator', 'admin@roh.com', ?, 'admin', 'Active', '+1 (555) 010-0001')`,
      [adminPass]
    );

    // ID 2: Director
    await conn.query(
      `INSERT INTO users (id, name, email, password, role, status, phone) VALUES 
       (2, 'Dr. Sterling Vance (BCBA-D)', 'director@roh.com', ?, 'director', 'Active', '+1 (555) 010-0002')`,
      [directorPass]
    );

    // ID 3: Primary Therapist
    await conn.query(
      `INSERT INTO users (id, name, email, password, role, status, phone) VALUES 
       (3, 'Dr. Sarah Lee (BCBA)', 'therapist@roh.com', ?, 'therapist', 'Active', '+1 (555) 010-0003')`,
      [therapistPass]
    );

    // ID 4: Parent
    await conn.query(
      `INSERT INTO users (id, name, email, password, role, status, phone) VALUES 
       (4, 'Mr. John Wilson', 'parent@roh.com', ?, 'parent', 'Active', '+1 (555) 010-0004')`,
      [parentPass]
    );

    // Secondary Therapists for Caseload Balance
    const therapist2Pass = await bcrypt.hash('therapist123', 10);
    await conn.query(
      `INSERT INTO users (id, name, email, password, role, status, phone) VALUES 
       (5, 'Dr. Michael Chen (Senior Analyst)', 'mchen@roh.com', ?, 'therapist', 'Active', '+1 (555) 010-0005'),
       (6, 'Priya Sharma (RBT Specialist)', 'psharma@roh.com', ?, 'therapist', 'Active', '+1 (555) 010-0006')`,
      [therapist2Pass, therapist2Pass]
    );

    // ----------------------------------------------------
    // 2. THERAPIST PROFILES
    // ----------------------------------------------------
    console.log('🩺 Seeding therapist clinical profiles...');
    await conn.query(`
      INSERT INTO therapist_profiles (user_id, employee_id, designation, qualification, license_number, active_caseload, specialties, about) VALUES
      (3, 'EMP-1001', 'Lead Clinical BCBA', 'Ph.D. Applied Behavior Analysis', 'BACB-098234', 8, 'Early Verbal Milestones, Functional Communication Training', 'Over 12 years of specialized ABA practice with early learners.'),
      (5, 'EMP-1002', 'Senior Behavior Analyst', 'M.S. Applied Behavior Analysis', 'BACB-112093', 9, 'Discrete Trial Training, Social Dynamics, EESA', 'Specialist in verbal milestone advancement and pediatric transition programs.'),
      (6, 'EMP-1003', 'Registered Behavior Technician', 'B.S. Psychology, Certified RBT', 'RBT-234901', 6, 'Natural Environment Teaching (NET), Sensory Regulation', 'Passionate about sensory integration and play-based functional language.')
    `);

    // ----------------------------------------------------
    // 3. PARENT PROFILE
    // ----------------------------------------------------
    console.log('👨‍👩‍👦 Seeding parent profile...');
    await conn.query(`
      INSERT INTO parent_profiles (user_id, secondary_phone, street_address, city, state, postal_code, occupation, preferred_communication) VALUES
      (4, '+1 (555) 019-9944', '742 Evergreen Terrace', 'Springfield', 'OR', '97477', 'Bio-Medical Engineer', 'Email')
    `);

    // ----------------------------------------------------
    // 4. STUDENTS & CLINICAL ADMISSIONS
    // ----------------------------------------------------
    console.log('🧒 Seeding clinical students...');
    await conn.query(`
      INSERT INTO students (id, first_name, last_name, dob, gender, blood_group, program, primary_diagnosis, primary_therapist_id, status) VALUES
      (1, 'Alex', 'Thomas Sam', '2019-04-12', 'Male', 'O+', 'Comprehensive ABA Early Intervention', 'Autism Spectrum Disorder (Level 2)', 3, 'Active'),
      (2, 'Romeo', 'Alex A', '2018-09-20', 'Male', 'A+', 'Verbal Behavior Intensive Program', 'Autism Spectrum Disorder (Level 1)', 5, 'Active'),
      (3, 'Matt', 'Dickerson', '2017-11-05', 'Male', 'B+', 'Social Communication & NET', 'Autism Spectrum Disorder (Level 2)', 3, 'Active'),
      (4, 'Jemi', 'Wilson', '2020-02-14', 'Female', 'O-', 'Early Echoic & Mand Training', 'Global Developmental Delay / ASD', 6, 'Active'),
      (5, 'Maya', 'Patel', '2019-08-30', 'Female', 'AB+', 'Pediatric Sensory & Behavior Modulation', 'ASD with Sensory Processing Sensitivity', 5, 'Active')
    `);

    // Guardians
    await conn.query(`
      INSERT INTO guardians (student_id, guardian_priority, relationship, first_name, last_name, phone, email, is_emergency_contact) VALUES
      (1, 1, 'Father', 'John', 'Wilson', '+1 (555) 010-0004', 'parent@roh.com', 1),
      (1, 2, 'Mother', 'Elena', 'Wilson', '+1 (555) 019-9944', 'elena.wilson@example.com', 1),
      (4, 1, 'Mother', 'Clara', 'Wilson', '+1 (555) 019-5521', 'clara.w@example.com', 1)
    `);

    // Medical Histories
    await conn.query(`
      INSERT INTO medical_histories (student_id, pediatrician_name, pediatrician_phone, has_allergies, allergy_details, eating_habits, sleeping_habits, has_seizures) VALUES
      (1, 'Dr. Katherine Price, MD', '+1 (555) 019-1122', 1, 'Peanuts, Tree Nuts. Mild reaction.', 'Selective with food textures, prefers crunchy items.', 'Sleeps 9 hours regularly, uses white noise machine.', 0),
      (2, 'Dr. Robert Ross, MD', '+1 (555) 014-9988', 1, 'Penicillin', 'Balanced dietary intake, independent eater.', 'Consistent sleep schedule.', 0)
    `);

    // ----------------------------------------------------
    // 5. VB-MAPP ASSESSMENTS (Real-time baseline & domain points)
    // ----------------------------------------------------
    console.log('📊 Seeding real-time VB-MAPP assessment evaluations...');
    await conn.query(`
      INSERT INTO vb_assessments (student_id, therapist_id, assessment_type, assessment_date, level, total_score, max_score, manding_score, tacting_score, echoic_score, intraverbal_score, listener_score, social_score, imitation_score, therapist_notes) VALUES
      (1, 3, 'milestone', '2026-09-10', 2, 26.5, 30.0, 4.5, 4.0, 3.5, 3.0, 4.0, 3.5, 4.0, 'Alex demonstrates rapid acquisition of 2-component mand frames and receptive tact labeling.'),
      (1, 3, 'barriers', '2026-09-10', 2, 11.5, 24.0, 2.0, 1.5, 1.0, 2.5, 1.0, 1.5, 2.0, 'Mild instructional control resistance noted during task transitions. Responds well to visual timers.'),
      (2, 5, 'milestone', '2026-09-08', 3, 29.0, 30.0, 5.0, 4.5, 4.5, 4.0, 5.0, 3.5, 4.5, 'Romeo is progressing through advanced intraverbal categories and peer cooperative play.')
    `);

    // ----------------------------------------------------
    // 6. IEP REPORTS & MULTI-DOMAIN TARGETS
    // ----------------------------------------------------
    console.log('📋 Seeding real-time IEP treatment plans...');
    await conn.query(`
      INSERT INTO iep_reports (id, student_id, therapist_id, title, cycle_term, status, director_signed_by, director_signed_at, manding_score, tacting_score, listener_score, echoic_score, lrffc_score, goals_summary, director_notes) VALUES
      (1, 1, 3, 'Q3-2026 Comprehensive Verbal Behavior Plan', 'Q3 2026', 'Active', 2, NOW(), 4.5, 4.0, 4.0, 3.5, 3.0, 'Focus on spontaneous 3-word mands, receptive prepositions, and peer greeting response.', 'Approved. Significant progress noted across verbal operants since baseline.'),
      (2, 4, 6, 'Annual IEP Early Communication Protocol', '2026-2027', 'Pending Approval', NULL, NULL, 2.0, 1.5, 2.0, 2.5, 1.0, 'Targeting basic sign and vocal approximations for snack and preferred toys.', 'Pending final review by Clinical Director Dr. Vance.')
    `);

    // ----------------------------------------------------
    // 7. DAILY DATA SHEETS & DISCRETE TRIALS
    // ----------------------------------------------------
    console.log('📝 Seeding real-time daily trial data sheets...');
    await conn.query(`
      INSERT INTO daily_data_sheets (student_id, therapist_id, session_date, domain, target_skill, prompt_level, trials_completed, trials_successful, notes) VALUES
      (1, 3, CURRENT_DATE(), 'Manding', 'Spontaneous Request for Water/Juice', 'Independent', 10, 9, 'Child produced clear vocal approximations without prompting in 9/10 opportunities.'),
      (1, 3, CURRENT_DATE(), 'Tacting', 'Common Household Objects (Cup, Spoon, Ball)', 'Verbal', 12, 10, 'Required initial phonetic prompt on "spoon", then mastered independently.'),
      (1, 3, CURRENT_DATE(), 'Motor Imitation', 'Fine Motor: Clapping & Stacking Blocks', 'Independent', 8, 8, '100% accuracy during structured table time.'),
      (2, 5, CURRENT_DATE(), 'Intraverbal', 'Fill-in-the-blanks from songs & rhymes', 'Gestural', 15, 13, 'Excellent attention and vocal reciprocity.')
    `);

    // ----------------------------------------------------
    // 8. THERAPY SESSIONS (Daily Timetable)
    // ----------------------------------------------------
    console.log('⏰ Seeding daily therapy sessions...');
    await conn.query(`
      INSERT INTO therapy_sessions (student_id, therapist_id, session_date, start_time, end_time, program_title, status, room) VALUES
      (1, 3, CURRENT_DATE(), '09:00:00', '10:30:00', 'Verbal Behavior / DTT', 'completed', 'Clinic Room 102'),
      (1, 3, CURRENT_DATE(), '11:00:00', '12:00:00', 'Social & NET Play', 'upcoming', 'Sensory Gym'),
      (2, 5, CURRENT_DATE(), '10:00:00', '11:30:00', 'Intensive Intraverbal Training', 'upcoming', 'Clinic Room 105'),
      (4, 6, CURRENT_DATE(), '13:00:00', '14:30:00', 'Early Echoic & Sensory Integration', 'upcoming', 'Early Learner Suite')
    `);

    // ----------------------------------------------------
    // 9. DIRECTOR CONFERENCES & APPOINTMENTS
    // ----------------------------------------------------
    console.log('📅 Seeding director conference appointments...');
    await conn.query(`
      INSERT INTO director_appointments (director_user_id, title, appointment_type, date, start_time, end_time, attendee_name, attendee_role, attendee_phone, attendee_email, location, scheduled_by, status, notes) VALUES
      (2, 'Q3 Progress Evaluation Conference', 'iepReview', CURRENT_DATE(), '02:00 PM', '02:45 PM', 'Mr. John Wilson', 'Parent', '+1 (555) 010-0004', 'parent@roh.com', 'Director Office Suite / Virtual', 'parent', 'confirmed', 'Review Alex Q3 IEP goals and carryover strategies for home.'),
      (2, 'Diagnostic Clinical Intake', 'diagnosticIntake', DATE_ADD(CURRENT_DATE(), INTERVAL 2 DAY), '10:00 AM', '11:00 AM', 'Clara Wilson', 'Parent', '+1 (555) 019-5521', 'clara.w@example.com', 'Consultation Room B', 'admin', 'confirmed', 'Initial diagnostic evaluation and baseline placement for Jemi Wilson.')
    `);

    // ----------------------------------------------------
    // 10. REAL-TIME EVENT NOTIFICATIONS
    // ----------------------------------------------------
    console.log('🔔 Seeding live event notifications across roles...');
    await conn.query(`
      INSERT INTO notifications (recipient_user_id, event_type, title, message, is_read, metadata_json) VALUES
      (2, 'IEP_SUBMITTED', 'New IEP Pending Approval', 'Therapist Dr. Sarah Lee submitted the Q3-2026 IEP for Alex Thomas Sam. Action required for sign-off.', 0, '{"student_id": 1, "iep_id": 1}'),
      (4, 'REPORT_READY', 'Child IEP Progress Plan Activated', 'The Q3-2026 Treatment Plan for Alex Thomas Sam has been reviewed and signed off by Clinical Director Dr. Sterling Vance.', 0, '{"iep_id": 1}'),
      (4, 'APPOINTMENT_SCHEDULED', 'Director Conference Confirmed', 'Your conference with Dr. Sterling Vance is confirmed for today at 02:00 PM in the Director Office Suite.', 0, '{"appointment_id": 1}'),
      (3, 'SESSION_ASSIGNED', 'Clinical Session Scheduled', 'Morning Verbal Behavior / DTT session for Alex Thomas Sam scheduled for 09:00 AM in Room 102.', 1, '{"session_id": 1}')
    `);

    // ----------------------------------------------------
    // 11. REGULATORY AUDIT LOGS (DPDP / FERPA Compliant)
    // ----------------------------------------------------
    console.log('🔒 Seeding regulatory audit logs...');
    await conn.query(`
      INSERT INTO audit_logs (user_id, user_role, action, target_entity, target_id, ip_address, user_agent, details) VALUES
      (1, 'admin', 'SYSTEM_PURGE_AND_RESET', 'system', NULL, '127.0.0.1', 'Antigravity Verified Automation', 'All database tables successfully purged and reseated with production clinical data'),
      (3, 'therapist', 'SAVE_IEP', 'iep_reports', 1, '127.0.0.1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', 'Created Q3-2026 Comprehensive Verbal Behavior Plan'),
      (2, 'director', 'SIGN_OFF_IEP', 'iep_reports', 1, '127.0.0.1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', 'Director approved and activated IEP report #1'),
      (4, 'parent', 'BOOK_APPOINTMENT', 'director_appointments', 1, '127.0.0.1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', 'Booked Q3 Progress Evaluation Conference with Director')
    `);

    console.log('\n✅ Database reset and real-time data seeding completed successfully!');
  } catch (err) {
    console.error('❌ Error during reset and seed:', err);
  } finally {
    await conn.end();
  }
}

resetAndSeed();
