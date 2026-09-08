-- ============================================================================
-- Ray of Hope Center for Autism ERP Database Schema
-- Database Name: roh_erp
-- Engine: InnoDB | Charset: utf8mb4
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `roh_erp` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `roh_erp`;

-- ----------------------------------------------------------------------------
-- 1. USERS TABLE (Admin, Director, Therapist, Parent)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(120) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `role` ENUM('admin', 'director', 'therapist', 'parent') NOT NULL,
  `status` VARCHAR(20) DEFAULT 'Active',
  `phone` VARCHAR(30) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- 2. STUDENTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `students` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `first_name` VARCHAR(80) NOT NULL,
  `last_name` VARCHAR(80) NOT NULL,
  `dob` DATE DEFAULT NULL,
  `gender` VARCHAR(20) DEFAULT NULL,
  `joining_date` DATE DEFAULT NULL,
  `program` VARCHAR(100) DEFAULT NULL,
  `primary_diagnosis` VARCHAR(150) DEFAULT NULL,
  `language` VARCHAR(100) DEFAULT NULL,
  `parent_email` VARCHAR(120) DEFAULT NULL,
  `parent_name` VARCHAR(100) DEFAULT NULL,
  `phone` VARCHAR(30) DEFAULT NULL,
  `status` VARCHAR(20) DEFAULT 'Active',
  `photo_url` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- 3. GUARDIANS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `guardians` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT NOT NULL,
  `guardian_number` INT DEFAULT 1, -- 1 for Guardian #1, 2 for Guardian #2
  `relationship` VARCHAR(50) DEFAULT NULL,
  `first_name` VARCHAR(80) DEFAULT NULL,
  `last_name` VARCHAR(80) DEFAULT NULL,
  `mobile` VARCHAR(30) DEFAULT NULL,
  `email` VARCHAR(120) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- 4. MEDICATIONS & MEDICAL HISTORY TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `medications` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT NOT NULL,
  `has_condition` TINYINT(1) DEFAULT 0,
  `condition_details` TEXT DEFAULT NULL,
  `has_allergies` TINYINT(1) DEFAULT 0,
  `allergy_details` TEXT DEFAULT NULL,
  `has_seizures` TINYINT(1) DEFAULT 0,
  `seizure_details` TEXT DEFAULT NULL,
  `medication_name` VARCHAR(150) DEFAULT NULL,
  `dosage` VARCHAR(100) DEFAULT NULL,
  `reason` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- 5. IEP REPORTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `iep_reports` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT NOT NULL,
  `therapist_id` INT DEFAULT NULL,
  `title` VARCHAR(150) NOT NULL,
  `status` ENUM('Pending Approval', 'Active', 'Completed') DEFAULT 'Pending Approval',
  `manding_score` INT DEFAULT 0,
  `tacting_score` INT DEFAULT 0,
  `listener_score` INT DEFAULT 0,
  `echoic_score` INT DEFAULT 0,
  `lrffc_score` INT DEFAULT 0,
  `goals_summary` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- 6. REINFORCER ASSESSMENTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `reinforcers` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT NOT NULL,
  `category` ENUM('Edible', 'Social', 'Toys/Materials', 'Other') NOT NULL,
  `item_name` VARCHAR(150) NOT NULL,
  `rating` INT DEFAULT 5, -- 1 to 5 scale preference rating
  `notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- 7. VB-MAPP ASSESSMENTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vb_assessments` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT NOT NULL,
  `therapist_id` INT DEFAULT NULL,
  `level` VARCHAR(20) DEFAULT 'Level 1', -- Level 1, Level 2, Level 3
  `score` FLOAT DEFAULT 0,
  `max_score` FLOAT DEFAULT 170,
  `milestones_data` LONGTEXT DEFAULT NULL, -- JSON formatted milestone scores
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- 8. DAILY DATA SHEETS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `daily_data_sheets` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT NOT NULL,
  `therapist_id` INT DEFAULT NULL,
  `session_date` DATE NOT NULL,
  `domain` VARCHAR(100) NOT NULL, -- Manding, Tacting, Listener Responding, etc.
  `prompt_level` VARCHAR(50) DEFAULT 'Independent', -- Independent, Verbal, Gestural, Physical
  `trials_completed` INT DEFAULT 0,
  `trials_successful` INT DEFAULT 0,
  `notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`student_id`) REFERENCES `students`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- DEFAULT SEED DATA FOR TESTING
-- ----------------------------------------------------------------------------
INSERT INTO `users` (`name`, `email`, `password`, `role`) VALUES
('System Admin', 'admin@roh.com', 'admin123', 'admin'),
('ROH Director', 'director@roh.com', 'director123', 'director'),
('Dr. Sarah Lee', 'therapist@roh.com', 'therapist123', 'therapist'),
('Mr. John Wilson', 'parent@roh.com', 'parent123', 'parent')
ON DUPLICATE KEY UPDATE `id`=`id`;
