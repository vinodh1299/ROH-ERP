require('dotenv').config();
require('./ops/production_guard')('seed_graphs_data.js');

const mysql = require('mysql2/promise');

async function seed() {
  const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME || 'roh_erp',
    multipleStatements: true,
  });

  console.log('Connecting to roh_erp to seed live graph data...');

  // 1. Clear old daily_data_sheets for student 1 & 2
  await pool.query('DELETE FROM daily_data_sheets WHERE student_id IN (1, 2)');

  // 2. Insert Manding & Discrete Trial sessions for Student 1 (Alex Thomas Sam)
  const dailyDataRows = [
    // Date, Domain, Target, Prompt Level, Completed, Successful, Notes
    ['2026-10-01', 'Manding', 'Vocal request for water ("want water")', 'Physical', 16, 4, 'High prompt required on first session'],
    ['2026-10-02', 'Manding', 'Vocal request for snack ("cookie please")', 'Verbal', 18, 6, 'Partial verbal prompt needed'],
    ['2026-10-04', 'Manding', 'Vocal request for swing ("swing please")', 'Gestural', 20, 10, 'Point prompt to picture cue'],
    ['2026-10-06', 'Manding', 'Vocal request for ball ("give ball")', 'Independent', 22, 14, 'Spontaneous vocal mand achieved'],
    ['2026-10-08', 'Manding', 'Vocal request for iPad ("play music")', 'Independent', 24, 18, 'Clear independent vocal requests'],
    ['2026-10-10', 'Manding', 'Vocal request for bubbles ("open bubbles")', 'Independent', 25, 21, 'Independent requesting across 3 settings'],
    ['2026-10-12', 'Manding', 'Vocal request for break ("want break")', 'Independent', 26, 24, 'Mastered 2-word phrase independent mand'],

    // Skills & DTT Targets
    ['2026-10-01', 'Tacting', 'Labeling common household items (cup, shoe, spoon)', 'Verbal', 10, 5, 'Mastery in progress'],
    ['2026-10-03', 'Tacting', 'Labeling body parts (eyes, nose, mouth)', 'Gestural', 12, 8, '80% accuracy'],
    ['2026-10-05', 'Listener Responding', 'Following 1-step motor commands ("clap", "sit")', 'Independent', 15, 13, 'Criterion met'],
    ['2026-10-07', 'Listener Responding', 'Identifying colors (red, blue, yellow)', 'Gestural', 14, 11, 'Field of 3 array'],
    ['2026-10-09', 'Imitation', 'Gross motor imitation (arms up, jump)', 'Independent', 10, 10, '100% fidelity mastery'],
    ['2026-10-11', 'VP-MTS', 'Matching identical 3D objects to picture', 'Independent', 12, 11, 'Mastered on 2 consecutive days'],

    // ABC Problem Behavior Incidents (Deceleration progression)
    ['2026-10-01', 'ABC Problem Behavior', 'Hit', 'Verbal', 4, 0, 'Duration 30 mins. Antecedent: Work demand. Consequence: Planned ignore & redirect'],
    ['2026-10-03', 'ABC Problem Behavior', 'Flop', 'Gestural', 3, 0, 'Duration 18 mins. Antecedent: Transition from playground. Consequence: Visual schedule cue'],
    ['2026-10-05', 'ABC Problem Behavior', 'Crying', 'Independent', 2, 0, 'Duration 12 mins. Antecedent: Task difficulty. Consequence: Functional communication break prompt'],
    ['2026-10-07', 'ABC Problem Behavior', 'Bolt', 'Verbal', 2, 0, 'Duration 8 mins. Antecedent: Noise hallway. Consequence: Noise-canceling headphones'],
    ['2026-10-09', 'ABC Problem Behavior', 'Hit', 'Gestural', 1, 0, 'Duration 5 mins. Antecedent: Delay in reinforcer. Consequence: Count down timer'],
    ['2026-10-11', 'ABC Problem Behavior', 'Whine', 'Independent', 1, 0, 'Duration 3 mins. Antecedent: Turn-taking. Consequence: Token economy praise'],
    ['2026-10-12', 'ABC Problem Behavior', 'Hit', 'Independent', 1, 0, 'Duration 2 mins. Deceleration demonstrated. Duration reduced by 93%'],
  ];

  for (const row of dailyDataRows) {
    await pool.query(
      `INSERT INTO daily_data_sheets (student_id, therapist_id, session_date, domain, target_skill, prompt_level, trials_completed, trials_successful, notes)
       VALUES (1, 3, ?, ?, ?, ?, ?, ?, ?)`,
      row
    );
  }
  console.log(`✓ Inserted ${dailyDataRows.length} daily_data_sheets rows for Student 1.`);

  // 3. Seed Milestone Assessments (3 tests showing Level 1 progress)
  await pool.query('DELETE FROM milestone_assessments WHERE student_id = 1');
  const milestoneTests = [
    {
      test_number: 1,
      level: 'Level 1',
      assessment_date: '2026-08-15',
      total_score: 18.0,
      manding_score: 2.0,
      tacting_score: 2.0,
      listener_score: 1.5,
      echoic_score: 2.0,
      vocal_score: 2.0,
      vp_mts_score: 2.0,
      play_score: 1.0,
      social_score: 1.5,
      imitation_score: 2.0,
      therapist_notes: 'Initial Baseline Assessment',
    },
    {
      test_number: 2,
      level: 'Level 1',
      assessment_date: '2026-09-18',
      total_score: 31.5,
      manding_score: 3.5,
      tacting_score: 3.5,
      listener_score: 3.0,
      echoic_score: 3.5,
      vocal_score: 3.5,
      vp_mts_score: 3.5,
      play_score: 2.5,
      social_score: 2.5,
      imitation_score: 3.5,
      therapist_notes: 'Mid-term Progress Assessment',
    },
    {
      test_number: 3,
      level: 'Level 1',
      assessment_date: '2026-10-10',
      total_score: 44.0,
      manding_score: 5.0,
      tacting_score: 5.0,
      listener_score: 4.5,
      echoic_score: 5.0,
      vocal_score: 4.5,
      vp_mts_score: 5.0,
      play_score: 4.0,
      social_score: 3.5,
      imitation_score: 5.0,
      therapist_notes: 'Q4 Milestone Mastery Assessment',
    },
  ];

  for (const t of milestoneTests) {
    await pool.query(
      `INSERT INTO milestone_assessments 
       (student_id, therapist_id, test_number, level, assessment_date, total_score, max_score, 
        manding_score, tacting_score, listener_score, echoic_score, vocal_score, vp_mts_score, 
        play_score, social_score, imitation_score, scores_detail, therapist_notes)
       VALUES (1, 3, ?, ?, ?, ?, 170, ?, ?, ?, ?, ?, ?, ?, ?, ?, '{}', ?)`,
      [
        t.test_number, t.level, t.assessment_date, t.total_score,
        t.manding_score, t.tacting_score, t.listener_score, t.echoic_score, t.vocal_score,
        t.vp_mts_score, t.play_score, t.social_score, t.imitation_score, t.therapist_notes
      ]
    );
  }
  console.log(`✓ Inserted 3 milestone assessment tests for Student 1.`);

  // 4. Seed Barriers Assessments
  await pool.query('DELETE FROM barriers_assessments WHERE student_id = 1');
  const barrierScoresTest1 = {
    'Behaviour Problems': 3,
    'Instructional Control': 3,
    'Impaired Mand': 4,
    'Impaired Tact': 3,
    'Impaired Imitation': 2,
    'Impaired Echoic': 3,
    'Impaired VP-MTS': 2,
    'Impaired Listener Responding': 3,
    'Impaired Intraverbal': 4,
    'Impaired Social Skills': 3,
    'Prompt Dependent': 3,
    'Scrolling': 2,
    'Impaired Scanning': 2,
    'Impaired Conditional Discrimination': 3,
    'Failure to Generalize': 3,
    'Weak Motivators': 2,
    'Response Requirement weakens MO': 2,
    'Reinforcer Dependent': 2,
  };

  const barrierScoresTest2 = {
    'Behaviour Problems': 1,
    'Instructional Control': 1,
    'Impaired Mand': 1,
    'Impaired Tact': 1,
    'Impaired Imitation': 0,
    'Impaired Echoic': 1,
    'Impaired VP-MTS': 1,
    'Impaired Listener Responding': 1,
    'Impaired Intraverbal': 2,
    'Impaired Social Skills': 1,
    'Prompt Dependent': 1,
    'Scrolling': 0,
    'Impaired Scanning': 0,
    'Impaired Conditional Discrimination': 1,
    'Failure to Generalize': 1,
    'Weak Motivators': 0,
    'Response Requirement weakens MO': 1,
    'Reinforcer Dependent': 1,
  };

  await pool.query(
    `INSERT INTO barriers_assessments 
     (student_id, therapist_id, test_number, assessment_date, total_score, max_score, barrier_scores, therapist_notes)
     VALUES (1, 3, 1, '2026-08-15', 48, 96, ?, 'Baseline: Severe manding and instructional control barriers')`,
    [JSON.stringify(barrierScoresTest1)]
  );

  await pool.query(
    `INSERT INTO barriers_assessments 
     (student_id, therapist_id, test_number, assessment_date, total_score, max_score, barrier_scores, therapist_notes)
     VALUES (1, 3, 2, '2026-10-10', 14, 96, ?, 'Re-assessment: Major barrier reduction through prompt fading & BIP')`,
    [JSON.stringify(barrierScoresTest2)]
  );
  console.log(`✓ Inserted 2 barriers assessments for Student 1.`);

  // 5. Seed Transition Assessments
  await pool.query('DELETE FROM transition_assessments WHERE student_id = 1');
  const transitionScores = {
    1: 4, 2: 4, 3: 3, 4: 4, 5: 3, 6: 4, 7: 3, 8: 4, 9: 3,
    10: 4, 11: 3, 12: 4, 13: 3, 14: 4, 15: 3, 16: 4, 17: 3, 18: 4
  };
  await pool.query(
    `INSERT INTO transition_assessments 
     (student_id, therapist_id, test_number, assessment_date, total_score, max_score, area_scores, therapist_notes)
     VALUES (1, 3, 1, '2026-10-10', 65, 90, ?, 'Readiness for semi-inclusive classroom setting demonstrated')`,
    [JSON.stringify(transitionScores)]
  );
  console.log(`✓ Inserted transition assessment for Student 1.`);

  await pool.end();
  console.log('Database seeding successfully finished!');
}

seed().catch(err => {
  console.error('Seeding error:', err);
  process.exit(1);
});
