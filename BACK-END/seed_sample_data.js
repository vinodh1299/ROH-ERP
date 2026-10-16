// ============================================================================
// ROH-ERP — Sample data for trying out the portals and graphs
//
// Creates one director, one therapist and one parent (all "(Sample)"), three
// students and ~3 weeks of clinical data (daily data sheets, VB-MAPP milestone,
// barriers, transition, EESA and preference assessments, sessions, IEPs).
// Dates are relative to today so "today" views have data.
//
//   echo '{"director":"...","therapist":"...","parent":"..."}' | node seed_sample_data.js
//   node seed_sample_data.js --remove        # delete all sample data again
//
// Re-running removes the previous sample data first. Real data is never touched:
// only rows linked to the three sample.*@example.com accounts are deleted.
// ============================================================================

require('dotenv').config();
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');

const SAMPLE_USERS = {
  director: { name: 'Dr. Meera Iyer (Sample)', email: 'sample.director@example.com', phone: '+91 98400 00001' },
  therapist: { name: 'Anjali Rao (Sample)', email: 'sample.therapist@example.com', phone: '+91 98400 00002' },
  parent: { name: 'Ravi Sharma (Sample)', email: 'sample.parent@example.com', phone: '+91 98400 00003' },
};

const STUDENT_TABLES = [
  'daily_data_sheets', 'milestone_assessments', 'barriers_assessments', 'transition_assessments',
  'eesa_assessments', 'preference_assessments', 'therapy_sessions', 'iep_reports', 'student_therapists',
  'guardians', 'medical_histories', 'medications', 'parental_consents',
];

const day = offset => {
  const d = new Date();
  d.setDate(d.getDate() + offset);
  return d.toISOString().slice(0, 10);
};

async function readStdinJson() {
  if (process.stdin.isTTY) return {};
  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;
  return raw.trim() ? JSON.parse(raw) : {};
}

async function removeSampleData(db) {
  const emails = Object.values(SAMPLE_USERS).map(u => u.email);
  const [users] = await db.query('SELECT id FROM users WHERE email IN (?)', [emails]);
  const userIds = users.map(u => u.id);
  if (!userIds.length) return 0;

  const [students] = await db.query(
    'SELECT id FROM students WHERE primary_therapist_id IN (?) OR parent_user_id IN (?)', [userIds, userIds]
  );
  const studentIds = students.map(s => s.id);
  if (studentIds.length) {
    for (const t of STUDENT_TABLES) await db.query(`DELETE FROM \`${t}\` WHERE student_id IN (?)`, [studentIds]);
    await db.query('DELETE FROM students WHERE id IN (?)', [studentIds]);
  }
  await db.query('DELETE FROM director_appointments WHERE director_user_id IN (?) OR LOWER(attendee_email) IN (?)', [userIds, emails]);
  await db.query('DELETE FROM notifications WHERE recipient_user_id IN (?)', [userIds]);
  await db.query('DELETE FROM therapist_profiles WHERE user_id IN (?)', [userIds]);
  await db.query('DELETE FROM parent_profiles WHERE user_id IN (?)', [userIds]);
  await db.query('DELETE FROM users WHERE id IN (?)', [userIds]);
  return studentIds.length;
}

async function createUser(db, role, password) {
  const u = SAMPLE_USERS[role];
  const [r] = await db.query(
    "INSERT INTO users (name, email, password, role, status, phone) VALUES (?, ?, ?, ?, 'Active', ?)",
    [u.name, u.email, await bcrypt.hash(password, 10), role, u.phone]
  );
  return r.insertId;
}

