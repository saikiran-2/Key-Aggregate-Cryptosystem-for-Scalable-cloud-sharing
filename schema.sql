-- Full schema: multi-file aggregate keys + multi-admin with approval workflow.

CREATE DATABASE IF NOT EXISTS key_agg;
USE key_agg;

-- People who receive shared files (patients, students, clients - any recipient)
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100),
  password VARCHAR(50),
  email VARCHAR(100),
  phone VARCHAR(20),
  status VARCHAR(10) DEFAULT 'active'
);

-- People who upload & share files (doctors, teachers, staff - any provider).
-- The one "main admin" is NOT a row here - it logs in with admin.username/
-- admin.password from config.properties and approves everyone in this table.
CREATE TABLE admins (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  password VARCHAR(50),
  name VARCHAR(100),
  email VARCHAR(100),
  status VARCHAR(10) DEFAULT 'pending'   -- pending / approved / rejected
);

-- Every file, tagged with which admin uploaded it (owner_admin), so each
-- admin only ever sees and shares their own files.
CREATE TABLE uploaded_files (
  id INT AUTO_INCREMENT PRIMARY KEY,
  original_name VARCHAR(255),
  storage_path VARCHAR(255),    -- path of the encrypted file inside Dropbox
  file_size BIGINT,
  upload_time DATETIME,
  public_key VARCHAR(255),      -- the DES key used to encrypt this file
  owner_admin VARCHAR(50)       -- username of the admin who uploaded it
);

-- One aggregate key can cover many files: a "batch" of access granted by
-- one admin to one user, identified by a single agg_key.
CREATE TABLE share_batches (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50),         -- recipient
  agg_key VARCHAR(255),
  owner_admin VARCHAR(50),      -- which admin issued this key
  created_time DATETIME
);

-- Which files are included under a given aggregate key (many-to-many).
CREATE TABLE share_batch_files (
  id INT AUTO_INCREMENT PRIMARY KEY,
  batch_id INT,
  file_id INT,
  UNIQUE KEY unique_batch_file (batch_id, file_id),
  FOREIGN KEY (batch_id) REFERENCES share_batches(id),
  FOREIGN KEY (file_id) REFERENCES uploaded_files(id)
);
