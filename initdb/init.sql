-- Create database (PostgreSQL automatically creates the database specified in POSTGRES_DB)
-- \c dbc_hris;

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Simplified users table (now includes employee fields directly)
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(100) UNIQUE,
  name VARCHAR(100),
  password VARCHAR(255) NOT NULL,
  role VARCHAR(20) DEFAULT 'user',
  -- Employee fields moved to users table
  employee_id VARCHAR(50) UNIQUE,
  employee_code VARCHAR(50) DEFAULT NULL,
  status VARCHAR(1) NOT NULL DEFAULT 'A', -- A (Active), I (Inactive)
  start_active_date TIMESTAMP DEFAULT NULL,
  area_code VARCHAR(50) DEFAULT NULL,
  territory_code VARCHAR(50) DEFAULT NULL,
  type VARCHAR(50) DEFAULT NULL,
  source VARCHAR(191) DEFAULT NULL,
  country VARCHAR(3) DEFAULT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_status_active_date ON users(status, start_active_date);
CREATE INDEX IF NOT EXISTS idx_users_location ON users(area_code);

CREATE TABLE IF NOT EXISTS attendances (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL, -- Changed from employee_id to user_id
  check_in_time TIMESTAMP NOT NULL,
  check_in_lat DECIMAL(10,8) DEFAULT NULL,
  check_in_lng DECIMAL(11,8) DEFAULT NULL,
  check_in_address VARCHAR(255) DEFAULT NULL,
  bssid VARCHAR(17) DEFAULT NULL, -- Wi-Fi MAC address
  cell_id VARCHAR(50) DEFAULT NULL, -- Cell tower ID
  check_out_time TIMESTAMP DEFAULT NULL,
  check_out_lat DECIMAL(10,8) DEFAULT NULL,
  check_out_lng DECIMAL(11,8) DEFAULT NULL,
  check_out_address VARCHAR(255) DEFAULT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  admin_notes TEXT DEFAULT NULL,
  submission_type VARCHAR(20) DEFAULT 'check_in', -- 'check_in', 'check_out', 'break_start', 'break_end'
  is_offline_submission BOOLEAN DEFAULT FALSE, -- Track if submitted offline
  offline_timestamp TIMESTAMP DEFAULT NULL, -- Original timestamp when captured offline
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) -- Changed reference
);

CREATE INDEX IF NOT EXISTS idx_attendances_user ON attendances(user_id); -- Changed from employee
CREATE INDEX IF NOT EXISTS idx_attendances_status_created ON attendances(status, created_at);
CREATE INDEX IF NOT EXISTS idx_attendances_network_info ON attendances(bssid, cell_id);
CREATE INDEX IF NOT EXISTS idx_attendances_user_date ON attendances(user_id, DATE(check_in_time)); -- Changed from employee
CREATE INDEX IF NOT EXISTS idx_attendances_offline ON attendances(is_offline_submission, offline_timestamp);

CREATE TABLE IF NOT EXISTS attendance_photos (
  id BIGSERIAL PRIMARY KEY,
  attendance_id BIGINT NOT NULL,
  photo_type VARCHAR(20) NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_path VARCHAR(500) NOT NULL,
  file_size BIGINT DEFAULT NULL,
  mime_type VARCHAR(100) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT NULL,
  updated_at TIMESTAMP DEFAULT NULL,
  deleted_at TIMESTAMP DEFAULT NULL,
  FOREIGN KEY (attendance_id) REFERENCES attendances(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_attendance_photos_attendance ON attendance_photos(attendance_id);
CREATE INDEX IF NOT EXISTS idx_attendance_photos_deleted_at ON attendance_photos(deleted_at);

-- Insert sample users with employee data included
INSERT INTO users (username, email, name, password, role, employee_id, employee_code, status, start_active_date, country, is_active, created_at, updated_at) VALUES
('admin', 'admin@example.com', 'Admin User', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'ADM001', 'AD001', 'A', NOW(), 'ID', TRUE, NOW(), NOW()),
('employee', 'employee@example.com', 'John Doe', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'employee', 'EMP001', 'JD001', 'A', NOW(), 'ID', TRUE, NOW(), NOW())
ON CONFLICT (username) DO NOTHING;