// Daily data: manding + skill acquisition improving, problem behaviour decreasing
function dailyRows(profile) {
  const rows = [];
  const behaviours = ['Hit', 'Flop', 'Crying', 'Bolt', 'Whine', 'Grab', 'Throwing'];
  const antecedents = ['Work demand', 'Transition from playground', 'Task difficulty', 'Noise in hallway', 'Delay in reinforcer', 'Turn-taking'];
  const consequences = ['Planned ignore & redirect', 'Visual schedule cue', 'Functional communication prompt', 'Noise-cancelling headphones', 'Count-down timer', 'Token economy praise'];
  const prompts = ['Physical', 'Verbal', 'Gestural', 'Independent'];
  const sessions = 10;

  for (let i = 0; i < sessions; i++) {
    const date = day(-21 + i * 2);
    const progress = i / (sessions - 1); // 0 → 1
    const completed = 16 + Math.round(progress * 8);
    const successful = Math.min(completed, Math.round(completed * (profile.start + progress * (profile.end - profile.start))));
    rows.push([date, 'Manding', profile.mands[i % profile.mands.length], prompts[Math.min(3, Math.floor(progress * 4))],
      completed, successful, progress > 0.7 ? 'Spontaneous independent mands' : 'Prompt fading in progress']);

    const skill = profile.skills[i % profile.skills.length];
    const sc = 10 + (i % 3) * 2;
    rows.push([date, skill[0], skill[1], prompts[Math.min(3, Math.floor(progress * 4))],
      sc, Math.min(sc, Math.round(sc * (0.4 + progress * 0.55))), `${Math.round((0.4 + progress * 0.55) * 100)}% accuracy`]);

    const incidents = Math.max(1, Math.round(profile.pb * (1 - progress)));
    const duration = Math.max(2, Math.round(profile.pbMins * (1 - progress * 0.9)));
    rows.push([date, 'ABC Problem Behavior', behaviours[(i + profile.seed) % behaviours.length], prompts[i % 4],
      incidents, 0,
      `Duration ${duration} mins. Antecedent: ${antecedents[i % antecedents.length]}. Consequence: ${consequences[i % consequences.length]}.`]);
  }
  return rows;
}

// VB-MAPP milestone scores are cumulative milestone numbers per domain (0-15)
function milestoneTests(base) {
  const domains = ['manding', 'tacting', 'listener', 'echoic', 'vocal', 'vp_mts', 'play', 'social', 'imitation', 'lrffc', 'intraverbal', 'group', 'linguistic'];
  return [0, 1, 2].map(t => {
    const scores = {};
    domains.forEach((d, idx) => {
      const lvl1 = ['manding', 'tacting', 'listener', 'echoic', 'vocal', 'vp_mts', 'play', 'social', 'imitation'].includes(d);
      const start = lvl1 ? base + (idx % 3) : 0;
      scores[d] = Math.min(lvl1 ? 10 : 7, start + t * (lvl1 ? 2 + (idx % 2) : 2) + (lvl1 ? 0 : (t > 0 ? 4 : 0)));
    });
    const total = Object.values(scores).reduce((a, b) => a + b, 0);
    return { test_number: t + 1, date: day(-90 + t * 40), level: t < 2 ? 'Level 1' : 'Level 2', total, scores };
  });
}

const BARRIERS = ['Behaviour Problems', 'Instructional Control', 'Impaired Mand', 'Impaired Tact', 'Impaired Imitation',
  'Impaired Echoic', 'Impaired VP-MTS', 'Impaired Listener Responding', 'Impaired Intraverbal', 'Impaired Social Skills',
  'Prompt Dependent', 'Scrolling', 'Impaired Scanning', 'Impaired Conditional Discrimination', 'Failure to Generalize',
  'Weak Motivators', 'Response Requirement weakens MO', 'Reinforcer Dependent'];

