-- ============================================================================
-- Ray of Hope Center for Autism ERP (ROH-ERP)
-- Production Database Schema & Reference Data
-- Engine: InnoDB | Charset: utf8mb4 | Collation: utf8mb4_unicode_ci
-- Version: 2.0.0
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `roh_erp` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `roh_erp`;

SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------------------------
-- 1. USERS & CORE AUTHENTICATION TABLE
-- Supported roles: admin, director, therapist, parent
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
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
DROP TABLE IF EXISTS `therapist_profiles`;
CREATE TABLE `therapist_profiles` (
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
DROP TABLE IF EXISTS `parent_profiles`;
CREATE TABLE `parent_profiles` (
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
DROP TABLE IF EXISTS `students`;
CREATE TABLE `students` (
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
DROP TABLE IF EXISTS `guardians`;
CREATE TABLE `guardians` (
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
DROP TABLE IF EXISTS `medical_histories`;
CREATE TABLE `medical_histories` (
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
DROP TABLE IF EXISTS `medications`;
CREATE TABLE `medications` (
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
DROP TABLE IF EXISTS `therapy_sessions`;
CREATE TABLE `therapy_sessions` (
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
DROP TABLE IF EXISTS `director_appointments`;
CREATE TABLE `director_appointments` (
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
-- 10. VB-MAPP ASSESSMENTS TABLE (Milestones, Barriers, Transitions, EESA)
-- Granular assessment scores across Verbal Behavior domains
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS `vb_assessments`;
CREATE TABLE `vb_assessments` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `therapist_id` INT UNSIGNED NOT NULL,
  `assessment_type` ENUM('milestone', 'barriers', 'transition', 'eesa') NOT NULL DEFAULT 'milestone',
  `level` ENUM('Level 1', 'Level 2', 'Level 3', 'Comprehensive') NOT NULL DEFAULT 'Level 1',
  `assessment_date` DATE NOT NULL,
  `total_score` DECIMAL(6,2) DEFAULT 0.00,
  `max_score` DECIMAL(6,2) DEFAULT 170.00,
  `manding_score` DECIMAL(5,2) DEFAULT 0.00,
  `tacting_score` DECIMAL(5,2) DEFAULT 0.00,
  `listener_score` DECIMAL(5,2) DEFAULT 0.00,
  `echoic_score` DECIMAL(5,2) DEFAULT 0.00,
  `lrffc_score` DECIMAL(5,2) DEFAULT 0.00,
  `intraverbal_score` DECIMAL(5,2) DEFAULT 0.00,
  `imitation_score` DECIMAL(5,2) DEFAULT 0.00,
  `social_score` DECIMAL(5,2) DEFAULT 0.00,
  `milestones_data` JSON DEFAULT NULL, -- Full domain-level item breakdown
  `therapist_notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_vb_student` (`student_id`),
  INDEX `idx_vb_type` (`assessment_type`),
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`therapist_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 11. PREFERENCE ASSESSMENTS (Reinforcer Inventory)
-- Categorized motivators (Edibles, Toys, Sensory, Social) with preference ratings
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS `preference_assessments`;
CREATE TABLE `preference_assessments` (
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
DROP TABLE IF EXISTS `daily_data_sheets`;
CREATE TABLE `daily_data_sheets` (
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
DROP TABLE IF EXISTS `iep_reports`;
CREATE TABLE `iep_reports` (
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
DROP TABLE IF EXISTS `clinical_governance_settings`;
CREATE TABLE `clinical_governance_settings` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `setting_key` VARCHAR(80) NOT NULL UNIQUE,
  `target_mastery_criteria` VARCHAR(120) NOT NULL DEFAULT '80% across 3 consecutive sessions',
  `require_two_therapists` TINYINT(1) NOT NULL DEFAULT 1,
  `reassessment_frequency` VARCHAR(80) NOT NULL DEFAULT 'Every 6 Months',
  `stagnation_alert_days` INT UNSIGNED NOT NULL DEFAULT 21,
  `supervision_ratio_target` DECIMAL(4,2) NOT NULL DEFAULT 5.00, -- BACB 5% rule
  `dual_signoff_crisis` TINYINT(1) NOT NULL DEFAULT 1,
  `director_signature_name` VARCHAR(120) NOT NULL DEFAULT 'Dr. Vincent Sterling',
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
DROP TABLE IF EXISTS `audit_logs`;
CREATE TABLE `audit_logs` (
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
DROP TABLE IF EXISTS `password_reset_requests`;
CREATE TABLE `password_reset_requests` (
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
DROP TABLE IF EXISTS `student_therapists`;
CREATE TABLE `student_therapists` (
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
DROP TABLE IF EXISTS `session_report_versions`;
CREATE TABLE `session_report_versions` (
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
DROP TABLE IF EXISTS `notifications`;
CREATE TABLE `notifications` (
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
DROP TABLE IF EXISTS `parental_consents`;
CREATE TABLE `parental_consents` (
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

SET FOREIGN_KEY_CHECKS = 1;

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

-- 10. Insert VB-MAPP Assessments
INSERT INTO `vb_assessments` (`student_id`, `therapist_id`, `assessment_type`, `level`, `assessment_date`, `total_score`, `max_score`, `manding_score`, `tacting_score`, `listener_score`, `echoic_score`, `lrffc_score`, `intraverbal_score`, `therapist_notes`) VALUES
(1, 3, 'milestone', 'Level 1', '2026-06-15', 38.50, 45.00, 12.00, 11.50, 9.00, 6.00, 0.00, 0.00, 'Alex demonstrates excellent vocal manding for edibles; working on spontaneous tacts without prompt.'),
(2, 3, 'milestone', 'Level 2', '2026-05-20', 62.00, 90.00, 14.00, 15.00, 13.00, 10.00, 6.00, 4.00, 'Steady progress across listener responding and 2-component tacts.'),
(3, 5, 'milestone', 'Level 1', '2026-06-28', 29.00, 45.00, 8.00, 7.50, 8.00, 5.50, 0.00, 0.00, 'Baseline assessment completed; focus on echoic syllables and generalized motor imitation.')
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

