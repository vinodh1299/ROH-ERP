-- ============================================================================
-- ROH-ERP demo seed data (local development only — do NOT load into production)
-- Run after schema.sql.
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;
-- ============================================================================
-- REFERENCE SEED DATA FOR PRODUCTION & DEMO ENVIRONMENTS
-- Passwords hashed using standard PHP password_hash(..., PASSWORD_BCRYPT)
-- ============================================================================

-- 1. Insert Core Users
-- admin123     -> $2y$10$c1xWbB39yO2hXfVfFfV5MeT7a3y0t9KzIqYmUf7a5w3v1u9s8q7aO
-- director123  -> $2y$10$w8kXmQ17vT3jYbWfEfU6NeU8b4z1u0LaJrZnVf8b6x4w2v0t9r8bO
-- therapist123 -> $2y$10$a9lYnR28wU4kZcBgFgV7OfV9c5a2v1MbKsAoWg9c7y5x3w1u0s9cP
-- parent123    -> $2y$10$b0mZoR39xV5lAdChGhW8PgW0d6b3w2NcLtBpXh0d8z6y4x2v1t0dQ
INSERT INTO `users` (`id`, `name`, `email`, `password`, `role`, `status`, `phone`) VALUES
(1, 'System Admin', 'admin@roh.com', '$2y$10$c1xWbB39yO2hXfVfFfV5MeT7a3y0t9KzIqYmUf7a5w3v1u9s8q7aO', 'admin', 'Active', '+1 (555) 010-0001'),
(2, 'Dr. Vincent Sterling', 'director@roh.com', '$2y$10$w8kXmQ17vT3jYbWfEfU6NeU8b4z1u0LaJrZnVf8b6x4w2v0t9r8bO', 'director', 'Active', '+1 (555) 010-0002'),
(3, 'Dr. Sarah Lee', 'therapist@roh.com', '$2y$10$a9lYnR28wU4kZcBgFgV7OfV9c5a2v1MbKsAoWg9c7y5x3w1u0s9cP', 'therapist', 'Active', '+1 (555) 010-0003'),
(4, 'Mr. John Wilson', 'parent@roh.com', '$2y$10$b0mZoR39xV5lAdChGhW8PgW0d6b3w2NcLtBpXh0d8z6y4x2v1t0dQ', 'parent', 'Active', '+1 (555) 019-2831'),
(5, 'Dr. Michael Chen', 'm.chen@roh.com', '$2y$10$a9lYnR28wU4kZcBgFgV7OfV9c5a2v1MbKsAoWg9c7y5x3w1u0s9cP', 'therapist', 'Active', '+1 (555) 010-0005'),
(6, 'Priya Sharma', 'priya.s@roh.com', '$2y$10$a9lYnR28wU4kZcBgFgV7OfV9c5a2v1MbKsAoWg9c7y5x3w1u0s9cP', 'therapist', 'Active', '+1 (555) 010-0006'),
(7, 'David Miller', 'd.miller@roh.com', '$2y$10$a9lYnR28wU4kZcBgFgV7OfV9c5a2v1MbKsAoWg9c7y5x3w1u0s9cP', 'therapist', 'Active', '+1 (555) 010-0007'),
(8, 'Suresh Patel', 'suresh.p@roh.com', '$2y$10$b0mZoR39xV5lAdChGhW8PgW0d6b3w2NcLtBpXh0d8z6y4x2v1t0dQ', 'parent', 'Active', '+1 (555) 019-2832'),
(9, 'Robert Watson', 'robert.w@roh.com', '$2y$10$b0mZoR39xV5lAdChGhW8PgW0d6b3w2NcLtBpXh0d8z6y4x2v1t0dQ', 'parent', 'Active', '+1 (555) 014-9284')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 2. Insert Therapist Profiles
INSERT INTO `therapist_profiles` (`user_id`, `employee_id`, `designation`, `qualification`, `license_number`, `date_of_joining`, `active_caseload`, `specialties`, `about`) VALUES
(3, 'EMP-1001', 'Lead Clinical BCBA', 'M.S. Applied Behavior Analysis', 'BACB # 1-18-29401', '2021-03-15', 8, 'Verbal Behavior, Early Intervention, DTT', 'Specializes in language acquisition and functional communication training for young children with ASD.'),
(5, 'EMP-1002', 'Senior Behavior Analyst', 'Ph.D. Clinical Psychology', 'BACB # 1-16-18920', '2020-08-01', 9, 'Severe Problem Behavior, Functional Assessment', 'Clinical expert in functional behavioral assessments and crisis deceleration protocols.'),
(6, 'EMP-1003', 'RBT Clinical Specialist', 'B.S. Special Education', 'RBT-21-98214', '2022-01-10', 6, 'Sensory Integration, Mand Training', 'Certified RBT focused on child-directed natural environment training.'),
(7, 'EMP-1004', 'Assistant Behavior Analyst', 'M.Ed. Special Education', 'BCaBA # 0-20-4102', '2023-04-18', 5, 'Social Skills, Peer Mentoring', 'Runs social skills peer dyads and school readiness transitions.')
ON DUPLICATE KEY UPDATE `designation`=VALUES(`designation`);