async function seedStudent(db, s, therapistId, directorId) {
  const [r] = await db.query(
    `INSERT INTO students (first_name, last_name, dob, gender, blood_group, joining_date, program, primary_diagnosis, language, status, primary_therapist_id, parent_user_id)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'Active', ?, ?)`,
    [s.first, s.last, s.dob, s.gender, s.blood, day(-120), s.program, s.diagnosis, s.language, therapistId, s.parentId]
  );
  const id = r.insertId;

  await db.query("INSERT INTO student_therapists (student_id, therapist_id, role_title, is_active) VALUES (?, ?, 'Primary BCBA', 1)", [id, therapistId]);
  await db.query(
    `INSERT INTO guardians (student_id, guardian_priority, relationship, first_name, last_name, phone, email, city, state, is_emergency_contact)
     VALUES (?, 1, ?, ?, ?, ?, ?, 'Chennai', 'Tamil Nadu', 1)`,
    [id, s.guardian[0], s.guardian[1], s.guardian[2], s.guardian[3], s.guardian[4]]
  );
  await db.query(
    `INSERT INTO medical_histories (student_id, has_allergies, allergy_details, eating_habits, sleeping_habits, pediatrician_name, pediatrician_phone)
     VALUES (?, ?, ?, ?, ?, 'Dr. K. Subramanian (Sample)', '+91 44 0000 0000')`,
    [id, s.allergy ? 1 : 0, s.allergy || null, 'Selective eater; prefers soft textures', 'Sleeps 9-10 hours, occasional night waking']
  );

  for (const row of dailyRows(s.profile)) {
    await db.query(
      `INSERT INTO daily_data_sheets (student_id, therapist_id, session_date, domain, target_skill, prompt_level, trials_completed, trials_successful, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`, [id, therapistId, ...row]
    );
  }

  for (const t of milestoneTests(s.profile.milestoneBase)) {
    const sc = t.scores;
    await db.query(
      `INSERT INTO milestone_assessments (student_id, therapist_id, test_number, level, assessment_date, total_score, max_score,
         manding_score, tacting_score, listener_score, echoic_score, vocal_score, vp_mts_score, play_score, social_score, imitation_score,
         lrffc_score, intraverbal_score, group_score, linguistic_score, scores_detail, therapist_notes)
       VALUES (?, ?, ?, ?, ?, ?, 170, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '{}', ?)`,
      [id, therapistId, t.test_number, t.level, t.date, t.total, sc.manding, sc.tacting, sc.listener, sc.echoic, sc.vocal,
        sc.vp_mts, sc.play, sc.social, sc.imitation, sc.lrffc, sc.intraverbal, sc.group, sc.linguistic,
        ['Baseline assessment', 'Mid-term progress assessment', 'Quarterly re-assessment'][t.test_number - 1]]
    );
  }

  for (const t of [1, 2]) {
    const scores = {};
    BARRIERS.forEach((b, i) => { scores[b] = Math.max(0, ((i + s.profile.seed) % 4) + 1 - (t - 1) * 2); });
    const total = Object.values(scores).reduce((a, b) => a + b, 0);
    await db.query(
      `INSERT INTO barriers_assessments (student_id, therapist_id, test_number, assessment_date, total_score, max_score, barrier_scores, therapist_notes)
       VALUES (?, ?, ?, ?, ?, 72, ?, ?)`,
      [id, therapistId, t, day(t === 1 ? -90 : -10), total, JSON.stringify(scores),
        t === 1 ? 'Baseline barriers' : 'Re-assessment after prompt fading and BIP']
    );
  }

  for (const t of [1, 2]) {
    const areas = {};
    for (let a = 1; a <= 7; a++) areas[String(a)] = Math.min(5, ((a + s.profile.seed) % 3) + 1 + (t - 1) * 2);
    const total = Object.values(areas).reduce((x, y) => x + y, 0);
    await db.query(
      `INSERT INTO transition_assessments (student_id, therapist_id, test_number, assessment_date, total_score, max_score, area_scores, therapist_notes)
       VALUES (?, ?, ?, ?, ?, 35, ?, ?)`,
      [id, therapistId, t, day(t === 1 ? -90 : -10), total, JSON.stringify(areas),
        t === 1 ? 'Initial transition readiness' : 'Improved classroom routines and group skills']
    );
  }

  for (const t of [1, 2]) {
    const g1 = 18 + t * 12 + s.profile.seed * 2;
    const g2 = 10 + t * 8 + s.profile.seed;
    await db.query(
      `INSERT INTO eesa_assessments (student_id, therapist_id, test_number, assessment_date, group1_score, group2_score, total_score, responses, therapist_notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, '{}', ?)`,
      [id, therapistId, t, day(t === 1 ? -80 : -12), g1, g2, g1 + g2, t === 1 ? 'Baseline EESA' : 'EESA re-assessment']
    );
  }

  for (const [category, item, rating] of s.preferences) {
    await db.query(
      `INSERT INTO preference_assessments (student_id, therapist_id, category, item_name, rating, hierarchy_rank, assessment_date)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [id, therapistId, category, item, rating, rating >= 4 ? 'High-Preference Primary Reinforcer' : 'Moderate Preference', day(-14)]
    );
  }

  const sessions = [
    [-7, 'completed'], [-5, 'completed'], [-3, 'completed'], [-1, 'completed'], [0, 'upcoming'], [2, 'upcoming'], [4, 'upcoming'],
  ];
  for (const [offset, status] of sessions) {
    await db.query(
      `INSERT INTO therapy_sessions (therapist_id, student_id, session_date, start_time, end_time, room, program_title, status, clinical_notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [therapistId, id, day(offset), s.slot[0], s.slot[1], s.room, s.sessionProgram, status,
        status === 'completed' ? 'Session completed; data recorded in daily data sheet' : null]
    );
  }

  await db.query(
    `INSERT INTO iep_reports (student_id, therapist_id, title, cycle_term, status, manding_score, tacting_score, listener_score, echoic_score, lrffc_score,
       goals_summary, director_notes, director_signed_by, director_signed_at)
     VALUES (?, ?, ?, 'Q3 2026 Treatment Plan', 'Active', ?, ?, ?, ?, ?, ?, 'Approved. Continue current prompt-fading plan.', ?, NOW())`,
    [id, therapistId, `${s.first} — Q3 IEP`, 60, 55, 50, 58, 40,
      'Increase independent 2-word mands to 80%; reduce problem behaviour duration by 50%; generalise tacting across 3 settings.', directorId]
  );
  await db.query(
    `INSERT INTO iep_reports (student_id, therapist_id, title, cycle_term, status, manding_score, tacting_score, listener_score, echoic_score, lrffc_score, goals_summary)
     VALUES (?, ?, ?, 'Q4 2026 Treatment Plan', 'Pending Approval', ?, ?, ?, ?, ?, ?)`,
    [id, therapistId, `${s.first} — Q4 IEP draft`, 75, 70, 66, 72, 55,
      'Introduce intraverbal fill-ins; group instruction readiness; maintain mastered mands.']
  );
  return id;
}

(async () => {
  const db = await mysql.createConnection({
    host: process.env.DB_HOST, port: parseInt(process.env.DB_PORT || '3306'),
    user: process.env.DB_USER, password: process.env.DB_PASSWORD, database: process.env.DB_NAME,
  });
  console.log(`✅ Connected to ${process.env.DB_NAME} on ${process.env.DB_HOST}`);

  await db.beginTransaction();
  try {
    const removed = await removeSampleData(db);
    if (removed) console.log(`🧹 Removed previous sample data (${removed} students)`);
    if (process.argv.includes('--remove')) {
      await db.commit();
      console.log('Done — sample data removed.');
      return;
    }

    const pw = await readStdinJson();
    for (const role of Object.keys(SAMPLE_USERS)) {
      if (!pw[role] || pw[role].length < 12) throw new Error(`Missing/short password for ${role} (pass JSON on stdin)`);
    }

    const directorId = await createUser(db, 'director', pw.director);
    const therapistId = await createUser(db, 'therapist', pw.therapist);
    const parentId = await createUser(db, 'parent', pw.parent);
    await db.query(
      `INSERT INTO therapist_profiles (user_id, employee_id, designation, qualification, license_number, date_of_joining, active_caseload, specialties)
       VALUES (?, 'SAMPLE-T-001', 'BCBA', 'M.S. Applied Behavior Analysis', 'BACB #SAMPLE-0001', ?, 3, 'Early Intervention, Verbal Behavior, NET')`,
      [therapistId, day(-400)]
    );
    await db.query(
      `INSERT INTO parent_profiles (user_id, secondary_phone, street_address, city, state, postal_code, occupation, preferred_communication)
       VALUES (?, '+91 98400 00004', '12 Sample Street, Adyar', 'Chennai', 'Tamil Nadu', '600020', 'Engineer', 'Email')`,
      [parentId]
    );

    const students = [
      {
        first: 'Ishaan', last: 'Sharma', dob: '2020-03-14', gender: 'Male', blood: 'B+', language: 'English, Tamil',
        program: 'Comprehensive ABA Early Intervention', diagnosis: 'Autism Spectrum Disorder (Level 2)', parentId,
        guardian: ['Father', 'Ravi', 'Sharma (Sample)', '+91 98400 00003', SAMPLE_USERS.parent.email], allergy: 'Peanuts',
        profile: { start: 0.25, end: 0.9, pb: 4, pbMins: 30, seed: 0, milestoneBase: 2,
          mands: ['"want water"', '"cookie please"', '"swing please"', '"give ball"', '"open bubbles"'],
          skills: [['Tacting', 'Labeling household items'], ['Listener Responding', 'Following 1-step commands'], ['Imitation', 'Gross motor imitation']] },
        preferences: [['Edible', 'Chocolate buttons', 5], ['Toys/Materials', 'Bubbles', 5], ['Sensory', 'Swing', 4], ['Social', 'High-fives', 3]],
        slot: ['09:00 AM', '10:00 AM'], room: 'Sensory Room A', sessionProgram: 'VB-MAPP Manding & Echoic Probes',
      },
      {
        first: 'Diya', last: 'Sharma', dob: '2021-07-02', gender: 'Female', blood: 'B+', language: 'English, Hindi',
        program: 'Speech & Language Integration', diagnosis: 'Autism Spectrum Disorder (Level 1)', parentId,
        guardian: ['Father', 'Ravi', 'Sharma (Sample)', '+91 98400 00003', SAMPLE_USERS.parent.email], allergy: null,
        profile: { start: 0.4, end: 0.95, pb: 2, pbMins: 15, seed: 1, milestoneBase: 4,
          mands: ['"more juice"', '"help me"', '"open door"', '"my turn"'],
          skills: [['VP-MTS', 'Matching identical objects to pictures'], ['Tacting', 'Labeling colours'], ['Listener Responding', 'Identifying body parts']] },
        preferences: [['Toys/Materials', 'Picture books', 5], ['Edible', 'Apple slices', 4], ['Social', 'Tickles', 4]],
        slot: ['11:00 AM', '12:00 PM'], room: 'ABA Cabin 2', sessionProgram: 'Tacting & Listener Responding DTT',
      },
      {
        first: 'Kabir', last: 'Menon', dob: '2019-11-21', gender: 'Male', blood: 'O+', language: 'English, Malayalam',
        program: 'Social Skills & School Readiness', diagnosis: 'Autism Spectrum Disorder (Level 2)', parentId: null,
        guardian: ['Mother', 'Lakshmi', 'Menon (Sample)', '+91 98400 00005', null], allergy: 'Lactose intolerance',
        profile: { start: 0.15, end: 0.7, pb: 5, pbMins: 40, seed: 2, milestoneBase: 1,
          mands: ['"want car"', '"music on"', '"break please"'],
          skills: [['Imitation', 'Fine motor imitation'], ['Tacting', 'Labeling animals'], ['VP-MTS', 'Sorting by colour']] },
        preferences: [['Toys/Materials', 'Toy cars', 5], ['Sensory', 'Weighted blanket', 4], ['Edible', 'Crackers', 3]],
        slot: ['02:00 PM', '03:00 PM'], room: 'Sensory Room B', sessionProgram: 'Social Play & Group Readiness',
      },
    ];

    const ids = [];
    for (const s of students) ids.push(await seedStudent(db, s, therapistId, directorId));

    await db.query(
      `INSERT INTO director_appointments (director_user_id, title, appointment_type, date, start_time, end_time, attendee_name, attendee_role, attendee_email, status)
       VALUES (?, 'Quarterly progress review — Ishaan', 'parentConference', ?, '04:00 PM', '04:30 PM', ?, 'Parent', ?, 'confirmed')`,
      [directorId, day(3), SAMPLE_USERS.parent.name, SAMPLE_USERS.parent.email]
    );

    await db.commit();
    console.log(`👥 Users: director #${directorId}, therapist #${therapistId}, parent #${parentId}`);
    console.log(`🧒 Students: ${students.map((s, i) => `${s.first} ${s.last} #${ids[i]}`).join(', ')}`);
    console.log('📊 Per student: 30 daily data rows, 3 milestone, 2 barriers, 2 transition, 2 EESA tests, 7 sessions, 2 IEPs');
  } catch (err) {
    await db.rollback();
    throw err;
  } finally {
    await db.end();
  }
})().catch(err => {
  console.error('❌ Sample data failed:', err.message);
  process.exit(1);
});
