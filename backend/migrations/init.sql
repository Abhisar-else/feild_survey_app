-- ============================================================
-- Field Survey App — MySQL Database Schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS field_survey_db;
USE field_survey_db;

-- ── Users ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin', 'field_worker') DEFAULT 'field_worker',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── Surveys ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS surveys (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  created_by INT,
  status ENUM('active', 'completed', 'draft') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ── Questions ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS questions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  survey_id INT NOT NULL,
  question_text TEXT NOT NULL,
  question_type ENUM('Text Input','Multiple Choice','Checkbox','Rating','Date','Number') DEFAULT 'Text Input',
  question_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (survey_id) REFERENCES surveys(id) ON DELETE CASCADE
);

-- ── Responses ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS responses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  survey_id INT NOT NULL,
  user_id INT NOT NULL,
  answers JSON,
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  device_id VARCHAR(100),
  synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (survey_id) REFERENCES surveys(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ── Seed: Default Admin User ─────────────────────────────────
-- Password: admin123 (bcrypt hash)
INSERT IGNORE INTO users (name, email, password_hash, role)
VALUES (
  'Admin User',
  'admin@gmail.com',
  '$2a$10$wUgPzar/8eSQGPuwJAiZnO98tDenry8R.u2hYZvVKS7bK.7KulY3i',
  'admin'
);

-- ── Seed: Default Field Worker ───────────────────────────────
-- Password: worker123 (bcrypt hash)
INSERT IGNORE INTO users (name, email, password_hash, role)
VALUES (
  'Field Worker',
  'worker@gmail.com',
  '$2a$10$UizS7gz32yCUb2fYtBuNbeU/6QL1T.gj5CbzyCiGQMFKYKwSptdgi',
  'field_worker'
);