-- 3. Insert Parent Profiles
INSERT INTO `parent_profiles` (`user_id`, `secondary_phone`, `street_address`, `city`, `state`, `postal_code`, `preferred_communication`) VALUES
(4, '+1 (555) 019-9999', '742 Evergreen Terrace', 'Springfield', 'OR', '97477', 'Email'),
(8, '+1 (555) 019-8888', '124 Conch Street', 'Seattle', 'WA', '98101', 'Phone'),
(9, '+1 (555) 014-7777', '221B Baker Boulevard', 'Portland', 'OR', '97201', 'SMS')
ON DUPLICATE KEY UPDATE `street_address`=VALUES(`street_address`);

-- 4. Insert Students
INSERT INTO `students` (`id`, `first_name`, `last_name`, `middle_name`, `dob`, `gender`, `blood_group`, `joining_date`, `program`, `primary_diagnosis`, `language`, `status`, `primary_therapist_id`, `parent_user_id`) VALUES
(1, 'Alex', 'Thomas Sam', NULL, '2019-04-12', 'Male', 'O+', '2023-01-15', 'Comprehensive ABA Early Intervention', 'Autism Spectrum Disorder (Level 2)', 'English', 'Active', 3, 4),
(2, 'Aarav', 'Patel', NULL, '2018-05-14', 'Male', 'B+', '2022-09-01', 'Verbal Behavior Intensive Program', 'Autism Spectrum Disorder (Level 1)', 'English, Hindi', 'Active', 3, 8),
(3, 'Emma', 'Watson', 'Rose', '2019-09-20', 'Female', 'A+', '2023-03-10', 'Social Communication & DTT', 'Autism Spectrum Disorder with Speech Delay', 'English', 'Active', 5, 9),
(4, 'Matt', 'Dickerson', NULL, '2019-02-18', 'Male', 'AB+', '2023-05-20', 'Comprehensive ABA Early Intervention', 'Autism Spectrum Disorder (Level 2)', 'English', 'Active', 3, 4),
(5, 'Rahul', 'Sharma', NULL, '2017-11-03', 'Male', 'O+', '2022-04-12', 'School Transition & Functional Living', 'Autism Spectrum Disorder (Level 2)', 'English', 'Active', 6, NULL),
(6, 'Sophia', 'Garcia', 'Elena', '2020-02-17', 'Female', 'O-', '2023-08-01', 'Early Echoic & Mand Training', 'Autism Spectrum Disorder (Level 3)', 'English, Spanish', 'Active', 5, NULL)
ON DUPLICATE KEY UPDATE `first_name`=VALUES(`first_name`);

