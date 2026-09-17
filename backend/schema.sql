-- ============================================================
-- LMS Database Schema
-- Run this once against your MySQL server to create the DB.
--   mysql -u root -p < schema.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS lms_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE lms_db;

-- ------------------------------------------------------------
-- Students
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(120)  NOT NULL,
    email           VARCHAR(255)  NOT NULL UNIQUE,
    password_hash   VARCHAR(255)  NOT NULL,
    interest_field  VARCHAR(60)   NULL,          -- e.g. 'devops', 'developer', 'cybersecurity', 'linux'
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- Learning fields (keeps field names/labels consistent + easy to extend)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fields (
    slug   VARCHAR(60)  PRIMARY KEY,   -- 'devops'
    label  VARCHAR(80)  NOT NULL,      -- 'DevOps'
    icon   VARCHAR(10)  NOT NULL DEFAULT '📦'
);

-- ------------------------------------------------------------
-- Course materials (curated links: YouTube videos, articles, courses)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS materials (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    field_slug    VARCHAR(60)   NOT NULL,
    title         VARCHAR(255)  NOT NULL,
    url           VARCHAR(500)  NOT NULL,
    resource_type ENUM('video','article','course','docs') NOT NULL DEFAULT 'video',
    platform      VARCHAR(80)   NULL,            -- 'YouTube', 'freeCodeCamp', 'Official Docs', ...
    description   VARCHAR(500)  NULL,
    FOREIGN KEY (field_slug) REFERENCES fields(slug)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ------------------------------------------------------------
-- Time tracking — one row per student per calendar day.
-- The frontend sends small "heartbeat" pings while the tab is
-- active/focused, and the backend adds seconds to today's row.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS time_logs (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    user_id       INT NOT NULL,
    log_date      DATE NOT NULL,
    seconds_spent INT NOT NULL DEFAULT 0,
    UNIQUE KEY uniq_user_day (user_id, log_date),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
