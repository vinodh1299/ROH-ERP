const http = require('http');

const BASE_URL = 'http://127.0.0.1:8000/api';

function request(action, method = 'GET', body = null, token = null, queryParams = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(BASE_URL);
    url.searchParams.set('action', action);
    for (const [k, v] of Object.entries(queryParams)) {
      url.searchParams.set(k, v);
    }

    const headers = {
      'Content-Type': 'application/json',
    };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: headers,
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, body: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function runTests() {
  console.log('🚀 Starting Comprehensive Production Readiness & CRUD Verification Suite...\n');
  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`  ✓ ${message}`);
      passed++;
    } else {
      console.error(`  ✗ FAIL: ${message}`);
      failed++;
    }
  }

  try {
    // ──────────────────────────────────────────────────────────────────────────
    // 1. Authentication for All 4 Roles
    // ──────────────────────────────────────────────────────────────────────────
    console.log('1️⃣  Verifying Authentication & JWT generation for Baseline Roles...');
    
    const adminLogin = await request('login', 'POST', { email: 'admin@roh.com', password: 'admin123' });
    assert(adminLogin.status === 200 && adminLogin.body.token && adminLogin.body.role === 'admin', 'Admin login successful with valid JWT');
    const adminToken = adminLogin.body.token;

    const directorLogin = await request('login', 'POST', { email: 'director@roh.com', password: 'director123' });
    assert(directorLogin.status === 200 && directorLogin.body.token && directorLogin.body.role === 'director', 'Director login successful with valid JWT');
    const directorToken = directorLogin.body.token;

    const therapistLogin = await request('login', 'POST', { email: 'therapist@roh.com', password: 'therapist123' });
    assert(therapistLogin.status === 200 && therapistLogin.body.token && therapistLogin.body.role === 'therapist', 'Therapist login successful with valid JWT');
    const therapistToken = therapistLogin.body.token;

    const parentLogin = await request('login', 'POST', { email: 'parent@roh.com', password: 'parent123' });
    assert(parentLogin.status === 200 && parentLogin.body.token && parentLogin.body.role === 'parent', 'Parent login successful with valid JWT');

    // ──────────────────────────────────────────────────────────────────────────
    // 2. Therapist Full CRUD
    // ──────────────────────────────────────────────────────────────────────────
    console.log('\n2️⃣  Verifying Therapist Management (Add, List, Update, Toggle Status)...');
    
    const addTherapist = await request('add_therapist', 'POST', {
      name: 'Dr. Emily Watson (BCBA)',
      email: 'emily.watson@rohcenter.org',
      password: 'therapist123',
      designation: 'Senior Behavior Analyst',
      phone: '+1 (800) 234-9901'
    }, adminToken);
    assert(addTherapist.status === 200 && addTherapist.body.id, `Therapist added with ID: ${addTherapist.body.id}`);
    const testTherapistId = addTherapist.body.id;

    const listTherapists = await request('get_therapists', 'GET', null, adminToken);
    assert(Array.isArray(listTherapists.body) && listTherapists.body.some(t => t.id === testTherapistId), 'Newly added therapist retrieved in therapist list');

    const updateTherapist = await request('update_therapist', 'POST', {
      id: testTherapistId,
      name: 'Dr. Emily Watson-Shaw (BCBA-D)',
      designation: 'Lead Clinical Supervisor',
      license_number: 'BACB-98712'
    }, adminToken);
    assert(updateTherapist.status === 200 && updateTherapist.body.success, 'Therapist updated successfully');

    const toggleTherapist = await request('toggle_therapist_status', 'POST', {
      user_id: testTherapistId,
      status: 'De-Activated'
    }, adminToken);
    assert(toggleTherapist.status === 200 && toggleTherapist.body.status === 'De-Activated', 'Therapist status toggled to De-Activated');

    // ──────────────────────────────────────────────────────────────────────────
    // 3. Parent Full CRUD
    // ──────────────────────────────────────────────────────────────────────────
    console.log('\n3️⃣  Verifying Parent Management (Add, List, Update, Toggle Status)...');

    const addParent = await request('add_parent', 'POST', {
      name: 'Mrs. Eleanor Vance',
      email: 'eleanor.vance@example.com',
      phone: '+1 (800) 234-8801',
      password: 'parent123'
    }, adminToken);
    assert(addParent.status === 200 && addParent.body.id, `Parent added with ID: ${addParent.body.id}`);
    const testParentId = addParent.body.id;

    const listParents = await request('get_parents', 'GET', null, adminToken);
    assert(Array.isArray(listParents.body) && listParents.body.some(p => p.id === testParentId), 'Newly added parent retrieved in parent list');

    const updateParent = await request('update_parent', 'POST', {
      id: testParentId,
      name: 'Mrs. Eleanor Vance-Miller',
      city: 'Portland',
      state: 'OR'
    }, adminToken);
    assert(updateParent.status === 200 && updateParent.body.success, 'Parent profile updated successfully');

    const toggleParent = await request('toggle_parent_status', 'POST', {
      user_id: testParentId,
      status: 'De-Activated'
    }, adminToken);
    assert(toggleParent.status === 200 && toggleParent.body.status === 'De-Activated', 'Parent status toggled to De-Activated');

    // ──────────────────────────────────────────────────────────────────────────
    // 4. Student Management & Therapist Assignment
    // ──────────────────────────────────────────────────────────────────────────
    console.log('\n4️⃣  Verifying Student Enrollment, Clinical Updates, and Therapist Assignment...');

    const addStudent = await request('add_student', 'POST', {
      name: 'Lucas Miller',
      dob: '2018-05-14',
      program: 'Comprehensive ABA Early Intervention',
      primary_diagnosis: 'Autism Spectrum Disorder',
    }, directorToken);
    assert(addStudent.status === 200 && addStudent.body.id, `Student enrolled with ID: ${addStudent.body.id}`);
    const testStudentId = addStudent.body.id;

    const updateStudent = await request('update_student', 'POST', {
      id: testStudentId,
      name: 'Lucas Alexander Miller',
      status: 'Active',
      program: 'Natural Environment Teaching (NET)'
    }, directorToken);
    assert(updateStudent.status === 200 && updateStudent.body.success, 'Student details updated');

    const assignTherapist = await request('assign_student_therapist', 'POST', {
      student_id: testStudentId,
      therapist_id: 3, // Baseline Dr. Sarah Lee
      role_title: 'Primary BCBA'
    }, directorToken);
    assert(assignTherapist.status === 200 && assignTherapist.body.success, 'Therapist assigned to student');

    const studentTherapistsParam = await (async () => {
      const url = new URL(BASE_URL);
      url.searchParams.set('action', 'get_student_therapists');
      url.searchParams.set('student_id', testStudentId);
      const res = await new Promise((r) => {
        http.get(url, (res) => {
          let d = '';
          res.on('data', c => d += c);
          res.on('end', () => r(JSON.parse(d)));
        });
      });
      return res;
    })();
    assert(Array.isArray(studentTherapistsParam) && studentTherapistsParam.length > 0, 'Assigned therapist retrieved for student');

    // ──────────────────────────────────────────────────────────────────────────
    // 5. Medical History, Medications & Guardians
    // ──────────────────────────────────────────────────────────────────────────
    console.log('\n5️⃣  Verifying Student Clinical Dossier (Medical History, Medications, Guardians)...');

    const saveMed = await request('save_student_medical_info', 'POST', {
      student_id: testStudentId,
      has_allergies: true,
      allergy_details: 'Peanut allergy (mild contact reaction)',
      has_diagnosed_conditions: true,
      diagnosed_condition_details: 'Sensory Processing Disorder',
      eating_habits: 'Textures sensitive; prefers dry foods',
      sleeping_habits: 'Consistent sleep schedule 8pm - 6am'
    }, directorToken);
    assert(saveMed.status === 200 && saveMed.body.success, 'Student medical info saved');

    const getMed = await request('get_student_medical_info', 'GET', null, directorToken, { student_id: testStudentId });
    assert(getMed.status === 200 && getMed.body && getMed.body.allergy_details.includes('Peanut'), 'Student medical info accurately retrieved');

    const addMedication = await request('add_student_medication', 'POST', {
      student_id: testStudentId,
      medication_name: 'Melatonin',
      dosage: '1mg at bedtime',
      administration_timeline: 'Nightly',
      used_for: 'Sleep regulation',
      is_administered_at_center: false
    }, directorToken);
    assert(addMedication.status === 200 && addMedication.body.id, 'Medication logged for student');
    const testMedId = addMedication.body.id;

    const getMeds = await request('get_student_medications', 'GET', null, directorToken, { student_id: testStudentId });
    assert(Array.isArray(getMeds.body) && getMeds.body.some(m => m.id === testMedId), 'Medications list retrieved');

    const deleteMed = await request('delete_student_medication', 'POST', { id: testMedId }, directorToken);
    assert(deleteMed.status === 200 && deleteMed.body.success, 'Medication deleted');

    const addGuardian = await request('add_student_guardian', 'POST', {
      student_id: testStudentId,
      relationship: 'Mother',
      first_name: 'Eleanor',
      last_name: 'Vance',
      phone: '+1 (800) 234-8801',
      email: 'eleanor.vance@example.com',
      is_emergency_contact: true,
      notes: 'Available for immediate center calls'
    }, directorToken);
    assert(addGuardian.status === 200 && addGuardian.body.id, 'Guardian added for student');
    const testGuardianId = addGuardian.body.id;

    const getGuardians = await request('get_student_guardians', 'GET', null, directorToken, { student_id: testStudentId });
    assert(Array.isArray(getGuardians.body) && getGuardians.body.some(g => g.id === testGuardianId), 'Guardians list retrieved');

    // ──────────────────────────────────────────────────────────────────────────
    // 6. Therapy Session Scheduling & Intelligent Conflict Detection
    // ──────────────────────────────────────────────────────────────────────────
    console.log('\n6️⃣  Verifying Therapy Session Scheduling & Real-Time Conflict Detection...');

    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const sessionDateStr = tomorrow.toISOString().split('T')[0];

    // Schedule valid session
    const scheduleSession = await request('save_therapy_session', 'POST', {
      therapist_id: 3, // Dr. Sarah Lee
      student_id: testStudentId,
      session_date: sessionDateStr,
      start_time: '10:00 AM',
      end_time: '11:15 AM',
      room: 'Sensory Room A',
      program_title: 'DTT Receptive Language Protocol',
      clinical_notes: 'Focus on 3-step listener responding instructions'
    }, directorToken);
    assert(scheduleSession.status === 200 && scheduleSession.body.id, `Therapy session scheduled with ID: ${scheduleSession.body.id}`);
    const testSessionId = scheduleSession.body.id;

    // Attempt conflict 1: Same Therapist, Same Date & Time
    const conflictTherapist = await request('save_therapy_session', 'POST', {
      therapist_id: 3, // Same therapist
      student_id: testStudentId,
      session_date: sessionDateStr,
      start_time: '10:00 AM', // Overlapping slot
      end_time: '11:15 AM',
      room: 'Speech Cabin B',
      program_title: 'Conflicting Slot Session'
    }, directorToken);
    assert(conflictTherapist.status === 409 && conflictTherapist.body.conflict === true, 'Therapist schedule conflict properly rejected with HTTP 409');

    // Attempt conflict 2: Different Therapist, Same Room & Time
    const conflictRoom = await request('save_therapy_session', 'POST', {
      therapist_id: testTherapistId, // Different therapist
      student_id: testStudentId,
      session_date: sessionDateStr,
      start_time: '10:00 AM',
      end_time: '11:15 AM',
      room: 'Sensory Room A', // Same room
      program_title: 'Conflicting Room Session'
    }, directorToken);
    assert(conflictRoom.status === 409 && conflictRoom.body.conflict === true, 'Room schedule conflict properly rejected with HTTP 409');

    // Retrieve Sessions
    const sessionsList = await request('get_sessions', 'GET', null, directorToken, { date: sessionDateStr });
    assert(Array.isArray(sessionsList.body) && sessionsList.body.some(s => s.id === testSessionId), 'Scheduled session retrieved from backend');

    // Update Session Status
    const updateSession = await request('update_therapy_session', 'POST', {
      id: testSessionId,
      status: 'inProgress',
      clinical_notes: 'Session started on time. Student engaged.'
    }, therapistToken);
    assert(updateSession.status === 200 && updateSession.body.success, 'Session status updated to inProgress');

    // Delete Session
    const deleteSession = await request('delete_therapy_session', 'POST', {
      id: testSessionId
    }, directorToken);
    assert(deleteSession.status === 200 && deleteSession.body.success, 'Session cancelled and deleted');

    // ──────────────────────────────────────────────────────────────────────────
    // Final Summary
    // ──────────────────────────────────────────────────────────────────────────
    console.log(`\n==================================================`);
    console.log(`🏁 VERIFICATION SUITE COMPLETE: ${passed} PASSED, ${failed} FAILED`);
    console.log(`==================================================\n`);

    if (failed > 0) {
      process.exit(1);
    } else {
      process.exit(0);
    }
  } catch (err) {
    console.error('Fatal error during test run:', err);
    process.exit(1);
  }
}

runTests();