-- 5. Insert Guardians
INSERT INTO `guardians` (`student_id`, `guardian_priority`, `relationship`, `first_name`, `last_name`, `phone`, `email`, `street_address`, `city`, `state`, `postal_code`, `is_emergency_contact`) VALUES
(1, 1, 'Father', 'John', 'Wilson', '+1 (555) 019-2831', 'parent@roh.com', '742 Evergreen Terrace', 'Springfield', 'OR', '97477', 1),
(1, 2, 'Mother', 'Jemi', 'Wilson', '+1 (555) 019-2839', 'jemi.w@roh.com', '742 Evergreen Terrace', 'Springfield', 'OR', '97477', 1),
(2, 1, 'Father', 'Suresh', 'Patel', '+1 (555) 019-2832', 'suresh.p@roh.com', '124 Conch Street', 'Seattle', 'WA', '98101', 1),
(3, 1, 'Father', 'Robert', 'Watson', '+1 (555) 014-9284', 'robert.w@roh.com', '221B Baker Boulevard', 'Portland', 'OR', '97201', 1)
ON DUPLICATE KEY UPDATE `first_name`=VALUES(`first_name`);

-- 6. Insert Medical History
INSERT INTO `medical_histories` (`student_id`, `has_hospital_admissions`, `hospital_admission_details`, `has_diagnosed_conditions`, `diagnosed_condition_details`, `has_allergies`, `allergy_details`, `eating_habits`, `sleeping_habits`, `has_seizures`, `pediatrician_name`, `pediatrician_phone`) VALUES
(1, 0, 'No prior inpatient admissions.', 1, 'Sensory Processing Sensitivity', 1, 'Peanuts, Tree nuts (EpiPen kept in clinic)', 'Self-feeds finger foods; prefers crunchy textures, sensitive to wet food textures.', 'Sleeps 8-9 hours; occasional night awakenings at 3 AM.', 0, 'Dr. Emily Carter, MD', '+1 (555) 012-3400'),
(2, 0, 'None', 0, 'None', 0, 'No known allergies', 'Eats independently with utensils.', 'Normal regular sleep pattern.', 0, 'Dr. David Vance, MD', '+1 (555) 012-3401')
ON DUPLICATE KEY UPDATE `allergy_details`=VALUES(`allergy_details`);

-- 7. Insert Medications
INSERT INTO `medications` (`student_id`, `medication_name`, `dosage`, `date_prescribed`, `administration_timeline`, `used_for`, `prescribing_doctor`, `is_administered_at_center`) VALUES
(1, 'Melatonin Oral Liquid', '1.5 mg', '2023-02-10', 'Bedtime (Home)', 'Sleep onset latency assistance', 'Dr. Emily Carter, MD', 0),
(1, 'Multivitamin Pediatric Drops', '1 ml', '2023-01-20', 'Morning with Breakfast', 'Dietary supplement', 'Dr. Emily Carter, MD', 0),
(2, 'Omega-3 DHA Suspension', '5 ml', '2022-11-05', 'Morning 08:30 AM', 'Nutritional support', 'Dr. David Vance, MD', 0)
ON DUPLICATE KEY UPDATE `medication_name`=VALUES(`medication_name`);

-- 8. Insert Therapy Sessions (Timetable)
INSERT INTO `therapy_sessions` (`id`, `therapist_id`, `student_id`, `session_date`, `start_time`, `end_time`, `room`, `program_title`, `status`, `clinical_notes`) VALUES
(1, 3, 1, CURRENT_DATE(), '09:00 AM', '10:15 AM', 'Sensory Room A', 'VB-MAPP Manding & Echoic Probes', 'completed', 'Completed 25 trials on manding for preferred edibles and toys. High spontaneous mand rate observed.'),
(2, 3, 4, CURRENT_DATE(), '10:30 AM', '11:45 AM', 'Table 2 (DTT Cabin)', 'Early Echoic Skill Assessment (EESA)', 'inProgress', 'Working on syllable repetition and tone matching.'),
(3, 3, 2, CURRENT_DATE(), '01:00 PM', '02:15 PM', 'Speech Cabin 1', 'Listener Responding by Function & Feature (LRFFC)', 'upcoming', 'Prepare 3-field picture arrays for LRFFC probe.'),
(4, 3, 3, CURRENT_DATE(), '02:30 PM', '03:45 PM', 'Play Area B', 'Social Dyads & Turn-Taking Probes', 'upcoming', 'Pair with peer for cooperative block building.')
ON DUPLICATE KEY UPDATE `status`=VALUES(`status`);

