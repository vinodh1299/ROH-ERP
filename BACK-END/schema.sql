-- ============================================================================
-- Ray of Hope Center for Autism ERP (ROH-ERP)
-- Production Database Schema & Reference Data
-- Engine: InnoDB | Charset: utf8mb4 | Collation: utf8mb4_unicode_ci
-- Version: 2.0.0
-- ============================================================================

-- Safe to run repeatedly: tables are created only if missing; existing data is never dropped.
-- Runs against whichever database you are connected to (local roh_erp or DreamHost roherp).

SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------------------------
-- 1. USERS & CORE AUTHENTICATION TABLE
-- Supported roles: admin, director, therapist, parent
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(120) NOT NULL,
  `email` VARCHAR(150) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `role` ENUM('admin', 'director', 'therapist', 'parent') NOT NULL,
  `status` ENUM('Active', 'De-Activated', 'Pending') DEFAULT 'Active',
  `phone` VARCHAR(40) DEFAULT NULL,
  `avatar_url` VARCHAR(255) DEFAULT NULL,
  `must_change_password` TINYINT(1) NOT NULL DEFAULT 0,
  `failed_login_attempts` INT UNSIGNED NOT NULL DEFAULT 0,
  `locked_until` TIMESTAMP NULL DEFAULT NULL,
  `token_version` INT UNSIGNED NOT NULL DEFAULT 1,
  `last_login_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_users_role` (`role`),
  INDEX `idx_users_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 2. THERAPIST PROFILES TABLE
-- Extends therapist users with credentials, BACB license, caseload, designation
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `therapist_profiles` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL UNIQUE,
  `employee_id` VARCHAR(50) DEFAULT NULL UNIQUE,
  `designation` VARCHAR(100) NOT NULL DEFAULT 'Behavior Therapist',
  `qualification` VARCHAR(150) DEFAULT 'M.S. Applied Behavior Analysis',
  `license_number` VARCHAR(80) DEFAULT NULL, -- e.g. BACB / RBT / BCBA #
  `date_of_birth` DATE DEFAULT NULL,
  `date_of_joining` DATE DEFAULT NULL,
  `active_caseload` INT UNSIGNED DEFAULT 0,
  `specialties` VARCHAR(255) DEFAULT 'Early Intervention, Verbal Behavior, NET',
  `about` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 3. PARENT / GUARDIAN PROFILES TABLE
-- Extends parent users with emergency contacts, residence, relationship
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `parent_profiles` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL UNIQUE,
  `secondary_phone` VARCHAR(40) DEFAULT NULL,
  `street_address` VARCHAR(255) DEFAULT NULL,
  `city` VARCHAR(80) DEFAULT NULL,
  `state` VARCHAR(80) DEFAULT NULL,
  `postal_code` VARCHAR(30) DEFAULT NULL,
  `occupation` VARCHAR(100) DEFAULT NULL,
  `preferred_communication` ENUM('Phone', 'Email', 'SMS', 'In-Person') DEFAULT 'Email',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 4. STUDENTS TABLE
-- Core student demographics, diagnosis, enrollment program & status
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `students` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `first_name` VARCHAR(80) NOT NULL,
  `last_name` VARCHAR(80) NOT NULL,
  `middle_name` VARCHAR(80) DEFAULT NULL,
  `dob` DATE NOT NULL,
  `gender` ENUM('Male', 'Female', 'Other') NOT NULL DEFAULT 'Male',
  `blood_group` VARCHAR(10) DEFAULT 'O+',
  `joining_date` DATE DEFAULT NULL,
  `program` VARCHAR(120) DEFAULT 'Comprehensive ABA Early Intervention',
  `primary_diagnosis` VARCHAR(150) DEFAULT 'Autism Spectrum Disorder (Level 2)',
  `language` VARCHAR(80) DEFAULT 'English',
  `status` ENUM('Active', 'De-Activated', 'Graduated', 'On Leave') DEFAULT 'Active',
  `primary_therapist_id` INT UNSIGNED DEFAULT NULL,
  `parent_user_id` INT UNSIGNED DEFAULT NULL,
  `photo_url` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_students_status` (`status`),
  INDEX `idx_students_primary_therapist` (`primary_therapist_id`),
  INDEX `idx_students_parent` (`parent_user_id`),
  FOREIGN KEY (`primary_therapist_id`) REFERENCES `users`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`parent_user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 5. GUARDIANS TABLE
-- Multiple emergency contacts / guardians per student
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `guardians` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `guardian_priority` TINYINT UNSIGNED DEFAULT 1, -- 1 = Primary, 2 = Secondary
  `relationship` VARCHAR(50) NOT NULL DEFAULT 'Mother', -- Mother, Father, Legal Guardian
  `first_name` VARCHAR(80) NOT NULL,
  `last_name` VARCHAR(80) NOT NULL,
  `phone` VARCHAR(40) NOT NULL,
  `email` VARCHAR(120) DEFAULT NULL,
  `street_address` VARCHAR(255) DEFAULT NULL,
  `city` VARCHAR(80) DEFAULT NULL,
  `state` VARCHAR(80) DEFAULT NULL,
  `postal_code` VARCHAR(30) DEFAULT NULL,
  `is_emergency_contact` TINYINT(1) DEFAULT 1,
  `notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_guardians_student` (`student_id`),
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 6. MEDICAL HISTORIES & ALLERGIES TABLE
-- Detailed clinical intake, eating/sleeping habits, allergies, hospitalizations
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `medical_histories` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL UNIQUE,
  `has_hospital_admissions` TINYINT(1) DEFAULT 0,
  `hospital_admission_details` TEXT DEFAULT NULL,
  `has_diagnosed_conditions` TINYINT(1) DEFAULT 0,
  `diagnosed_condition_details` TEXT DEFAULT NULL,
  `has_infectious_diseases` TINYINT(1) DEFAULT 0,
  `infectious_disease_details` TEXT DEFAULT NULL,
  `has_allergies` TINYINT(1) DEFAULT 0,
  `allergy_details` TEXT DEFAULT NULL,
  `eating_habits` TEXT DEFAULT NULL,
  `sleeping_habits` TEXT DEFAULT NULL,
  `has_seizures` TINYINT(1) DEFAULT 0,
  `seizure_protocol` TEXT DEFAULT NULL,
  `pediatrician_name` VARCHAR(120) DEFAULT NULL,
  `pediatrician_phone` VARCHAR(40) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 7. MEDICATIONS TABLE
-- Prescriptions, administration timelines, dosage, purpose
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `medications` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `medication_name` VARCHAR(150) NOT NULL,
  `dosage` VARCHAR(100) NOT NULL,
  `date_prescribed` DATE DEFAULT NULL,
  `administration_timeline` VARCHAR(120) NOT NULL, -- e.g. "Morning 08:00 AM", "After Lunch"
  `used_for` VARCHAR(255) DEFAULT NULL,
  `prescribing_doctor` VARCHAR(120) DEFAULT NULL,
  `is_administered_at_center` TINYINT(1) DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_medications_student` (`student_id`),
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 8. THERAPY SESSIONS TABLE (Master Timetable & Daily Schedule)
-- Daily scheduling, room assignments, statuses, session notes
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `therapy_sessions` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `therapist_id` INT UNSIGNED NOT NULL,
  `student_id` INT UNSIGNED NOT NULL,
  `session_date` DATE NOT NULL,
  `start_time` VARCHAR(20) NOT NULL, -- e.g. "09:00 AM"
  `end_time` VARCHAR(20) NOT NULL,   -- e.g. "10:15 AM"
  `room` VARCHAR(80) NOT NULL DEFAULT 'Sensory Room A',
  `program_title` VARCHAR(150) NOT NULL DEFAULT 'VB-MAPP Manding & Echoic Probes',
  `status` ENUM('upcoming', 'inProgress', 'completed', 'cancelled') DEFAULT 'upcoming',
  `clinical_notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_sessions_therapist_date` (`therapist_id`, `session_date`),
  INDEX `idx_sessions_student_date` (`student_id`, `session_date`),
  INDEX `idx_sessions_status` (`status`),
  FOREIGN KEY (`therapist_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT,
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 9. DIRECTOR APPOINTMENTS TABLE (Executive Consultations & Supervisions)
-- Parent intakes, IEP audits, BACB 5% supervisions, staff reviews
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `director_appointments` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `director_user_id` INT UNSIGNED NOT NULL,
  `title` VARCHAR(180) NOT NULL,
  `appointment_type` ENUM('diagnosticIntake', 'iepReview', 'bacbSupervision', 'parentConference', 'staffConsultation') NOT NULL,
  `date` DATE NOT NULL,
  `start_time` VARCHAR(20) NOT NULL, -- e.g. "09:00 AM"
  `end_time` VARCHAR(20) NOT NULL,   -- e.g. "10:00 AM"
  `attendee_name` VARCHAR(120) NOT NULL,
  `attendee_role` VARCHAR(80) NOT NULL DEFAULT 'Parent',
  `attendee_phone` VARCHAR(40) DEFAULT NULL,
  `attendee_email` VARCHAR(120) DEFAULT NULL,
  `location` VARCHAR(120) NOT NULL DEFAULT 'Director Office Suite',
  `scheduled_by` VARCHAR(80) NOT NULL DEFAULT 'Admin',
  `status` ENUM('confirmed', 'tentative', 'completed', 'cancelled') DEFAULT 'confirmed',
  `notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_appointments_director_date` (`director_user_id`, `date`),
  INDEX `idx_appointments_status` (`status`),
  FOREIGN KEY (`director_user_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 10. DEDICATED CLINICAL ASSESSMENT TABLES
-- Separate tables for Milestones, Barriers, Transitions, and EESA
-- ----------------------------------------------------------------------------

-- 10A. VB-MAPP MILESTONE ASSESSMENTS (Levels 1, 2, 3 across 16 domains)
CREATE TABLE IF NOT EXISTS `milestone_assessments` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `therapist_id` INT UNSIGNED NOT NULL,
  `test_number` TINYINT UNSIGNED NOT NULL DEFAULT 1, -- 1: 1st color, 2: 2nd color, 3: 3rd, 4: 4th
  `level` ENUM('Level 1', 'Level 2', 'Level 3', 'Comprehensive') NOT NULL DEFAULT 'Level 1',
  `assessment_date` DATE NOT NULL,
  `total_score` DECIMAL(6,2) DEFAULT 0.00,
  `max_score` DECIMAL(6,2) DEFAULT 170.00,
  `manding_score` DECIMAL(5,2) DEFAULT 0.00,
  `tacting_score` DECIMAL(5,2) DEFAULT 0.00,
  `listener_score` DECIMAL(5,2) DEFAULT 0.00,
  `echoic_score` DECIMAL(5,2) DEFAULT 0.00,
  `vocal_score` DECIMAL(5,2) DEFAULT 0.00,
  `vp_mts_score` DECIMAL(5,2) DEFAULT 0.00,
  `play_score` DECIMAL(5,2) DEFAULT 0.00,
  `social_score` DECIMAL(5,2) DEFAULT 0.00,
  `imitation_score` DECIMAL(5,2) DEFAULT 0.00,
  `lrffc_score` DECIMAL(5,2) DEFAULT 0.00,
  `intraverbal_score` DECIMAL(5,2) DEFAULT 0.00,
  `group_score` DECIMAL(5,2) DEFAULT 0.00,
  `linguistic_score` DECIMAL(5,2) DEFAULT 0.00,
  `reading_score` DECIMAL(5,2) DEFAULT 0.00,
  `writing_score` DECIMAL(5,2) DEFAULT 0.00,
  `math_score` DECIMAL(5,2) DEFAULT 0.00,
  `scores_detail` JSON DEFAULT NULL, -- Granular item-by-item grid responses (e.g. Mand-1: 1, Mand-2: 0.5)
  `therapist_notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_milestone_student` (`student_id`),
  INDEX `idx_milestone_test` (`test_number`),
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`therapist_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10B. VB-MAPP BARRIERS ASSESSMENTS (24 Learning Barriers, scored 0 to 4)
CREATE TABLE IF NOT EXISTS `barriers_assessments` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `therapist_id` INT UNSIGNED NOT NULL,
  `test_number` TINYINT UNSIGNED NOT NULL DEFAULT 1, -- 1 to 4 comparison tests
  `assessment_date` DATE NOT NULL,
  `total_score` DECIMAL(5,2) DEFAULT 0.00,
  `max_score` DECIMAL(5,2) DEFAULT 96.00, -- 24 barriers * 4 max
  `barrier_scores` JSON DEFAULT NULL, -- Key-value map of all 24 barrier scores (0 to 4)
  `therapist_notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_barriers_student` (`student_id`),
  INDEX `idx_barriers_test` (`test_number`),
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`therapist_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10C. VB-MAPP TRANSITION ASSESSMENTS (18 Educational Readiness Areas, scored 1 to 5)
CREATE TABLE IF NOT EXISTS `transition_assessments` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `therapist_id` INT UNSIGNED NOT NULL,
  `test_number` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `assessment_date` DATE NOT NULL,
  `total_score` DECIMAL(5,2) DEFAULT 0.00,
  `max_score` DECIMAL(5,2) DEFAULT 90.00, -- 18 areas * 5 max
  `area_scores` JSON DEFAULT NULL, -- Key-value map of all 18 transition scores (1 to 5)
  `therapist_notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_transition_student` (`student_id`),
  INDEX `idx_transition_test` (`test_number`),
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`therapist_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10D. VB-MAPP EARLY ECHOIC SKILLS ASSESSMENTS (EESA - Groups 1 & 2)
CREATE TABLE IF NOT EXISTS `eesa_assessments` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `therapist_id` INT UNSIGNED NOT NULL,
  `test_number` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `assessment_date` DATE NOT NULL,
  `group1_score` DECIMAL(5,2) DEFAULT 0.00,
  `group2_score` DECIMAL(5,2) DEFAULT 0.00,
  `total_score` DECIMAL(5,2) DEFAULT 0.00,
  `responses` JSON DEFAULT NULL, -- Detailed map of target items with response state ('Yes', 'Half', 'No')
  `therapist_notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_eesa_student` (`student_id`),
  INDEX `idx_eesa_test` (`test_number`),
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`therapist_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 11. PREFERENCE ASSESSMENTS (Reinforcer Inventory)
-- Categorized motivators (Edibles, Toys, Sensory, Social) with preference ratings
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `preference_assessments` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `therapist_id` INT UNSIGNED DEFAULT NULL,
  `category` ENUM('Edible', 'Toys/Materials', 'Social', 'Sensory', 'Other') NOT NULL,
  `item_name` VARCHAR(150) NOT NULL,
  `rating` TINYINT UNSIGNED NOT NULL DEFAULT 5, -- 1 to 5 scale
  `hierarchy_rank` VARCHAR(50) DEFAULT 'High-Preference Primary Reinforcer',
  `notes` TEXT DEFAULT NULL,
  `assessment_date` DATE DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_preference_student` (`student_id`),
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`therapist_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 12. DAILY DISCRETE-TRIAL DATA SHEETS TABLE
-- Clinical session trials, prompt levels, success rates
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `daily_data_sheets` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `therapist_id` INT UNSIGNED NOT NULL,
  `session_date` DATE NOT NULL,
  `domain` VARCHAR(100) NOT NULL, -- e.g. Manding, Tacting, Listener Responding
  `target_skill` VARCHAR(255) NOT NULL DEFAULT 'Vocal request with 2-word phrase',
  `prompt_level` ENUM('Independent', 'Verbal', 'Gestural', 'Physical') NOT NULL DEFAULT 'Independent',
  `trials_completed` INT UNSIGNED NOT NULL DEFAULT 0,
  `trials_successful` INT UNSIGNED NOT NULL DEFAULT 0,
  `percentage_success` DECIMAL(5,2) GENERATED ALWAYS AS (
    CASE WHEN `trials_completed` > 0 THEN (`trials_successful` / `trials_completed`) * 100.0 ELSE 0.0 END
  ) STORED,
  `notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_daily_student_date` (`student_id`, `session_date`),
  INDEX `idx_daily_therapist` (`therapist_id`),
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`therapist_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 13. INDIVIDUALIZED EDUCATION PLANS (IEP REPORTS)
-- Treatment plans, milestone scores, approval status, digital signature
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `iep_reports` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `therapist_id` INT UNSIGNED NOT NULL,
  `title` VARCHAR(180) NOT NULL,
  `cycle_term` VARCHAR(80) NOT NULL DEFAULT 'Q3 2026 Treatment Plan',
  `status` ENUM('Pending Approval', 'Active', 'Returned for Revision', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Pending Approval',
  `manding_score` INT UNSIGNED DEFAULT 0,
  `tacting_score` INT UNSIGNED DEFAULT 0,
  `listener_score` INT UNSIGNED DEFAULT 0,
  `echoic_score` INT UNSIGNED DEFAULT 0,
  `lrffc_score` INT UNSIGNED DEFAULT 0,
  `goals_summary` TEXT DEFAULT NULL,
  `director_notes` TEXT DEFAULT NULL,
  `director_signed_by` INT UNSIGNED DEFAULT NULL,
  `director_signed_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_iep_student` (`student_id`),
  INDEX `idx_iep_therapist` (`therapist_id`),
  INDEX `idx_iep_status` (`status`),
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`therapist_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT,
  FOREIGN KEY (`director_signed_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 14. CLINICAL GOVERNANCE & CENTER SETTINGS TABLE
-- Executive ABA thresholds, mastery standards, BACB supervision quota
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `clinical_governance_settings` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `setting_key` VARCHAR(80) NOT NULL UNIQUE,
  `target_mastery_criteria` VARCHAR(120) NOT NULL DEFAULT '80% across 3 consecutive sessions',
  `require_two_therapists` TINYINT(1) NOT NULL DEFAULT 1,
  `reassessment_frequency` VARCHAR(80) NOT NULL DEFAULT 'Every 6 Months',
  `stagnation_alert_days` INT UNSIGNED NOT NULL DEFAULT 21,
  `supervision_ratio_target` DECIMAL(4,2) NOT NULL DEFAULT 5.00, -- BACB 5% rule
  `dual_signoff_crisis` TINYINT(1) NOT NULL DEFAULT 1,
  `director_signature_name` VARCHAR(120) NOT NULL DEFAULT 'Clinical Director',
  `director_title` VARCHAR(120) NOT NULL DEFAULT 'BCBA-D, Clinical Director',
  `director_bacb_cert` VARCHAR(80) NOT NULL DEFAULT 'BACB # 1-19-38291',
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`updated_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 15. AUDIT LOGS TABLE
-- Tracks sensitive actions, authentication events, deletions, and clinical sign-offs
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `audit_logs` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED DEFAULT NULL,
  `user_role` VARCHAR(50) DEFAULT NULL,
  `action` VARCHAR(100) NOT NULL, -- e.g. 'LOGIN', 'IEP_SIGN_OFF', 'DELETE_STUDENT', 'UPDATE_SETTINGS'
  `target_entity` VARCHAR(80) DEFAULT NULL, -- e.g. 'students', 'iep_reports'
  `target_id` INT UNSIGNED DEFAULT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `user_agent` VARCHAR(255) DEFAULT NULL,
  `details` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_audit_user` (`user_id`),
  INDEX `idx_audit_action` (`action`),
  INDEX `idx_audit_created` (`created_at`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 16. PASSWORD RESET REQUESTS TABLE (Admin/Director Approval Workflow)
-- FRS 3.2: 10-point audit log, Director in-app approval, 48-hour expiration
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `password_reset_requests` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `requested_by_admin_id` INT UNSIGNED NOT NULL,
  `director_id` INT UNSIGNED DEFAULT NULL,
  `decision` ENUM('Pending', 'Approved', 'Rejected', 'Expired', 'Completed') NOT NULL DEFAULT 'Pending',
  `request_timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `decision_timestamp` TIMESTAMP NULL DEFAULT NULL,
  `completed_timestamp` TIMESTAMP NULL DEFAULT NULL,
  `requester_ip` VARCHAR(45) NOT NULL,
  `requester_user_agent` VARCHAR(255) DEFAULT NULL,
  `temp_password_hash` VARCHAR(255) DEFAULT NULL,
  `expires_at` TIMESTAMP NOT NULL,
  `rejection_reason` TEXT DEFAULT NULL,
  INDEX `idx_reset_user` (`user_id`),
  INDEX `idx_reset_status` (`decision`),
  INDEX `idx_reset_expires` (`expires_at`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`requested_by_admin_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`director_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 17. STUDENT THERAPISTS LINKING & REASSIGNMENT HISTORY TABLE
-- FRS 2.4: Multi-therapist support (Speech, OT, ABA) and history preservation
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `student_therapists` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `therapist_id` INT UNSIGNED NOT NULL,
  `role_title` ENUM('Primary BCBA', 'Speech Therapist', 'Occupational Therapist', 'RBT Behavior Technician', 'Secondary') NOT NULL DEFAULT 'Primary BCBA',
  `assigned_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `unassigned_at` TIMESTAMP NULL DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  INDEX `idx_student_therapist_active` (`student_id`, `is_active`),
  INDEX `idx_therapist_caseload` (`therapist_id`, `is_active`),
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`therapist_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 18. SESSION REPORT VERSIONS TABLE
-- FRS 5.3: Versioned clinical reports preventing silent overwrites
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `session_report_versions` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `report_id` INT UNSIGNED NOT NULL,
  `version_number` INT UNSIGNED NOT NULL DEFAULT 1,
  `editor_id` INT UNSIGNED NOT NULL,
  `content_json` JSON NOT NULL,
  `change_reason` VARCHAR(255) DEFAULT 'Initial clinical report submission',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_report_version` (`report_id`, `version_number`),
  FOREIGN KEY (`report_id`) REFERENCES `iep_reports`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`editor_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 19. IN-APP NOTIFICATIONS TABLE
-- FRS 6: Central in-app notification center for all 4 roles
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `recipient_user_id` INT UNSIGNED NOT NULL,
  `event_type` VARCHAR(80) NOT NULL, -- e.g. 'PASSWORD_RESET_REQUESTED', 'SESSION_ASSIGNED', 'REPORT_READY'
  `title` VARCHAR(180) NOT NULL,
  `message` TEXT NOT NULL,
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `metadata_json` JSON DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_notif_recipient` (`recipient_user_id`, `is_read`),
  FOREIGN KEY (`recipient_user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 20. PARENTAL CONSENTS TABLE (India DPDP Act 2023 Compliance)
-- FRS 7: Minor data protection, digital consent capture, IP & timestamp audit
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `parental_consents` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `guardian_id` INT UNSIGNED DEFAULT NULL,
  `consent_version` VARCHAR(50) NOT NULL DEFAULT 'DPDP-2023-V1',
  `consent_title` VARCHAR(180) NOT NULL DEFAULT 'Consent for Processing Sensitive Developmental Health Data',
  `ip_address` VARCHAR(45) NOT NULL,
  `user_agent` VARCHAR(255) DEFAULT NULL,
  `agreed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_consent_student` (`student_id`),
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`guardian_id`) REFERENCES `guardians`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- SUPERVISION LOGS TABLE
-- BACB supervision hours a director logs against a therapist
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `supervision_logs` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `therapist_id` INT UNSIGNED NOT NULL,
  `supervisor_id` INT UNSIGNED NOT NULL,
  `supervision_type` VARCHAR(120) NOT NULL,
  `hours` DECIMAL(5,2) NOT NULL,
  `log_date` DATE NOT NULL,
  `notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_supervision_therapist` (`therapist_id`),
  FOREIGN KEY (`therapist_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`supervisor_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- CENTER SETTINGS TABLE
-- Admin-editable center details (name, portal title, support contacts)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `center_settings` (
  `setting_key` VARCHAR(80) PRIMARY KEY,
  `setting_value` VARCHAR(255) NOT NULL DEFAULT '',
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`updated_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