-- 9. Insert Director Appointments
INSERT INTO `director_appointments` (`id`, `director_user_id`, `title`, `appointment_type`, `date`, `start_time`, `end_time`, `attendee_name`, `attendee_role`, `attendee_phone`, `attendee_email`, `location`, `scheduled_by`, `status`, `notes`) VALUES
(1, 2, 'Diagnostic Intake Consultation', 'diagnosticIntake', CURRENT_DATE(), '09:00 AM', '10:00 AM', 'Mr. John Wilson (Father of Alex)', 'Parent', '+1 (555) 019-2831', 'parent@roh.com', 'Director Office Suite', 'Admin', 'confirmed', 'Review initial developmental history, speech-language reports, and establish intake schedule.'),
(2, 2, 'IEP Final Sign-Off Audit', 'iepReview', CURRENT_DATE(), '11:00 AM', '12:00 PM', 'Dr. Sarah Lee (Lead BCBA)', 'Lead Clinical BCBA', '+1 (555) 010-0003', 'therapist@roh.com', 'Director Office Suite', 'Director', 'confirmed', 'Clinical mastery audit for Alex Thomas Sam Q3 IEP before publishing to parent portal.'),
(3, 2, 'BACB 5% Monthly Clinical Supervision', 'bacbSupervision', CURRENT_DATE(), '02:00 PM', '03:00 PM', 'Priya Sharma (RBT)', 'RBT Clinical Specialist', '+1 (555) 010-0006', 'priya.s@roh.com', 'Observation Room 2', 'Director', 'confirmed', 'Direct observation of discrete trial instruction and fidelity checklist verification.')
ON DUPLICATE KEY UPDATE `status`=VALUES(`status`);

-- 10. Insert Clinical Assessments Seed Data
-- 10A. Milestone Assessments
INSERT INTO `milestone_assessments` (`student_id`, `therapist_id`, `test_number`, `level`, `assessment_date`, `total_score`, `max_score`, `manding_score`, `tacting_score`, `listener_score`, `echoic_score`, `lrffc_score`, `intraverbal_score`, `therapist_notes`) VALUES
(1, 3, 1, 'Level 1', '2026-06-15', 38.50, 45.00, 12.00, 11.50, 9.00, 6.00, 0.00, 0.00, 'Alex demonstrates excellent vocal manding for edibles; working on spontaneous tacts without prompt.'),
(2, 3, 1, 'Level 2', '2026-05-20', 62.00, 90.00, 14.00, 15.00, 13.00, 10.00, 6.00, 4.00, 'Steady progress across listener responding and 2-component tacts.'),
(3, 5, 1, 'Level 1', '2026-06-28', 29.00, 45.00, 8.00, 7.50, 8.00, 5.50, 0.00, 0.00, 'Baseline assessment completed; focus on echoic syllables and generalized motor imitation.')
ON DUPLICATE KEY UPDATE `total_score`=VALUES(`total_score`);

-- 10B. Barriers Assessments
INSERT INTO `barriers_assessments` (`student_id`, `therapist_id`, `test_number`, `assessment_date`, `total_score`, `max_score`, `barrier_scores`, `therapist_notes`) VALUES
(1, 3, 1, '2026-06-16', 14.00, 96.00, '{"Negative Behaviors": 1, "Instructional Control": 1, "Prompt Dependent": 2, "Scrolling": 1}', 'Mild prompt dependency on academic table tasks; positive behavioral momentum.'),
(2, 3, 1, '2026-05-22', 22.00, 96.00, '{"Negative Behaviors": 2, "Instructional Control": 2, "Prompt Dependent": 3, "Scrolling": 2}', 'Working on fading verbal prompts.')
ON DUPLICATE KEY UPDATE `total_score`=VALUES(`total_score`);

-- 10C. Transition Assessments
INSERT INTO `transition_assessments` (`student_id`, `therapist_id`, `test_number`, `assessment_date`, `total_score`, `max_score`, `area_scores`, `therapist_notes`) VALUES
(1, 3, 1, '2026-06-18', 64.00, 90.00, '{"Classroom Routines": 4, "Group Skills": 3, "Social Play": 4}', 'High potential for partial mainstream inclusion with shadow support.'),
(2, 3, 1, '2026-05-25', 48.00, 90.00, '{"Classroom Routines": 3, "Group Skills": 2, "Social Play": 3}', 'Follows 3-step transitions with visual schedule.')
ON DUPLICATE KEY UPDATE `total_score`=VALUES(`total_score`);

-- 10D. EESA Assessments
INSERT INTO `eesa_assessments` (`student_id`, `therapist_id`, `test_number`, `assessment_date`, `group1_score`, `group2_score`, `total_score`, `therapist_notes`) VALUES
(1, 3, 1, '2026-06-19', 21.00, 12.00, 33.00, 'Mastered Group 1 vowels and early approximations; progressing to functional consonants.'),
(2, 3, 1, '2026-05-26', 18.00, 9.00, 27.00, 'Clear repetition of open vowels.')
ON DUPLICATE KEY UPDATE `total_score`=VALUES(`total_score`);

-- 11. Insert Preference Assessments
INSERT INTO `preference_assessments` (`student_id`, `therapist_id`, `category`, `item_name`, `rating`, `hierarchy_rank`, `notes`) VALUES
(1, 3, 'Edible', 'Organic Apple Slices', 5, 'High-Preference Primary Reinforcer', 'Delivered in small slices immediately following correct independent trials.'),
(1, 3, 'Toys/Materials', 'Spinning Light-up Wheel', 5, 'High-Preference Tangible Reinforcer', '30 seconds access as terminal reinforcer after 5-trial work sprints.'),
(1, 3, 'Social', 'High-Fives & Enthusiastic Praise', 4, 'Conditioned Social Reinforcer', 'Effective when paired with tangible reinforcers.'),
(1, 3, 'Sensory', 'Deep Pressure Weighted Blanket', 4, 'Sensory Regulation Tool', 'Utilized during transition breaks between work stations.')
ON DUPLICATE KEY UPDATE `rating`=VALUES(`rating`);

-- 12. Insert Daily Data Sheets
INSERT INTO `daily_data_sheets` (`student_id`, `therapist_id`, `session_date`, `domain`, `target_skill`, `prompt_level`, `trials_completed`, `trials_successful`, `notes`) VALUES
(1, 3, CURRENT_DATE(), 'Manding', 'Vocal request for desired toy ("open car")', 'Independent', 10, 9, 'Consistent vocalization with clear eye contact.'),
(1, 3, CURRENT_DATE(), 'Tacting', 'Labeling common household items (cup, shoe, ball)', 'Verbal', 10, 8, 'Required initial partial vocal prompt on 2 trials.'),
(1, 3, CURRENT_DATE(), 'Listener Responding', 'Following 1-step motor commands ("clap hands", "sit down")', 'Independent', 10, 10, 'Target mastered at 100% fidelity.'),
(2, 3, CURRENT_DATE(), 'Intraverbal', 'Completing song phrases ("The wheels on the...")', 'Independent', 10, 8, 'Completed phrase with "bus" promptly.')
ON DUPLICATE KEY UPDATE `trials_completed`=VALUES(`trials_completed`);

-- 13. Insert IEP Reports
INSERT INTO `iep_reports` (`id`, `student_id`, `therapist_id`, `title`, `cycle_term`, `status`, `manding_score`, `tacting_score`, `listener_score`, `echoic_score`, `lrffc_score`, `goals_summary`, `director_notes`, `director_signed_by`, `director_signed_at`) VALUES
(1, 1, 3, 'Alex Thomas Sam - Q3 Comprehensive IEP', 'Q3 2026 Treatment Plan', 'Active', 12, 11, 9, 6, 4, 'Master 20 new tacts, expand vocal mand repertoire to 40 items, and achieve 80% independent peer turn-taking.', 'Approved after clinical governance audit. Meets BACB early intervention standards.', 2, '2026-07-01 10:30:00'),
(2, 2, 3, 'Aarav Patel - Q3 Behavioral Intervention Plan', 'Q3 2026 Treatment Plan', 'Pending Approval', 14, 15, 13, 10, 6, 'Reduce instructional escape behavior to <2 instances per session and increase intraverbal responses.', 'Awaiting supervisor direct probe confirmation.', NULL, NULL),
(3, 3, 5, 'Emma Watson - Speech & Verbal Behavior Plan', 'Q3 2026 Treatment Plan', 'Active', 8, 7, 8, 5, 2, 'Intensive echoic training, generalized imitation, and PECS phase 3 navigation.', 'Approved for clinical delivery.', 2, '2026-07-12 14:00:00'),
(4, 4, 3, 'Matt Dickerson - Early Intervention Protocol', 'Q3 2026 Treatment Plan', 'Pending Approval', 10, 9, 8, 7, 3, 'Establish instructional control, sensory paired reinforcement, and 10 vocal mands.', 'Pending baseline assessment completion.', NULL, NULL)
ON DUPLICATE KEY UPDATE `status`=VALUES(`status`);

-- 14. Insert Clinical Governance Settings
INSERT INTO `clinical_governance_settings` (`id`, `setting_key`, `target_mastery_criteria`, `require_two_therapists`, `reassessment_frequency`, `stagnation_alert_days`, `supervision_ratio_target`, `dual_signoff_crisis`, `director_signature_name`, `director_title`, `director_bacb_cert`, `updated_by`) VALUES
(1, 'primary_center_config', '80% across 3 consecutive sessions', 1, 'Every 6 Months', 21, 5.00, 1, 'Dr. Vincent Sterling', 'BCBA-D, Clinical Director', 'BACB # 1-19-38291', 2)
ON DUPLICATE KEY UPDATE `target_mastery_criteria`=VALUES(`target_mastery_criteria`);

-- 15. Insert Multi-Therapist Assignments
INSERT INTO `student_therapists` (`student_id`, `therapist_id`, `role_title`, `is_active`) VALUES
(1, 3, 'Primary BCBA', 1),
(1, 6, 'Speech Therapist', 1),
(2, 3, 'Primary BCBA', 1),
(3, 5, 'Primary BCBA', 1),
(4, 3, 'Primary BCBA', 1)
ON DUPLICATE KEY UPDATE `role_title`=VALUES(`role_title`);

-- 16. Insert Sample Password Reset Request (Pending Director Approval)
INSERT INTO `password_reset_requests` (`id`, `user_id`, `requested_by_admin_id`, `decision`, `requester_ip`, `requester_user_agent`, `expires_at`) VALUES
(1, 3, 1, 'Pending', '127.0.0.1', 'Mozilla/5.0 (Macintosh; Intel Mac OS X)', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 48 HOUR))
ON DUPLICATE KEY UPDATE `decision`=VALUES(`decision`);

-- 17. Insert In-App Notifications
INSERT INTO `notifications` (`recipient_user_id`, `event_type`, `title`, `message`, `is_read`) VALUES
(2, 'PASSWORD_RESET_REQUESTED', 'Password Reset Approval Needed', 'Admin initiated a password reset request for Dr. Sarah Lee (therapist@roh.com). Action required within 48 hours.', 0),
(3, 'SESSION_ASSIGNED', 'New Therapy Session Scheduled', 'A new session for Alex Thomas Sam has been scheduled for today at 09:00 AM.', 1),
(4, 'REPORT_READY', 'IEP Progress Report Published', 'The Q3 2026 Treatment Plan for Alex Thomas Sam has been signed off by Clinical Director.', 0)
ON DUPLICATE KEY UPDATE `title`=VALUES(`title`);


SET FOREIGN_KEY_CHECKS = 1;
