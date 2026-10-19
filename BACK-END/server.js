// ============================================================================
// Ray of Hope Center for Autism ERP — Production Node.js API Gateway
// Express.js + MySQL2 Pool | OWASP Top 10 & FRS v1.0 Compliant
// ============================================================================

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./swagger_spec.json');

// Refuse to start without real secrets — never fall back to hardcoded credentials
for (const key of ['JWT_SECRET', 'DB_PASSWORD']) {
  if (!process.env[key]) {
    console.error(`❌ ${key} is not set in .env — refusing to start.`);
    process.exit(1);
  }
}

const app = express();
const PORT = process.env.PORT || 8000;
const JWT_SECRET = process.env.JWT_SECRET;

// // ── Security Headers & Middlewares ──
app.use(cors({
  origin: process.env.ALLOWED_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request Logger Middleware
app.use((req, res, next) => {
  const action = req.query.action || req.body?.action || '';
  console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.path}${action ? ' ?action=' + action : ''}`);
  next();
});

// ── Mount Swagger UI Documentation ──
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Defense-in-depth security headers
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  next();
});

// ── MySQL Connection Pool ──
const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'roh_erp',
  waitForConnections: true,
  connectionLimit: 20,
  queueLimit: 0,
  dateStrings: true,
});

// Connect and create any missing tables from schema.sql (CREATE TABLE IF NOT EXISTS — never drops data).
// Uses a dedicated connection so multipleStatements stays off for the request pool.
(async () => {
  let conn;
  try {
    conn = await mysql.createConnection({
      host: process.env.DB_HOST || '127.0.0.1',
      port: parseInt(process.env.DB_PORT || '3306'),
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME || 'roh_erp',
      multipleStatements: true,
    });
    console.log(`✅ Connected to MySQL Database (${process.env.DB_NAME || 'roh_erp'}) on ${process.env.DB_HOST || '127.0.0.1'}`);
    const [before] = await conn.query('SHOW TABLES');
    await conn.query(require('fs').readFileSync(require('path').join(__dirname, 'schema.sql'), 'utf8'));
    const [after] = await conn.query('SHOW TABLES');
    console.log(`📦 Schema check: ${after.length - before.length} table(s) created, ${after.length} total`);
  } catch (err) {
    console.error('❌ MySQL connection / schema setup error:', err.message);
  } finally {
    if (conn) await conn.end().catch(() => {});
  }
})();

// ── Utility Helpers ──
async function auditLog(userId, role, action, targetEntity = null, targetId = null, ip = null, userAgent = null, details = null) {
  try {
    await pool.query(
      'INSERT INTO audit_logs (user_id, user_role, action, target_entity, target_id, ip_address, user_agent, details) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [userId, role, action, targetEntity, targetId, ip, userAgent, details]
    );
  } catch (err) {
    console.error('Audit log error:', err.message);
  }
}

async function createNotification(recipientUserId, eventType, title, message, metadata = null) {
  try {
    const metaJson = metadata ? JSON.stringify(metadata) : null;
    const [res] = await pool.query(
      'INSERT INTO notifications (recipient_user_id, event_type, title, message, is_read, metadata_json) VALUES (?, ?, ?, ?, 0, ?)',
      [recipientUserId, eventType, title, message, metaJson]
    );
    console.log(`🔔 Created notification #${res.insertId} for User #${recipientUserId}: "${title}"`);
  } catch (err) {
    console.error('Create notification error:', err.message);
  }
}

function generateToken(user) {
  return jwt.sign(
    {
      sub: user.id,
      role: user.role,
      name: user.name,
      email: user.email,
      token_version: user.token_version || 1,
    },
    JWT_SECRET,
    { expiresIn: '30d' }
  );
}

async function verifyAuth(req) {
  const authHeader = req.headers['authorization'] || '';
  const match = authHeader.match(/Bearer\s+(\S+)/);
  if (!match) return null;

  try {
    const token = match[1];

    const decoded = jwt.verify(token, JWT_SECRET);
    if (!decoded || !decoded.sub) return null;

    // Check token version against database for session revocation
    const [rows] = await pool.query(
      'SELECT token_version, status FROM users WHERE id = ? LIMIT 1',
      [decoded.sub]
    );
    if (!rows.length || rows[0].status !== 'Active') return null;
    if (parseInt(rows[0].token_version) !== parseInt(decoded.token_version)) return null;

    return decoded;
  } catch (err) {
    return null;
  }
}

// Student IDs the caller may read: null = unrestricted (admin/director),
// therapist = assigned caseload, parent = their own children.
async function accessibleStudentIds(auth) {
  if (['admin', 'director'].includes(auth.role)) return null;
  if (auth.role === 'therapist') {
    const [rows] = await pool.query(
      `SELECT id FROM students WHERE primary_therapist_id = ?
       UNION SELECT student_id FROM student_therapists WHERE therapist_id = ? AND is_active = 1`,
      [auth.sub, auth.sub]
    );
    return rows.map(r => r.id);
  }
  if (auth.role === 'parent') {
    const [rows] = await pool.query('SELECT id FROM students WHERE parent_user_id = ?', [auth.sub]);
    return rows.map(r => r.id);
  }
  return [];
}

// SQL condition restricting `column` to a scope returned by accessibleStudentIds()
function studentScopeSql(column, scope) {
  if (scope === null) return { sql: '1=1', params: [] };
  if (!scope.length) return { sql: '1=0', params: [] };
  return { sql: `${column} IN (?)`, params: [scope] };
}

async function canAccessStudent(auth, studentId) {
  const scope = await accessibleStudentIds(auth);
  return scope === null || scope.includes(studentId);
}

// Validates input.student_id for a clinical write. Sends the 400/403 and returns null when
// the id is missing or outside the caller's caseload; otherwise returns the numeric id.
async function writableStudentId(auth, input, res) {
  const studentId = parseInt(input.student_id, 10);
  if (!studentId) {
    res.status(400).json({ error: 'student_id is required' });
    return null;
  }
  if (!(await canAccessStudent(auth, studentId))) {
    res.status(403).json({ error: 'Forbidden: student is outside your caseload' });
    return null;
  }
  return studentId;
}

// One record per student + test number: updates the newest existing row (older duplicates
// from before upserts are left alone) or inserts a new one. Returns { id, updated }.
async function upsertTestRecord(table, studentId, testNumber, fields) {
  const [existing] = await pool.query(
    `SELECT id FROM ${table} WHERE student_id = ? AND test_number = ? ORDER BY id DESC LIMIT 1`,
    [studentId, testNumber]
  );
  const columns = Object.keys(fields);
  const values = columns.map(c => fields[c]);
  if (existing.length) {
    await pool.query(
      `UPDATE ${table} SET ${columns.map(c => `${c} = ?`).join(', ')} WHERE id = ?`,
      [...values, existing[0].id]
    );
    return { id: existing[0].id, updated: true };
  }
  const [result] = await pool.query(
    `INSERT INTO ${table} (student_id, test_number, ${columns.join(', ')}) VALUES (?, ?, ${columns.map(() => '?').join(', ')})`,
    [studentId, testNumber, ...values]
  );
  return { id: result.insertId, updated: false };
}

// JSON columns may arrive as an object or as an already-encoded string.
function jsonColumn(value) {
  if (value === undefined || value === null || value === '') return '{}';
  if (typeof value === 'string') {
    try { JSON.parse(value); return value; } catch (_) { return JSON.stringify(value); }
  }
  return JSON.stringify(value);
}

function requireAuth(allowedRoles = []) {
  return async (req, res, next) => {
    const user = await verifyAuth(req);
    if (!user) {
      return res.status(401).json({ error: 'Unauthorized: Invalid, expired, or revoked bearer token' });
    }
    if (allowedRoles.length > 0 && !allowedRoles.includes(user.role)) {
      return res.status(403).json({ error: 'Forbidden: Insufficient privileges for this clinical action' });
    }
    req.user = user;
    next();
  };
}

// ── Unified API Dispatcher (supports ?action=xxx for exact backwards compatibility with Flutter ApiService) ──
app.all(['/api.php', '/api', '/api/api.php', '/api/v1'], async (req, res) => {
  const action = req.query.action || req.body.action || '';
  const input = { ...req.query, ...req.body };
  const ip = req.ip || req.connection.remoteAddress || '127.0.0.1';
  const ua = req.headers['user-agent'] || 'Unknown';

  try {
    switch (action) {
      // ──────────────────────────────────────────────────────────────────────
      // 1. AUTHENTICATION & SESSION MANAGEMENT
      // ──────────────────────────────────────────────────────────────────────
      case 'login': {
        const email = (input.email || '').trim().toLowerCase();
        const password = (input.password || '').trim();

        if (!email || !password) {
          return res.status(400).json({ error: 'Email and password are required' });
        }

        const [users] = await pool.query(
          'SELECT id, name, email, password, role, status, must_change_password, failed_login_attempts, locked_until, token_version FROM users WHERE LOWER(email) = ? LIMIT 1',
          [email]
        );

        if (!users.length) {
          await auditLog(null, null, 'LOGIN_FAILED', 'users', null, ip, ua, `Unknown email: ${email}`);
          return res.status(401).json({ error: 'Invalid email or password' });
        }

        const user = users[0];

        // Check if locked
        if (user.locked_until && new Date(user.locked_until) > new Date()) {
          const waitMins = Math.ceil((new Date(user.locked_until) - new Date()) / 60000);
          await auditLog(user.id, user.role, 'LOGIN_LOCKED', 'users', user.id, ip, ua, `Locked attempt. ${waitMins}m remaining`);
          return res.status(403).json({ error: `Account locked due to consecutive failed logins. Try again in ${waitMins} minute(s) or contact Admin.` });
        }

        let passwordMatches = false;
        if (user.password.startsWith('$2') || user.password.startsWith('$argon2')) {
          passwordMatches = await bcrypt.compare(password, user.password);
        } else {
          // Plain text fallback from initial seeds: auto-upgrade to Bcrypt
          passwordMatches = (user.password === password);
          if (passwordMatches) {
            const newHash = await bcrypt.hash(password, 10);
            await pool.query('UPDATE users SET password = ? WHERE id = ?', [newHash, user.id]);
          }
        }

        if (passwordMatches) {
          if (user.status !== 'Active') {
            return res.status(403).json({ error: 'Account deactivated. Please contact center administration.' });
          }

          // Reset failed attempts & update last login
          await pool.query(
            'UPDATE users SET failed_login_attempts = 0, locked_until = NULL, last_login_at = NOW() WHERE id = ?',
            [user.id]
          );

          const token = generateToken(user);
          await auditLog(user.id, user.role, 'LOGIN', 'users', user.id, ip, ua, 'Successful login');

          delete user.password;
          user.token = token;
          user.must_change_password = Boolean(user.must_change_password);
          return res.json(user);
        } else {
          const attempts = (user.failed_login_attempts || 0) + 1;
          if (attempts >= 5) {
            const lockUntil = new Date(Date.now() + 15 * 60000);
            await pool.query('UPDATE users SET failed_login_attempts = ?, locked_until = ? WHERE id = ?', [attempts, lockUntil, user.id]);
            await createNotification(1, 'ACCOUNT_LOCKED', 'Security Alert: Account Locked', `User ${user.email} locked after 5 failed attempts.`);
            await auditLog(user.id, user.role, 'ACCOUNT_LOCKED', 'users', user.id, ip, ua, `Locked after ${attempts} attempts`);
            return res.status(403).json({ error: 'Account locked after 5 consecutive failed login attempts. Please wait 15 minutes or contact Admin.' });
          } else {
            await pool.query('UPDATE users SET failed_login_attempts = ? WHERE id = ?', [attempts, user.id]);
            const remaining = 5 - attempts;
            await auditLog(user.id, user.role, 'LOGIN_FAILED', 'users', user.id, ip, ua, `Failed attempt (${attempts}/5)`);
            return res.status(401).json({ error: `Invalid email or password. ${remaining} attempt(s) remaining before account lockout.` });
          }
        }
      }

      case 'change_password': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized: Bearer token invalid or expired' });

        const currentPassword = (input.current_password || '').trim();
        const newPassword = (input.new_password || '').trim();

        if (!newPassword || newPassword.length < 8 || !/[A-Z]/.test(newPassword) || !/[a-z]/.test(newPassword) || !/[0-9]/.test(newPassword)) {
          return res.status(400).json({ error: 'Password must be at least 8 characters long and contain uppercase, lowercase, and a number.' });
        }

        const [users] = await pool.query('SELECT password FROM users WHERE id = ? LIMIT 1', [auth.sub]);
        if (!users.length) return res.status(404).json({ error: 'User not found' });

        const isMatch = await bcrypt.compare(currentPassword, users[0].password) || (users[0].password === currentPassword);
        if (!isMatch) return res.status(400).json({ error: 'Current password does not match.' });

        const newHash = await bcrypt.hash(newPassword, 10);
        await pool.query('UPDATE users SET password = ?, must_change_password = 0, token_version = token_version + 1 WHERE id = ?', [newHash, auth.sub]);
        await auditLog(auth.sub, auth.role, 'CHANGE_PASSWORD', 'users', auth.sub, ip, ua, 'Self-service password update');
        await createNotification(auth.sub, 'PASSWORD_CHANGED', 'Password Updated', 'Your password was updated successfully.');

        // Old tokens are revoked by the version bump; hand this device a fresh one.
        const [fresh] = await pool.query('SELECT id, role, name, email, token_version FROM users WHERE id = ? LIMIT 1', [auth.sub]);
        return res.json({ success: true, message: 'Password changed successfully', token: generateToken(fresh[0]) });
      }

      case 'initiate_password_reset': {
        const auth = await verifyAuth(req);
        if (!auth || auth.role !== 'admin') return res.status(403).json({ error: 'Forbidden: Admin access required' });

        const targetUserId = parseInt(input.user_id || 0);
        const reason = (input.reason || 'User requested assistance').trim();

        const [targets] = await pool.query('SELECT id, name, email, role FROM users WHERE id = ? LIMIT 1', [targetUserId]);
        if (!targets.length) return res.status(404).json({ error: 'Target user account not found' });

        const expiresAt = new Date(Date.now() + 48 * 3600000); // 48 hrs
        const [result] = await pool.query(
          'INSERT INTO password_reset_requests (user_id, requested_by_admin_id, decision, requester_ip, requester_user_agent, expires_at, rejection_reason) VALUES (?, ?, "Pending", ?, ?, ?, ?)',
          [targetUserId, auth.sub, ip, ua.substring(0, 255), expiresAt, reason]
        );

        const reqId = result.insertId;
        await auditLog(auth.sub, 'admin', 'INITIATE_PASSWORD_RESET', 'password_reset_requests', reqId, ip, ua, `Reset requested for ${targets[0].email}`);
        await createNotification(2, 'PASSWORD_RESET_REQUESTED', 'Password Reset Approval Required', `Admin requested reset for ${targets[0].name} (${targets[0].email}).`, { request_id: reqId });

        return res.json({ success: true, request_id: reqId, message: 'Reset request forwarded to Clinical Director for approval' });
      }

      case 'list_pending_password_resets': {
        const auth = await verifyAuth(req);
        if (!auth || !['director', 'admin'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const [rows] = await pool.query(
          `SELECT pr.*, u.name as user_name, u.email as user_email, u.role as user_role, adm.name as admin_name 
           FROM password_reset_requests pr 
           JOIN users u ON pr.user_id = u.id 
           JOIN users adm ON pr.requested_by_admin_id = adm.id 
           ORDER BY pr.id DESC LIMIT 50`
        );
        return res.json(rows);
      }

      case 'decide_password_reset': {
        const auth = await verifyAuth(req);
        if (!auth || auth.role !== 'director') return res.status(403).json({ error: 'Forbidden: Director authorization required' });

        const reqId = parseInt(input.request_id || 0);
        const decision = input.decision === 'Approved' ? 'Approved' : 'Rejected';
        const reason = (input.reason || '').trim();

        const [rows] = await pool.query('SELECT pr.*, u.name, u.email FROM password_reset_requests pr JOIN users u ON pr.user_id = u.id WHERE pr.id = ? LIMIT 1', [reqId]);
        if (!rows.length) return res.status(404).json({ error: 'Reset request not found' });
        const reqItem = rows[0];

        if (decision === 'Approved') {
          const tempPass = 'Roh@' + crypto.randomBytes(3).toString('hex');
          const hash = await bcrypt.hash(tempPass, 10);

          await pool.query(
            'UPDATE password_reset_requests SET decision = "Approved", director_id = ?, decision_timestamp = NOW(), completed_timestamp = NOW(), temp_password_hash = ? WHERE id = ?',
            [auth.sub, hash, reqId]
          );

          await pool.query(
            'UPDATE users SET password = ?, must_change_password = 1, failed_login_attempts = 0, locked_until = NULL, token_version = token_version + 1 WHERE id = ?',
            [hash, reqItem.user_id]
          );

          await auditLog(auth.sub, 'director', 'APPROVE_PASSWORD_RESET', 'password_reset_requests', reqId, ip, ua, `Approved reset for ${reqItem.email}`);
          await createNotification(reqItem.requested_by_admin_id, 'RESET_APPROVED', 'Password Reset Approved', `Director approved reset for ${reqItem.email}.`);
          await createNotification(reqItem.user_id, 'PASSWORD_RESET_COMPLETED', 'Password Reset Completed', 'Your password was reset by administration.');

          return res.json({ success: true, temporary_password: tempPass, message: 'Reset approved and temporary password generated' });
        } else {
          await pool.query(
            'UPDATE password_reset_requests SET decision = "Rejected", director_id = ?, decision_timestamp = NOW(), rejection_reason = ? WHERE id = ?',
            [auth.sub, reason || 'Rejected by Clinical Director', reqId]
          );

          await auditLog(auth.sub, 'director', 'REJECT_PASSWORD_RESET', 'password_reset_requests', reqId, ip, ua, `Rejected reset for ${reqItem.email}`);
          await createNotification(reqItem.requested_by_admin_id, 'RESET_REJECTED', 'Password Reset Rejected', `Director rejected reset request for ${reqItem.email}.`);

          return res.json({ success: true, message: 'Password reset request rejected' });
        }
      }

      case 'logout_all_devices': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const targetUserId = (auth.role === 'admin' || auth.role === 'director') ? parseInt(input.user_id || auth.sub) : auth.sub;

        await pool.query('UPDATE users SET token_version = token_version + 1 WHERE id = ?', [targetUserId]);
        await auditLog(auth.sub, auth.role, 'LOGOUT_ALL_DEVICES', 'users', targetUserId, ip, ua, 'Revoked all active tokens');
        return res.json({ success: true, message: 'All active sessions invalidated' });
      }

      // ──────────────────────────────────────────────────────────────────────
      // 2. THERAPISTS & STAFF MANAGEMENT
      // ──────────────────────────────────────────────────────────────────────
      case 'get_therapists': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });

        // Staff see the full roster; a parent only sees their own child's therapists
        let where = '1=1';
        const params = [];
        if (auth.role === 'parent') {
          const scope = studentScopeSql('s.id', await accessibleStudentIds(auth));
          where = `u.id IN (
            SELECT s.primary_therapist_id FROM students s WHERE ${scope.sql} AND s.primary_therapist_id IS NOT NULL
            UNION SELECT st.therapist_id FROM student_therapists st JOIN students s ON st.student_id = s.id
            WHERE st.is_active = 1 AND ${scope.sql})`;
          params.push(...scope.params, ...scope.params);
        } else if (!['admin', 'director', 'therapist'].includes(auth.role)) {
          return res.status(403).json({ error: 'Forbidden' });
        }

        const [rows] = await pool.query(
          `SELECT u.id, u.name, u.email, u.status, u.phone, tp.designation, tp.license_number, tp.active_caseload
           FROM users u
           LEFT JOIN therapist_profiles tp ON u.id = tp.user_id
           WHERE u.role = 'therapist' AND ${where} ORDER BY u.id DESC`,
          params
        );
        return res.json(rows);
      }

      case 'add_therapist': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const name = (input.name || '').trim();
        const email = (input.email || '').trim().toLowerCase();
        const password = input.password || 'therapist123';

        if (!name || !email) return res.status(400).json({ error: 'Valid name and email are required' });

        const hash = await bcrypt.hash(password, 10);
        const [resUser] = await pool.query(
          'INSERT INTO users (name, email, password, role, status) VALUES (?, ?, ?, "therapist", "Active")',
          [name, email, hash]
        );
        const newId = resUser.insertId;

        await pool.query(
          'INSERT INTO therapist_profiles (user_id, designation) VALUES (?, ?)',
          [newId, input.designation || 'Behavior Therapist']
        );

        await auditLog(auth.sub, auth.role, 'ADD_THERAPIST', 'users', newId, ip, ua, `Added therapist: ${name}`);
        return res.json({ success: true, id: newId });
      }

      case 'update_therapist': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const userId = parseInt(input.id || input.user_id || 0);
        if (!userId) return res.status(400).json({ error: 'Therapist ID required' });

        const name = input.name ? input.name.trim() : null;
        const email = input.email ? input.email.trim().toLowerCase() : null;
        const phone = input.phone || null;

        if (name || email || phone !== undefined) {
          await pool.query(
            'UPDATE users SET name = COALESCE(?, name), email = COALESCE(?, email), phone = COALESCE(?, phone) WHERE id = ? AND role = "therapist"',
            [name, email, phone, userId]
          );
        }

        if (input.designation || input.license_number || input.qualification || input.specialties || input.about) {
          await pool.query(
            `INSERT INTO therapist_profiles (user_id, designation, license_number, qualification, specialties, about)
             VALUES (?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
               designation = COALESCE(VALUES(designation), designation),
               license_number = COALESCE(VALUES(license_number), license_number),
               qualification = COALESCE(VALUES(qualification), qualification),
               specialties = COALESCE(VALUES(specialties), specialties),
               about = COALESCE(VALUES(about), about)`,
            [userId, input.designation || null, input.license_number || null, input.qualification || null, input.specialties || null, input.about || null]
          );
        }

        await auditLog(auth.sub, auth.role, 'UPDATE_THERAPIST', 'users', userId, ip, ua, `Updated therapist ${userId}`);
        return res.json({ success: true, id: userId });
      }

      case 'toggle_therapist_status': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const userId = parseInt(input.user_id || input.id || 0);
        if (!userId) return res.status(400).json({ error: 'Therapist ID required' });

        let newStatus = input.status;
        if (!newStatus) {
          const [curr] = await pool.query('SELECT status FROM users WHERE id = ? AND role = "therapist"', [userId]);
          if (!curr.length) return res.status(404).json({ error: 'Therapist not found' });
          newStatus = curr[0].status === 'Active' ? 'De-Activated' : 'Active';
        }

        await pool.query('UPDATE users SET status = ? WHERE id = ? AND role = "therapist"', [newStatus, userId]);
        await auditLog(auth.sub, auth.role, 'TOGGLE_THERAPIST_STATUS', 'users', userId, ip, ua, `Set therapist ${userId} status to ${newStatus}`);
        return res.json({ success: true, id: userId, status: newStatus });
      }

      case 'get_parents': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });

        // Admin/director see all parents; a therapist sees their caseload's parents; a parent sees only themselves
        let where = '1=1';
        const params = [];
        if (auth.role === 'parent') {
          where = 'u.id = ?';
          params.push(auth.sub);
        } else if (auth.role === 'therapist') {
          const scope = studentScopeSql('s.id', await accessibleStudentIds(auth));
          where = `u.id IN (SELECT s.parent_user_id FROM students s WHERE ${scope.sql})`;
          params.push(...scope.params);
        } else if (!['admin', 'director'].includes(auth.role)) {
          return res.status(403).json({ error: 'Forbidden' });
        }

        const [rows] = await pool.query(
          `SELECT u.id, u.name, u.email, u.status, u.phone, pp.secondary_phone, pp.street_address,
                  (SELECT CONCAT(s.first_name, ' ', s.last_name) FROM students s WHERE s.parent_user_id = u.id LIMIT 1) AS child_name
           FROM users u
           LEFT JOIN parent_profiles pp ON u.id = pp.user_id
           WHERE u.role = 'parent' AND ${where} ORDER BY u.id DESC`,
          params
        );
        return res.json(rows);
      }

      case 'add_parent': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const name = (input.name || '').trim();
        const email = (input.email || '').trim().toLowerCase();
        const password = input.password || 'parent123';

        if (!name || !email) return res.status(400).json({ error: 'Valid name and email are required' });

        const hash = await bcrypt.hash(password, 10);
        const [resUser] = await pool.query(
          'INSERT INTO users (name, email, password, role, status, phone) VALUES (?, ?, ?, "parent", "Active", ?)',
          [name, email, hash, input.phone || null]
        );
        const newId = resUser.insertId;

        await pool.query(
          'INSERT INTO parent_profiles (user_id, secondary_phone) VALUES (?, ?)',
          [newId, input.phone || null]
        );

        await auditLog(auth.sub, auth.role, 'ADD_PARENT', 'users', newId, ip, ua, `Added parent: ${name}`);
        return res.json({ success: true, id: newId });
      }

      case 'update_parent': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const userId = parseInt(input.id || input.user_id || 0);
        if (!userId) return res.status(400).json({ error: 'Parent ID required' });

        const name = input.name ? input.name.trim() : null;
        const email = input.email ? input.email.trim().toLowerCase() : null;
        const phone = input.phone || null;

        if (name || email || phone !== undefined) {
          await pool.query(
            'UPDATE users SET name = COALESCE(?, name), email = COALESCE(?, email), phone = COALESCE(?, phone) WHERE id = ? AND role = "parent"',
            [name, email, phone, userId]
          );
        }

        if (input.secondary_phone || input.street_address || input.city || input.state || input.postal_code || input.occupation || input.preferred_communication) {
          await pool.query(
            `INSERT INTO parent_profiles (user_id, secondary_phone, street_address, city, state, postal_code, occupation, preferred_communication)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
               secondary_phone = COALESCE(VALUES(secondary_phone), secondary_phone),
               street_address = COALESCE(VALUES(street_address), street_address),
               city = COALESCE(VALUES(city), city),
               state = COALESCE(VALUES(state), state),
               postal_code = COALESCE(VALUES(postal_code), postal_code),
               occupation = COALESCE(VALUES(occupation), occupation),
               preferred_communication = COALESCE(VALUES(preferred_communication), preferred_communication)`,
            [
              userId,
              input.secondary_phone || phone || null,
              input.street_address || null,
              input.city || null,
              input.state || null,
              input.postal_code || null,
              input.occupation || null,
              input.preferred_communication || 'Phone'
            ]
          );
        }

        await auditLog(auth.sub, auth.role, 'UPDATE_PARENT', 'users', userId, ip, ua, `Updated parent ${userId}`);
        return res.json({ success: true, id: userId });
      }

      case 'toggle_parent_status': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const userId = parseInt(input.user_id || input.id || 0);
        if (!userId) return res.status(400).json({ error: 'Parent ID required' });

        let newStatus = input.status;
        if (!newStatus) {
          const [curr] = await pool.query('SELECT status FROM users WHERE id = ? AND role = "parent"', [userId]);
          if (!curr.length) return res.status(404).json({ error: 'Parent not found' });
          newStatus = curr[0].status === 'Active' ? 'De-Activated' : 'Active';
        }

        await pool.query('UPDATE users SET status = ? WHERE id = ? AND role = "parent"', [newStatus, userId]);
        await auditLog(auth.sub, auth.role, 'TOGGLE_PARENT_STATUS', 'users', userId, ip, ua, `Set parent ${userId} status to ${newStatus}`);
        return res.json({ success: true, id: userId, status: newStatus });
      }

      // ──────────────────────────────────────────────────────────────────────
      // 3. STUDENTS & CLINICAL ADMISSIONS
      // ──────────────────────────────────────────────────────────────────────
      case 'get_students':
      case 'get_students_full': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const scope = studentScopeSql('s.id', await accessibleStudentIds(auth));

        const [rows] = await pool.query(
          `SELECT s.*, CONCAT(s.first_name, ' ', s.last_name) AS name, u.name AS therapist_name
           FROM students s
           LEFT JOIN users u ON s.primary_therapist_id = u.id
           WHERE ${scope.sql}
           ORDER BY s.id DESC`,
          scope.params
        );
        return res.json(rows);
      }

      case 'add_student': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const name = (input.name || '').trim();
        const parts = name.split(' ');
        const firstName = input.first_name || parts[0] || 'Student';
        const lastName = input.last_name || parts.slice(1).join(' ') || '';
        const middleName = input.middle_name || null;
        const gender = input.gender || 'Male';
        const bloodGroup = input.blood_group || 'O+';
        const program = input.program || 'Comprehensive ABA Early Intervention';
        const primaryDiagnosis = input.primary_diagnoses || input.primary_diagnosis || 'Autism Spectrum Disorder (Level 2)';
        const dob = input.dob ? new Date(input.dob).toISOString().split('T')[0] : '2019-01-01';

        const [result] = await pool.query(
          'INSERT INTO students (first_name, last_name, middle_name, dob, gender, blood_group, program, primary_diagnosis, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, "Active")',
          [firstName, lastName, middleName, dob, gender, bloodGroup, program, primaryDiagnosis]
        );

        const newId = result.insertId;
        const fullName = `${firstName} ${lastName}`.trim();
        await auditLog(auth.sub, auth.role, 'ADD_STUDENT', 'students', newId, ip, ua, `Enrolled student: ${fullName}`);
        return res.json({ success: true, id: newId });
      }

      case 'update_student': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const studentId = parseInt(input.id || 0);
        if (!studentId) return res.status(400).json({ error: 'Student ID required' });

        const name = (input.name || '').trim();
        const parts = name.split(' ');
        const firstName = parts[0] || input.first_name || 'Student';
        const lastName = parts.slice(1).join(' ') || input.last_name || '';
        const status = input.status || 'Active';
        const program = input.program || 'Comprehensive ABA Early Intervention';

        await pool.query(
          'UPDATE students SET first_name = ?, last_name = ?, status = ?, program = ? WHERE id = ?',
          [firstName, lastName, status, program, studentId]
        );
        await auditLog(auth.sub, auth.role, 'UPDATE_STUDENT', 'students', studentId, ip, ua, `Updated student ID ${studentId}: ${name}`);
        return res.json({ success: true, id: studentId });
      }

      case 'delete_student': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const studentId = parseInt(input.id || 0);
        await pool.query('DELETE FROM students WHERE id = ?', [studentId]);
        await auditLog(auth.sub, auth.role, 'DELETE_STUDENT', 'students', studentId, ip, ua, `Deleted student ID ${studentId}`);
        return res.json({ success: true });
      }

      case 'assign_student_therapist': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const studentId = parseInt(input.student_id || 0);
        const therapistId = parseInt(input.therapist_id || 0);
        const roleTitle = input.role_title || 'Primary BCBA';

        if (!studentId || !therapistId) return res.status(400).json({ error: 'student_id and therapist_id required' });

        // Update student's primary therapist if applicable
        await pool.query('UPDATE students SET primary_therapist_id = ? WHERE id = ?', [therapistId, studentId]);

        // Record in student_therapists
        await pool.query(
          'INSERT INTO student_therapists (student_id, therapist_id, role_title, is_active) VALUES (?, ?, ?, 1)',
          [studentId, therapistId, roleTitle]
        );

        await auditLog(auth.sub, auth.role, 'ASSIGN_THERAPIST', 'students', studentId, ip, ua, `Assigned therapist ${therapistId} to student ${studentId}`);
        await createNotification(therapistId, 'Case Assignment', `You have been assigned to student #${studentId}`, 'clinical', '/therapist');
        return res.json({ success: true, student_id: studentId, therapist_id: therapistId });
      }

      case 'get_student_therapists': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });

        const studentId = parseInt(input.student_id || req.query.student_id || 0);
        if (!studentId) return res.status(400).json({ error: 'student_id required' });
        if (!(await canAccessStudent(auth, studentId))) return res.status(403).json({ error: 'Forbidden' });

        const [rows] = await pool.query(
          `SELECT st.*, u.name as therapist_name, u.email as therapist_email, u.phone as therapist_phone, tp.designation 
           FROM student_therapists st 
           JOIN users u ON st.therapist_id = u.id 
           LEFT JOIN therapist_profiles tp ON u.id = tp.user_id 
           WHERE st.student_id = ? AND st.is_active = 1
           ORDER BY st.id DESC`,
          [studentId]
        );
        return res.json(rows);
      }

      case 'get_student_medical_info': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });

        const studentId = parseInt(input.student_id || req.query.student_id || 0);
        if (!studentId) return res.status(400).json({ error: 'student_id required' });
        if (!(await canAccessStudent(auth, studentId))) return res.status(403).json({ error: 'Forbidden' });

        const [rows] = await pool.query('SELECT * FROM medical_histories WHERE student_id = ? LIMIT 1', [studentId]);
        return res.json(rows[0] || null);
      }

      case 'save_student_medical_info': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director', 'therapist'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const studentId = parseInt(input.student_id || 0);
        if (!studentId) return res.status(400).json({ error: 'student_id required' });

        await pool.query(
          `INSERT INTO medical_histories (
             student_id, has_hospital_admissions, hospital_admission_details,
             has_diagnosed_conditions, diagnosed_condition_details,
             has_infectious_diseases, infectious_disease_details,
             has_allergies, allergy_details,
             eating_habits, sleeping_habits,
             has_seizures, seizure_protocol,
             pediatrician_name, pediatrician_phone
           ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
           ON DUPLICATE KEY UPDATE
             has_hospital_admissions = VALUES(has_hospital_admissions),
             hospital_admission_details = VALUES(hospital_admission_details),
             has_diagnosed_conditions = VALUES(has_diagnosed_conditions),
             diagnosed_condition_details = VALUES(diagnosed_condition_details),
             has_infectious_diseases = VALUES(has_infectious_diseases),
             infectious_disease_details = VALUES(infectious_disease_details),
             has_allergies = VALUES(has_allergies),
             allergy_details = VALUES(allergy_details),
             eating_habits = VALUES(eating_habits),
             sleeping_habits = VALUES(sleeping_habits),
             has_seizures = VALUES(has_seizures),
             seizure_protocol = VALUES(seizure_protocol),
             pediatrician_name = VALUES(pediatrician_name),
             pediatrician_phone = VALUES(pediatrician_phone)`,
          [
            studentId,
            input.has_hospital_admissions ? 1 : 0,
            input.hospital_admission_details || null,
            input.has_diagnosed_conditions ? 1 : 0,
            input.diagnosed_condition_details || null,
            input.has_infectious_diseases ? 1 : 0,
            input.infectious_disease_details || null,
            input.has_allergies ? 1 : 0,
            input.allergy_details || null,
            input.eating_habits || null,
            input.sleeping_habits || null,
            input.has_seizures ? 1 : 0,
            input.seizure_protocol || null,
            input.pediatrician_name || null,
            input.pediatrician_phone || null,
          ]
        );

        await auditLog(auth.sub, auth.role, 'SAVE_MEDICAL_INFO', 'medical_histories', studentId, ip, ua, `Saved medical info for student ${studentId}`);
        return res.json({ success: true, student_id: studentId });
      }

      case 'get_student_medications': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });

        const studentId = parseInt(input.student_id || req.query.student_id || 0);
        if (!studentId) return res.status(400).json({ error: 'student_id required' });
        if (!(await canAccessStudent(auth, studentId))) return res.status(403).json({ error: 'Forbidden' });

        const [rows] = await pool.query('SELECT * FROM medications WHERE student_id = ? ORDER BY id DESC', [studentId]);
        return res.json(rows);
      }

      case 'add_student_medication': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director', 'therapist'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const studentId = parseInt(input.student_id || 0);
        const medicationName = (input.medication_name || '').trim();
        if (!studentId || !medicationName) return res.status(400).json({ error: 'student_id and medication_name required' });

        const [result] = await pool.query(
          `INSERT INTO medications (student_id, medication_name, dosage, date_prescribed, administration_timeline, used_for, prescribing_doctor, is_administered_at_center)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            studentId,
            medicationName,
            input.dosage || '1 dose',
            input.date_prescribed || new Date().toISOString().split('T')[0],
            input.administration_timeline || 'Daily',
            input.used_for || '',
            input.prescribing_doctor || null,
            input.is_administered_at_center ? 1 : 0,
          ]
        );

        await auditLog(auth.sub, auth.role, 'ADD_MEDICATION', 'medications', result.insertId, ip, ua, `Added medication ${medicationName} for student ${studentId}`);
        return res.json({ success: true, id: result.insertId });
      }

      case 'delete_student_medication': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director', 'therapist'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const medId = parseInt(input.id || req.query.id || 0);
        await pool.query('DELETE FROM medications WHERE id = ?', [medId]);
        return res.json({ success: true, id: medId });
      }

      case 'get_student_guardians': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });

        const studentId = parseInt(input.student_id || req.query.student_id || 0);
        if (!studentId) return res.status(400).json({ error: 'student_id required' });
        if (!(await canAccessStudent(auth, studentId))) return res.status(403).json({ error: 'Forbidden' });

        const [rows] = await pool.query('SELECT * FROM guardians WHERE student_id = ? ORDER BY guardian_priority ASC, id ASC', [studentId]);
        return res.json(rows);
      }

      case 'add_student_guardian': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const studentId = parseInt(input.student_id || 0);
        const relationship = (input.relationship || 'Guardian').trim();
        const firstName = (input.first_name || input.name || 'Guardian').trim();
        const lastName = (input.last_name || '').trim();

        const [result] = await pool.query(
          `INSERT INTO guardians (student_id, guardian_priority, relationship, first_name, last_name, phone, email, street_address, city, state, postal_code, is_emergency_contact, notes)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            studentId,
            input.guardian_priority || 1,
            relationship,
            firstName,
            lastName,
            input.phone || null,
            input.email || null,
            input.street_address || null,
            input.city || null,
            input.state || null,
            input.postal_code || null,
            input.is_emergency_contact ? 1 : 1,
            input.notes || input.about || null,
          ]
        );

        await auditLog(auth.sub, auth.role, 'ADD_GUARDIAN', 'guardians', result.insertId, ip, ua, `Added guardian ${firstName} for student ${studentId}`);
        return res.json({ success: true, id: result.insertId });
      }

      case 'delete_student_guardian': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const guardianId = parseInt(input.id || req.query.id || 0);
        await pool.query('DELETE FROM guardians WHERE id = ?', [guardianId]);
        return res.json({ success: true, id: guardianId });
      }

      case 'get_student_emergency_contacts': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });

        const studentId = parseInt(input.student_id || req.query.student_id || 0);
        if (!studentId) return res.status(400).json({ error: 'student_id required' });
        if (!(await canAccessStudent(auth, studentId))) return res.status(403).json({ error: 'Forbidden' });

        const [rows] = await pool.query('SELECT * FROM guardians WHERE student_id = ? AND is_emergency_contact = 1 ORDER BY guardian_priority ASC', [studentId]);
        return res.json(rows);
      }

      case 'save_student_emergency_contact': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const studentId = parseInt(input.student_id || 0);
        const contactName = (input.contact_name || 'Emergency Contact').trim();
        const message = input.message || '';

        const [result] = await pool.query(
          `INSERT INTO guardians (student_id, guardian_priority, relationship, first_name, last_name, is_emergency_contact, notes)
           VALUES (?, 1, 'Emergency Contact', ?, '', 1, ?)`,
          [studentId, contactName, message]
        );

        return res.json({ success: true, id: result.insertId });
      }

      // ──────────────────────────────────────────────────────────────────────
      // 4. IEP REPORTS & CLINICAL GOVERNANCE
      // ──────────────────────────────────────────────────────────────────────
      case 'get_iep_reports': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const scope = studentScopeSql('i.student_id', await accessibleStudentIds(auth));

        const [rows] = await pool.query(
          `SELECT i.*, CONCAT(s.first_name, ' ', s.last_name) AS student_name, s.dob AS student_dob, u.name AS therapist_name, du.name AS director_signer_name
           FROM iep_reports i
           LEFT JOIN students s ON i.student_id = s.id
           LEFT JOIN users u ON i.therapist_id = u.id
           LEFT JOIN users du ON i.director_signed_by = du.id
           WHERE ${scope.sql}
           ORDER BY i.id DESC`,
          scope.params
        );
        return res.json(rows);
      }

      case 'save_iep_report': {
        const auth = await verifyAuth(req);
        if (!auth || !['therapist', 'director', 'admin'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const studentId = await writableStudentId(auth, input, res);
        if (!studentId) return;

        const fields = {
          title: (input.title || 'IEP Treatment Plan').trim(),
          cycle_term: (input.cycle_term || 'Q3 2026 Treatment Plan').toString().trim().slice(0, 80),
          // Only a director/admin may set a non-pending state; therapists' plans need sign-off.
          status: auth.role === 'therapist' ? 'Pending Approval' : (input.status || 'Pending Approval'),
          manding_score: parseInt(input.manding_score || 0),
          tacting_score: parseInt(input.tacting_score || 0),
          listener_score: parseInt(input.listener_score || 0),
          echoic_score: parseInt(input.echoic_score || 0),
          lrffc_score: parseInt(input.lrffc_score || 0),
          goals_summary: input.goals_summary || '',
        };

        // With an id, edit that report instead of creating another one. A therapist can only
        // edit a plan that is not yet signed off (pending or returned for revision).
        const iepId = parseInt(input.id || 0);
        let previousStatus = null;
        if (iepId) {
          const [rows] = await pool.query('SELECT student_id, status FROM iep_reports WHERE id = ? LIMIT 1', [iepId]);
          if (!rows.length || rows[0].student_id !== studentId) return res.status(404).json({ error: 'IEP report not found for this student' });
          previousStatus = rows[0].status;
          if (auth.role === 'therapist' && !['Pending Approval', 'Returned for Revision'].includes(previousStatus)) {
            return res.status(409).json({ error: `This IEP is ${previousStatus}; save a new plan instead of editing it` });
          }
          await pool.query(
            `UPDATE iep_reports SET ${Object.keys(fields).map(c => `${c} = ?`).join(', ')} WHERE id = ?`,
            [...Object.values(fields), iepId]
          );
          await auditLog(auth.sub, auth.role, 'UPDATE_IEP', 'iep_reports', iepId, ip, ua, `Updated IEP: ${fields.title}`);
        } else {
          const [result] = await pool.query(
            `INSERT INTO iep_reports (student_id, therapist_id, ${Object.keys(fields).join(', ')})
             VALUES (?, ?, ${Object.keys(fields).map(() => '?').join(', ')})`,
            [studentId, auth.sub, ...Object.values(fields)]
          );
          await auditLog(auth.sub, auth.role, 'SAVE_IEP', 'iep_reports', result.insertId, ip, ua, `Created IEP: ${fields.title}`);
          input.id = result.insertId;
        }
        const savedId = parseInt(input.id);

        // Notify every active director when a plan newly needs sign-off (not on edits of a plan already pending).
        if (fields.status === 'Pending Approval' && previousStatus !== 'Pending Approval') {
          const [directors] = await pool.query("SELECT id FROM users WHERE role = 'director' AND status = 'Active'");
          for (const director of directors) {
            await createNotification(
              director.id,
              'IEP_SUBMITTED',
              'New IEP Pending Approval',
              `Therapist ${auth.name || 'Staff'} submitted an IEP (${fields.title}) requiring Director sign-off.`,
              { iep_id: savedId, student_id: studentId }
            );
          }
        }

        return res.json({ success: true, id: savedId, updated: Boolean(iepId) });
      }

      case 'sign_off_iep': {
        const auth = await verifyAuth(req);
        if (!auth || auth.role !== 'director') return res.status(403).json({ error: 'Forbidden: Director approval required' });

        const iepId = parseInt(input.iep_id || 0);
        const notes = input.director_notes || '';
        const [found] = await pool.query('SELECT id FROM iep_reports WHERE id = ? LIMIT 1', [iepId]);
        if (!found.length) return res.status(404).json({ error: 'IEP not found' });

        await pool.query(
          'UPDATE iep_reports SET status = "Active", director_notes = ?, director_signed_by = ?, director_signed_at = NOW() WHERE id = ?',
          [notes, auth.sub, iepId]
        );

        await auditLog(auth.sub, 'director', 'SIGN_OFF_IEP', 'iep_reports', iepId, ip, ua, 'Director signed off IEP');

        // Fetch student & parent details to dispatch notification
        const [iepRow] = await pool.query(
          'SELECT i.student_id, i.therapist_id, i.title, s.parent_user_id FROM iep_reports i LEFT JOIN students s ON s.id = i.student_id WHERE i.id = ? LIMIT 1',
          [iepId]
        );
        if (iepRow.length) {
          // Notify Therapist
          await createNotification(
            iepRow[0].therapist_id,
            'IEP_APPROVED',
            'IEP Plan Approved',
            `Director signed off and activated "${iepRow[0].title}".`,
            { iep_id: iepId }
          );
          // Notify the student's parent
          if (iepRow[0].parent_user_id) await createNotification(
            iepRow[0].parent_user_id,
            'REPORT_READY',
            'Child IEP Plan Published',
            `The new Individualized Education Plan "${iepRow[0].title}" has been signed off and is now active.`,
            { iep_id: iepId }
          );
        }

        return res.json({ success: true });
      }

      case 'update_iep_report': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director', 'therapist'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const iepId = parseInt(input.id || 0);
        const [existing] = await pool.query('SELECT student_id, title, goals_summary FROM iep_reports WHERE id = ? LIMIT 1', [iepId]);
        if (!existing.length) return res.status(404).json({ error: 'IEP not found' });
        if (!(await canAccessStudent(auth, existing[0].student_id))) return res.status(403).json({ error: 'Forbidden' });
        const title = (input.title || existing[0].title).toString();
        const goalsSummary = input.goals_summary ?? existing[0].goals_summary ?? '';
        await pool.query('UPDATE iep_reports SET title = ?, goals_summary = ? WHERE id = ?', [title, goalsSummary, iepId]);
        await auditLog(auth.sub, auth.role, 'UPDATE_IEP', 'iep_reports', iepId, ip, ua, `Updated IEP: ${title}`);
        return res.json({ success: true, id: iepId });
      }

      case 'request_iep_revision': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const iepId = parseInt(input.iep_id || input.id || 0);
        const notes = (input.director_notes || '').toString().trim();
        if (!notes) return res.status(400).json({ error: 'Revision notes are required' });
        const [rows] = await pool.query('SELECT therapist_id, title FROM iep_reports WHERE id = ? LIMIT 1', [iepId]);
        if (!rows.length) return res.status(404).json({ error: 'IEP not found' });
        await pool.query('UPDATE iep_reports SET status = "Returned for Revision", director_notes = ? WHERE id = ?', [notes, iepId]);
        await auditLog(auth.sub, auth.role, 'REQUEST_IEP_REVISION', 'iep_reports', iepId, ip, ua, 'Returned IEP for revision');
        await createNotification(rows[0].therapist_id, 'IEP_RETURNED', 'IEP Returned for Revision',
          `"${rows[0].title}" needs changes: ${notes}`, { iep_id: iepId });
        return res.json({ success: true });
      }

      case 'delete_iep_report': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const iepId = parseInt(input.id || 0);
        await pool.query('DELETE FROM iep_reports WHERE id = ?', [iepId]);
        await auditLog(auth.sub, auth.role, 'DELETE_IEP', 'iep_reports', iepId, ip, ua, `Deleted IEP ID ${iepId}`);
        return res.json({ success: true });
      }

      // ──────────────────────────────────────────────────────────────────────
      // 5. DAILY DATA SHEETS & DISCRETE TRIALS (OFFLINE READY)
      // ──────────────────────────────────────────────────────────────────────
      case 'get_daily_data': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const scope = studentScopeSql('d.student_id', await accessibleStudentIds(auth));

        const studentId = req.query.student_id;
        let query = `SELECT d.*, CONCAT(s.first_name, ' ', s.last_name) AS student_name, u.name AS therapist_name
           FROM daily_data_sheets d
           LEFT JOIN students s ON d.student_id = s.id
           LEFT JOIN users u ON d.therapist_id = u.id
           WHERE ${scope.sql} `;
        const params = [...scope.params];
        if (studentId) {
          query += ` AND d.student_id = ? `;
          params.push(studentId);
        }
        query += ` ORDER BY d.session_date ASC, d.id ASC`;
        const [rows] = await pool.query(query, params);
        return res.json(rows);
      }

      case 'save_daily_data':
      case 'save_daily_data_sheet': {
        const auth = await verifyAuth(req);
        if (!auth || !['therapist', 'director', 'admin'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const studentId = await writableStudentId(auth, input, res);
        if (!studentId) return;
        const therapistId = auth.sub;

        // Accepts either a single row (legacy) or `rows: [...]` sharing one session_date;
        // a multi-row sheet is written atomically.
        const sessionDate = input.session_date || new Date().toISOString().split('T')[0];
        const rows = Array.isArray(input.rows) ? input.rows : [input];
        if (!rows.length) return res.status(400).json({ error: 'No rows to save' });

        const conn = await pool.getConnection();
        const ids = [];
        try {
          await conn.beginTransaction();
          for (const row of rows) {
            const values = [
              row.session_date || sessionDate,
              row.domain || 'Manding',
              (row.target_skill || 'Vocal Request').toString().slice(0, 255),
              row.prompt_level || 'Independent',
              parseInt(row.trials_completed || 0),
              parseInt(row.trials_successful || 0),
              typeof row.notes === 'object' && row.notes !== null ? JSON.stringify(row.notes) : (row.notes || ''),
            ];
            const rowId = parseInt(row.id || 0);
            if (rowId) {
              // Edit of an existing row; it must belong to this student.
              const [result] = await conn.query(
                `UPDATE daily_data_sheets SET session_date = ?, domain = ?, target_skill = ?, prompt_level = ?,
                   trials_completed = ?, trials_successful = ?, notes = ?
                 WHERE id = ? AND student_id = ?`,
                [...values, rowId, studentId]
              );
              if (!result.affectedRows) throw Object.assign(new Error(`Row ${rowId} not found for this student`), { status: 404 });
              ids.push(rowId);
              continue;
            }
            const [result] = await conn.query(
              `INSERT INTO daily_data_sheets (student_id, therapist_id, session_date, domain, target_skill, prompt_level, trials_completed, trials_successful, notes) 
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
              [studentId, therapistId, ...values]
            );
            ids.push(result.insertId);
          }
          await conn.commit();
        } catch (err) {
          await conn.rollback();
          if (err.status === 404) return res.status(404).json({ error: err.message });
          throw err;
        } finally {
          conn.release();
        }
        await auditLog(auth.sub, auth.role, 'SAVE_DAILY_DATA', 'daily_data_sheets', ids[0], ip, ua, `Saved ${ids.length} row(s) for student ${studentId}`);

        return res.json({ success: true, id: ids[0], ids });
      }

      // ──────────────────────────────────────────────────────────────────────
      // 6. DEDICATED CLINICAL ASSESSMENTS (Milestones, Barriers, Transitions, EESA)
      // ──────────────────────────────────────────────────────────────────────

      // 6A. VB-MAPP MILESTONES
      case 'get_milestone_assessments': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const scope = studentScopeSql('m.student_id', await accessibleStudentIds(auth));

        const studentId = req.query.student_id ? parseInt(req.query.student_id) : null;
        let query = `SELECT m.*, CONCAT(s.first_name, ' ', s.last_name) AS student_name, s.dob AS student_dob, u.name AS therapist_name
                     FROM milestone_assessments m 
                     LEFT JOIN students s ON m.student_id = s.id
                     LEFT JOIN users u ON m.therapist_id = u.id
                     WHERE ${scope.sql}`;
        const params = [...scope.params];
        if (studentId) {
          query += ` AND m.student_id = ?`;
          params.push(studentId);
        }
        query += ` ORDER BY m.test_number ASC, m.assessment_date DESC`;
        const [rows] = await pool.query(query, params);
        return res.json(rows);
      }

      case 'save_milestone_assessment': {
        const auth = await verifyAuth(req);
        if (!auth || !['therapist', 'director', 'admin'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const studentId = await writableStudentId(auth, input, res);
        if (!studentId) return;
        const testNumber = Math.min(4, Math.max(1, parseInt(input.test_number || 1) || 1));
        const num = key => parseFloat(input[key] || 0);
        const saved = await upsertTestRecord('milestone_assessments', studentId, testNumber, {
          therapist_id: auth.sub,
          level: input.level || 'Level 1',
          assessment_date: input.assessment_date || new Date().toISOString().slice(0, 10),
          total_score: parseFloat(input.total_score || input.score || 0),
          max_score: parseFloat(input.max_score || 170),
          manding_score: num('manding_score'),
          tacting_score: num('tacting_score'),
          listener_score: num('listener_score'),
          echoic_score: num('echoic_score'),
          vocal_score: num('vocal_score'),
          vp_mts_score: num('vp_mts_score'),
          play_score: num('play_score'),
          social_score: num('social_score'),
          imitation_score: num('imitation_score'),
          lrffc_score: num('lrffc_score'),
          intraverbal_score: num('intraverbal_score'),
          group_score: num('group_score'),
          linguistic_score: num('linguistic_score'),
          reading_score: num('reading_score'),
          writing_score: num('writing_score'),
          math_score: num('math_score'),
          scores_detail: jsonColumn(input.scores_detail || input.milestones_data || {}),
          // Keep existing notes on update unless the client sends new ones.
          ...(input.therapist_notes !== undefined ? { therapist_notes: input.therapist_notes || null } : {}),
        });
        return res.json({ success: true, ...saved });
      }

      // 6B. VB-MAPP BARRIERS
      case 'get_barriers_assessments': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const scope = studentScopeSql('b.student_id', await accessibleStudentIds(auth));

        const studentId = req.query.student_id ? parseInt(req.query.student_id) : null;
        let query = `SELECT b.*, CONCAT(s.first_name, ' ', s.last_name) AS student_name, s.dob AS student_dob, u.name AS therapist_name
                     FROM barriers_assessments b 
                     LEFT JOIN students s ON b.student_id = s.id
                     LEFT JOIN users u ON b.therapist_id = u.id
                     WHERE ${scope.sql}`;
        const params = [...scope.params];
        if (studentId) {
          query += ` AND b.student_id = ?`;
          params.push(studentId);
        }
        query += ` ORDER BY b.test_number ASC, b.assessment_date DESC`;
        const [rows] = await pool.query(query, params);
        return res.json(rows);
      }

      case 'save_barriers_assessment': {
        const auth = await verifyAuth(req);
        if (!auth || !['therapist', 'director', 'admin'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const studentId = await writableStudentId(auth, input, res);
        if (!studentId) return;
        const testNumber = Math.min(4, Math.max(1, parseInt(input.test_number || 1) || 1));
        const saved = await upsertTestRecord('barriers_assessments', studentId, testNumber, {
          therapist_id: auth.sub,
          assessment_date: input.assessment_date || new Date().toISOString().slice(0, 10),
          total_score: parseFloat(input.total_score || 0),
          max_score: parseFloat(input.max_score || 96),
          barrier_scores: jsonColumn(input.barrier_scores || {}),
          // Keep existing notes on update unless the client sends new ones.
          ...(input.therapist_notes !== undefined ? { therapist_notes: input.therapist_notes || null } : {}),
        });
        return res.json({ success: true, ...saved });
      }

      // 6C. VB-MAPP TRANSITIONS
      case 'get_transition_assessments': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const scope = studentScopeSql('t.student_id', await accessibleStudentIds(auth));

        const studentId = req.query.student_id ? parseInt(req.query.student_id) : null;
        let query = `SELECT t.*, CONCAT(s.first_name, ' ', s.last_name) AS student_name, s.dob AS student_dob, u.name AS therapist_name
                     FROM transition_assessments t 
                     LEFT JOIN students s ON t.student_id = s.id
                     LEFT JOIN users u ON t.therapist_id = u.id
                     WHERE ${scope.sql}`;
        const params = [...scope.params];
        if (studentId) {
          query += ` AND t.student_id = ?`;
          params.push(studentId);
        }
        query += ` ORDER BY t.test_number ASC, t.assessment_date DESC`;
        const [rows] = await pool.query(query, params);
        return res.json(rows);
      }

      case 'save_transition_assessment': {
        const auth = await verifyAuth(req);
        if (!auth || !['therapist', 'director', 'admin'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const studentId = await writableStudentId(auth, input, res);
        if (!studentId) return;
        const testNumber = Math.min(4, Math.max(1, parseInt(input.test_number || 1) || 1));
        const saved = await upsertTestRecord('transition_assessments', studentId, testNumber, {
          therapist_id: auth.sub,
          assessment_date: input.assessment_date || new Date().toISOString().slice(0, 10),
          total_score: parseFloat(input.total_score || 0),
          max_score: parseFloat(input.max_score || 90),
          area_scores: jsonColumn(input.area_scores || {}),
          // Keep existing notes on update unless the client sends new ones.
          ...(input.therapist_notes !== undefined ? { therapist_notes: input.therapist_notes || null } : {}),
        });
        return res.json({ success: true, ...saved });
      }

      // 6D. VB-MAPP EESA
      case 'get_eesa_assessments': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const scope = studentScopeSql('e.student_id', await accessibleStudentIds(auth));

        const studentId = req.query.student_id ? parseInt(req.query.student_id) : null;
        let query = `SELECT e.*, CONCAT(s.first_name, ' ', s.last_name) AS student_name, s.dob AS student_dob, u.name AS therapist_name
                     FROM eesa_assessments e 
                     LEFT JOIN students s ON e.student_id = s.id
                     LEFT JOIN users u ON e.therapist_id = u.id
                     WHERE ${scope.sql}`;
        const params = [...scope.params];
        if (studentId) {
          query += ` AND e.student_id = ?`;
          params.push(studentId);
        }
        query += ` ORDER BY e.test_number ASC, e.assessment_date DESC`;
        const [rows] = await pool.query(query, params);
        return res.json(rows);
      }

      case 'save_eesa_assessment': {
        const auth = await verifyAuth(req);
        if (!auth || !['therapist', 'director', 'admin'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const studentId = await writableStudentId(auth, input, res);
        if (!studentId) return;
        const testNumber = Math.min(4, Math.max(1, parseInt(input.test_number || 1) || 1));
        const saved = await upsertTestRecord('eesa_assessments', studentId, testNumber, {
          therapist_id: auth.sub,
          assessment_date: input.assessment_date || new Date().toISOString().slice(0, 10),
          group1_score: parseFloat(input.group1_score || 0),
          group2_score: parseFloat(input.group2_score || 0),
          total_score: parseFloat(input.total_score || 0),
          responses: jsonColumn(input.responses || {}),
          // Keep existing notes on update unless the client sends new ones.
          ...(input.therapist_notes !== undefined ? { therapist_notes: input.therapist_notes || null } : {}),
        });
        return res.json({ success: true, ...saved });
      }

      // 6E. PREFERENCE (REINFORCER) ASSESSMENTS
      case 'get_preference_assessments': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const scope = studentScopeSql('p.student_id', await accessibleStudentIds(auth));

        const studentId = req.query.student_id ? parseInt(req.query.student_id) : null;
        let query = `SELECT p.*, CONCAT(s.first_name, ' ', s.last_name) AS student_name
                     FROM preference_assessments p
                     LEFT JOIN students s ON p.student_id = s.id
                     WHERE ${scope.sql}`;
        const params = [...scope.params];
        if (studentId) {
          query += ` AND p.student_id = ?`;
          params.push(studentId);
        }
        query += ` ORDER BY p.assessment_date DESC, p.id DESC`;
        const [rows] = await pool.query(query, params);
        return res.json(rows);
      }

      case 'save_preference_assessment': {
        const auth = await verifyAuth(req);
        if (!auth || !['therapist', 'director', 'admin'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const studentId = await writableStudentId(auth, input, res);
        if (!studentId) return;

        const categories = ['Edible', 'Toys/Materials', 'Social', 'Sensory', 'Other'];
        const assessmentDate = input.assessment_date || new Date().toISOString().slice(0, 10);
        // Accepts `items: [{category, item_name, rating, hierarchy_rank, notes}]` or a single item.
        const items = (Array.isArray(input.items) ? input.items : [input]).filter(i => i && (i.item_name || '').toString().trim());
        if (!items.length) return res.status(400).json({ error: 'At least one item_name is required' });

        const conn = await pool.getConnection();
        const ids = [];
        try {
          await conn.beginTransaction();
          // One preference snapshot per student per day: re-saving the same day replaces it.
          await conn.query('DELETE FROM preference_assessments WHERE student_id = ? AND assessment_date = ?', [studentId, assessmentDate]);
          for (const item of items) {
            const rating = Math.min(5, Math.max(1, parseInt(item.rating || 5) || 5));
            const [result] = await conn.query(
              `INSERT INTO preference_assessments (student_id, therapist_id, category, item_name, rating, hierarchy_rank, notes, assessment_date)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
              [
                studentId,
                auth.sub,
                categories.includes(item.category) ? item.category : 'Other',
                item.item_name.toString().trim().slice(0, 150),
                rating,
                (item.hierarchy_rank || 'High-Preference Primary Reinforcer').toString().slice(0, 50),
                item.notes || null,
                assessmentDate,
              ]
            );
            ids.push(result.insertId);
          }
          await conn.commit();
        } catch (err) {
          await conn.rollback();
          throw err;
        } finally {
          conn.release();
        }
        await auditLog(auth.sub, auth.role, 'SAVE_PREFERENCE_ASSESSMENT', 'preference_assessments', ids[0], ip, ua, `Saved ${ids.length} preference item(s) for student ${studentId}`);
        return res.json({ success: true, id: ids[0], ids });
      }

      // Backward-compatibility bridge for generic get_vb_assessments
      case 'get_vb_assessments': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const scope = studentScopeSql('m.student_id', await accessibleStudentIds(auth));

        const studentId = req.query.student_id ? parseInt(req.query.student_id) : null;
        let query = `SELECT m.*, CONCAT(s.first_name, ' ', s.last_name) AS student_name, s.dob AS student_dob, u.name AS therapist_name
                     FROM milestone_assessments m 
                     LEFT JOIN students s ON m.student_id = s.id
                     LEFT JOIN users u ON m.therapist_id = u.id
                     WHERE ${scope.sql}`;
        const params = [...scope.params];
        if (studentId) {
          query += ` AND m.student_id = ?`;
          params.push(studentId);
        }
        query += ` ORDER BY m.id DESC`;
        const [rows] = await pool.query(query, params);
        return res.json(rows);
      }

      // ──────────────────────────────────────────────────────────────────────
      // 7. SESSIONS & DIRECTOR APPOINTMENTS
      // ──────────────────────────────────────────────────────────────────────
      case 'get_sessions': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const scope = studentScopeSql('ts.student_id', await accessibleStudentIds(auth));

        const dateFilter = input.date || req.query.date;
        let query = `SELECT ts.*,
            CONCAT(s.first_name, ' ', s.last_name) AS student_name,
            s.dob AS student_dob,
            u.name AS therapist_name
           FROM therapy_sessions ts
           LEFT JOIN students s ON ts.student_id = s.id
           LEFT JOIN users u ON ts.therapist_id = u.id
           WHERE (${scope.sql}${auth.role === 'therapist' ? ' OR ts.therapist_id = ?' : ''}) `;
        let params = [...scope.params];
        if (auth.role === 'therapist') params.push(auth.sub);
        if (dateFilter && dateFilter !== 'all') {
          query += ` AND ts.session_date = ? `;
          params.push(dateFilter);
        }
        query += ` ORDER BY ts.session_date ASC, ts.start_time ASC`;
        const [rows] = await pool.query(query, params);
        return res.json(rows);
      }

      case 'save_therapy_session': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const therapistId = parseInt(input.therapist_id || 0);
        const studentId = parseInt(input.student_id || 0);
        const sessionDate = input.session_date || input.date || new Date().toISOString().split('T')[0];
        const startTime = (input.start_time || '09:00 AM').trim();
        const endTime = (input.end_time || '10:00 AM').trim();
        const room = (input.room || 'Sensory Room A').trim();
        const programTitle = (input.program_title || 'ABA Therapy Session').trim();
        const status = input.status || 'upcoming';
        const notes = input.clinical_notes || input.notes || '';

        if (!therapistId || !studentId) {
          return res.status(400).json({ error: 'therapist_id and student_id are required' });
        }

        // 1. Conflict Check: Therapist schedule collision
        const [therapistConflict] = await pool.query(
          `SELECT id FROM therapy_sessions 
           WHERE therapist_id = ? AND session_date = ? AND start_time = ? AND status != 'cancelled'
           LIMIT 1`,
          [therapistId, sessionDate, startTime]
        );
        if (therapistConflict.length > 0) {
          return res.status(409).json({ 
            conflict: true, 
            error: 'Therapist Schedule Conflict: The selected clinician already has an active session scheduled at this date and time.' 
          });
        }

        // 2. Conflict Check: Room collision
        if (room) {
          const [roomConflict] = await pool.query(
            `SELECT id FROM therapy_sessions 
             WHERE room = ? AND session_date = ? AND start_time = ? AND status != 'cancelled'
             LIMIT 1`,
            [room, sessionDate, startTime]
          );
          if (roomConflict.length > 0) {
            return res.status(409).json({ 
              conflict: true, 
              error: `Room Conflict: ${room} is already booked at ${startTime} on ${sessionDate}.` 
            });
          }
        }

        const [result] = await pool.query(
          `INSERT INTO therapy_sessions (therapist_id, student_id, session_date, start_time, end_time, room, program_title, status, clinical_notes)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [therapistId, studentId, sessionDate, startTime, endTime, room, programTitle, status, notes]
        );

        const newId = result.insertId;

        // Dispatch Notification to Therapist
        await createNotification(
          therapistId, 
          'SESSION_SCHEDULED',
          'New Therapy Session Scheduled', 
          `You have a session scheduled with student #${studentId} on ${sessionDate} at ${startTime} in ${room}.`,
          { session_id: newId, student_id: studentId, date: sessionDate }
        );

        await auditLog(auth.sub, auth.role, 'SCHEDULE_SESSION', 'therapy_sessions', newId, ip, ua, `Scheduled therapy session ${newId} for therapist ${therapistId} with student ${studentId}`);
        return res.json({ success: true, id: newId });
      }

      case 'update_therapy_session': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });

        const sessionId = parseInt(input.id || input.session_id || 0);
        if (!sessionId) return res.status(400).json({ error: 'Session ID required' });

        const status = input.status || null;
        const notes = input.clinical_notes !== undefined ? input.clinical_notes : (input.notes !== undefined ? input.notes : null);
        const room = input.room || null;
        const startTime = input.start_time || null;
        const endTime = input.end_time || null;
        const programTitle = input.program_title || null;

        await pool.query(
          `UPDATE therapy_sessions SET 
             status = COALESCE(?, status),
             clinical_notes = COALESCE(?, clinical_notes),
             room = COALESCE(?, room),
             start_time = COALESCE(?, start_time),
             end_time = COALESCE(?, end_time),
             program_title = COALESCE(?, program_title)
           WHERE id = ?`,
          [status, notes, room, startTime, endTime, programTitle, sessionId]
        );

        await auditLog(auth.sub, auth.role, 'UPDATE_SESSION', 'therapy_sessions', sessionId, ip, ua, `Updated therapy session ${sessionId}`);
        return res.json({ success: true, id: sessionId });
      }

      case 'delete_therapy_session': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const sessionId = parseInt(input.id || input.session_id || req.query.id || 0);
        if (!sessionId) return res.status(400).json({ error: 'Session ID required' });

        await pool.query('DELETE FROM therapy_sessions WHERE id = ?', [sessionId]);
        await auditLog(auth.sub, auth.role, 'DELETE_SESSION', 'therapy_sessions', sessionId, ip, ua, `Deleted therapy session ${sessionId}`);
        return res.json({ success: true, id: sessionId });
      }

      case 'get_director_appointments': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });

        // Admin/director see the whole calendar; others only appointments booked for them
        if (['admin', 'director'].includes(auth.role)) {
          const [rows] = await pool.query('SELECT * FROM director_appointments ORDER BY date ASC, start_time ASC');
          return res.json(rows);
        }
        const [rows] = await pool.query(
          'SELECT * FROM director_appointments WHERE LOWER(attendee_email) = LOWER(?) ORDER BY date ASC, start_time ASC',
          [auth.email || '']
        );
        return res.json(rows);
      }

      case 'save_director_appointment': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const userId = auth.sub;
        const userName = auth.name;
        const userRole = auth.role;

        // Parents/therapists book for themselves, so their own email is what scopes get_director_appointments
        if (!['admin', 'director'].includes(userRole)) input.attendee_email = auth.email;

        const attendeeName = (input.attendee_name || userName).trim();
        const attendeeRole = (input.attendee_role || 'Parent').trim();
        const title = (input.title || 'Director Clinical Conference').trim();
        const date = input.date || new Date().toISOString().split('T')[0];
        const startTime = input.start_time || '09:00 AM';
        const endTime = input.end_time || '10:00 AM';

        const [result] = await pool.query(
          `INSERT INTO director_appointments (director_user_id, title, appointment_type, date, start_time, end_time, attendee_name, attendee_role, attendee_phone, attendee_email, location, scheduled_by, status, notes) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, "confirmed", ?)`,
          [
            2,
            title,
            input.appointment_type || 'diagnosticIntake',
            date,
            startTime,
            endTime,
            attendeeName,
            attendeeRole,
            input.attendee_phone || '',
            input.attendee_email || '',
            input.location || 'Director Suite 201',
            userRole,
            input.notes || '',
          ]
        );

        const newApptId = result.insertId;
        console.log(`✅ [APPOINTMENT_SCHEDULED] Appointment #${newApptId} booked for Attendee "${attendeeName}" with Director`);

        // Dispatch real-time notification to Director (ID 2)
        await createNotification(
          2,
          'APPOINTMENT_SCHEDULED',
          `New Appointment: ${attendeeName}`,
          `${userName} (${userRole}) scheduled "${title}" with Attendee: ${attendeeName} (${attendeeRole}) on ${date} at ${startTime}.`,
          { appointment_id: newApptId, attendee_name: attendeeName, title, date, start_time: startTime }
        );

        // Also record audit log
        await auditLog(userId, userRole, 'APPOINTMENT_SCHEDULED', 'director_appointments', newApptId, ip, ua, `Scheduled with ${attendeeName}`);

        return res.json({ success: true, id: newApptId });
      }

      case 'update_director_appointment': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const apptId = parseInt(input.id || 0);
        const [appt] = await pool.query('SELECT attendee_email FROM director_appointments WHERE id = ? LIMIT 1', [apptId]);
        if (!appt.length) return res.status(404).json({ error: 'Appointment not found' });
        // Others may only cancel their own bookings.
        const isStaff = ['admin', 'director'].includes(auth.role);
        if (!isStaff && ((appt[0].attendee_email || '').toLowerCase() !== (auth.email || '').toLowerCase() || input.status !== 'cancelled')) {
          return res.status(403).json({ error: 'Forbidden' });
        }
        const status = ['confirmed', 'tentative', 'completed', 'cancelled'].includes(input.status) ? input.status : 'confirmed';
        const notes = input.notes === undefined ? null : input.notes.toString();
        await pool.query('UPDATE director_appointments SET status = ?, notes = COALESCE(?, notes) WHERE id = ?', [status, notes, apptId]);
        await auditLog(auth.sub, auth.role, 'UPDATE_APPOINTMENT', 'director_appointments', apptId, ip, ua, `Updated appt ${apptId} to ${status}`);
        return res.json({ success: true });
      }

      case 'delete_director_appointment': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const apptId = parseInt(input.id || 0);
        await pool.query('DELETE FROM director_appointments WHERE id = ?', [apptId]);
        await auditLog(auth.sub, auth.role, 'DELETE_APPOINTMENT', 'director_appointments', apptId, ip, ua, `Deleted appointment ${apptId}`);
        return res.json({ success: true });
      }

      // ──────────────────────────────────────────────────────────────────────
      // 8. AUDIT LOGS & NOTIFICATIONS
      // ──────────────────────────────────────────────────────────────────────
      case 'get_governance_settings': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const [rows] = await pool.query('SELECT * FROM clinical_governance_settings WHERE setting_key = "default" LIMIT 1');
        return res.json(rows[0] || null);
      }

      case 'save_governance_settings': {
        const auth = await verifyAuth(req);
        if (!auth || auth.role !== 'director') return res.status(403).json({ error: 'Forbidden: Director only' });
        const str = (v, max) => (v ?? '').toString().trim().slice(0, max);
        const values = [
          str(input.target_mastery_criteria, 120) || '80% across 3 consecutive sessions',
          input.require_two_therapists ? 1 : 0,
          str(input.reassessment_frequency, 80) || 'Every 6 Months',
          Math.max(1, parseInt(input.stagnation_alert_days || 21)),
          Math.min(99.99, Math.max(0, parseFloat(input.supervision_ratio_target || 5))),
          input.dual_signoff_crisis ? 1 : 0,
          str(input.director_signature_name, 120),
          str(input.director_title, 120),
          str(input.director_bacb_cert, 80),
          auth.sub,
        ];
        await pool.query(
          `INSERT INTO clinical_governance_settings
             (setting_key, target_mastery_criteria, require_two_therapists, reassessment_frequency, stagnation_alert_days,
              supervision_ratio_target, dual_signoff_crisis, director_signature_name, director_title, director_bacb_cert, updated_by)
           VALUES ("default", ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
           ON DUPLICATE KEY UPDATE
             target_mastery_criteria = VALUES(target_mastery_criteria), require_two_therapists = VALUES(require_two_therapists),
             reassessment_frequency = VALUES(reassessment_frequency), stagnation_alert_days = VALUES(stagnation_alert_days),
             supervision_ratio_target = VALUES(supervision_ratio_target), dual_signoff_crisis = VALUES(dual_signoff_crisis),
             director_signature_name = VALUES(director_signature_name), director_title = VALUES(director_title),
             director_bacb_cert = VALUES(director_bacb_cert), updated_by = VALUES(updated_by)`,
          values
        );
        await auditLog(auth.sub, auth.role, 'SAVE_GOVERNANCE_SETTINGS', 'clinical_governance_settings', null, ip, ua, 'Updated clinical governance settings');
        return res.json({ success: true });
      }

      case 'get_center_settings': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const [rows] = await pool.query('SELECT setting_key, setting_value FROM center_settings');
        return res.json(Object.fromEntries(rows.map((r) => [r.setting_key, r.setting_value])));
      }

      case 'save_center_settings': {
        const auth = await verifyAuth(req);
        if (!auth || auth.role !== 'admin') return res.status(403).json({ error: 'Forbidden: Admin only' });
        const allowed = ['center_name', 'portal_title', 'support_email', 'emergency_hotline'];
        for (const key of allowed) {
          if (input[key] === undefined) continue;
          await pool.query(
            'INSERT INTO center_settings (setting_key, setting_value, updated_by) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), updated_by = VALUES(updated_by)',
            [key, input[key].toString().trim().slice(0, 255), auth.sub]
          );
        }
        await auditLog(auth.sub, auth.role, 'SAVE_CENTER_SETTINGS', 'center_settings', null, ip, ua, 'Updated center settings');
        return res.json({ success: true });
      }

      case 'save_supervision_log': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const therapistId = parseInt(input.therapist_id || 0);
        const hours = parseFloat(input.hours);
        const type = (input.supervision_type || '').toString().trim().slice(0, 120);
        if (!therapistId || !type || !(hours > 0 && hours <= 24)) {
          return res.status(400).json({ error: 'Therapist, supervision type and 0–24 hours are required' });
        }
        const [t] = await pool.query('SELECT id FROM users WHERE id = ? AND role = "therapist" LIMIT 1', [therapistId]);
        if (!t.length) return res.status(404).json({ error: 'Therapist not found' });
        const logDate = /^\d{4}-\d{2}-\d{2}$/.test(input.log_date || '') ? input.log_date : new Date().toISOString().split('T')[0];
        const [result] = await pool.query(
          'INSERT INTO supervision_logs (therapist_id, supervisor_id, supervision_type, hours, log_date, notes) VALUES (?, ?, ?, ?, ?, ?)',
          [therapistId, auth.sub, type, hours, logDate, (input.notes || '').toString()]
        );
        await auditLog(auth.sub, auth.role, 'LOG_SUPERVISION', 'supervision_logs', result.insertId, ip, ua, `${hours}h ${type} for therapist ${therapistId}`);
        return res.json({ success: true, id: result.insertId });
      }

      case 'get_supervision_logs': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });
        const [rows] = await pool.query(
          `SELECT l.*, u.name AS supervisor_name FROM supervision_logs l
           LEFT JOIN users u ON l.supervisor_id = u.id ORDER BY l.log_date DESC, l.id DESC`
        );
        return res.json(rows);
      }

      case 'get_my_profile': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const [rows] = await pool.query(
          `SELECT u.id, u.name, u.email, u.phone, u.role, u.created_at,
                  tp.employee_id, tp.designation, tp.qualification, tp.license_number, tp.specialties, tp.about, tp.date_of_joining
           FROM users u LEFT JOIN therapist_profiles tp ON tp.user_id = u.id WHERE u.id = ? LIMIT 1`,
          [auth.sub]
        );
        return res.json(rows[0] || null);
      }

      case 'update_my_profile': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const name = (input.name || '').toString().trim().slice(0, 120);
        if (!name) return res.status(400).json({ error: 'Name is required' });
        const phone = (input.phone || '').toString().trim().slice(0, 40);
        await pool.query('UPDATE users SET name = ?, phone = ? WHERE id = ?', [name, phone || null, auth.sub]);
        if (auth.role === 'therapist') {
          const str = (v, max) => (v === undefined ? null : v.toString().trim().slice(0, max));
          await pool.query(
            `INSERT INTO therapist_profiles (user_id, qualification, specialties, about) VALUES (?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE qualification = COALESCE(VALUES(qualification), qualification),
               specialties = COALESCE(VALUES(specialties), specialties), about = COALESCE(VALUES(about), about)`,
            [auth.sub, str(input.qualification, 150), str(input.specialties, 255), input.about === undefined ? null : input.about.toString()]
          );
        }
        await auditLog(auth.sub, auth.role, 'UPDATE_OWN_PROFILE', 'users', auth.sub, ip, ua, 'Self-service profile update');
        return res.json({ success: true });
      }

      case 'get_audit_logs': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const [rows] = await pool.query(
          `SELECT al.*, u.name AS user_name 
           FROM audit_logs al 
           LEFT JOIN users u ON al.user_id = u.id 
           ORDER BY al.id DESC LIMIT 100`
        );
        return res.json(rows);
      }

      case 'get_notifications': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        // Always the caller's own inbox; user_id/role params from the client are ignored
        const recipientId = auth.sub;

        const [rows] = await pool.query('SELECT * FROM notifications WHERE recipient_user_id = ? ORDER BY id DESC LIMIT 50', [recipientId]);
        const [countRow] = await pool.query('SELECT COUNT(*) as unread FROM notifications WHERE recipient_user_id = ? AND is_read = 0', [recipientId]);

        return res.json({
          unread_count: countRow[0]?.unread || 0,
          notifications: rows,
        });
      }

      case 'mark_notification_read': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const recipientId = auth.sub;

        const notifId = parseInt(input.notification_id || 0);
        if (notifId > 0) {
          await pool.query('UPDATE notifications SET is_read = 1 WHERE id = ? AND recipient_user_id = ?', [notifId, recipientId]);
        } else {
          await pool.query('UPDATE notifications SET is_read = 1 WHERE recipient_user_id = ?', [recipientId]);
        }
        return res.json({ success: true });
      }

      // ──────────────────────────────────────────────────────────────────────
      // 9. DPDP ACT 2023 CONSENT & DOSSIER EXPORT
      // ──────────────────────────────────────────────────────────────────────
      case 'record_parental_consent': {
        const auth = await verifyAuth(req);
        if (!auth) return res.status(401).json({ error: 'Unauthorized' });
        const studentId = parseInt(input.student_id || 0);
        if (!studentId) return res.status(400).json({ error: 'student_id required' });
        if (!(await canAccessStudent(auth, studentId))) return res.status(403).json({ error: 'Forbidden' });
        const version = input.consent_version || 'DPDP-2023-V1';

        const [result] = await pool.query(
          'INSERT INTO parental_consents (student_id, consent_version, ip_address, user_agent) VALUES (?, ?, ?, ?)',
          [studentId, version, ip, ua.substring(0, 255)]
        );

        if (auth) {
          await auditLog(auth.sub, auth.role, 'RECORD_CONSENT', 'parental_consents', result.insertId, ip, ua, `Consent recorded for student ${studentId}`);
        }
        return res.json({ success: true, consent_id: result.insertId });
      }

      case 'export_student_dossier': {
        const auth = await verifyAuth(req);
        if (!auth || !['admin', 'director'].includes(auth.role)) return res.status(403).json({ error: 'Forbidden' });

        const studentId = parseInt(input.student_id || 0);
        const [students] = await pool.query('SELECT * FROM students WHERE id = ? LIMIT 1', [studentId]);
        if (!students.length) return res.status(404).json({ error: 'Student not found' });

        const [med] = await pool.query('SELECT * FROM medical_histories WHERE student_id = ? LIMIT 1', [studentId]);
        const [ieps] = await pool.query('SELECT * FROM iep_reports WHERE student_id = ?', [studentId]);

        await auditLog(auth.sub, auth.role, 'EXPORT_DOSSIER', 'students', studentId, ip, ua, `Exported DPDP dossier for student ${studentId}`);

        return res.json({
          compliance: 'DPDP Act 2023 Regulated Export',
          exported_at: new Date().toISOString(),
          student: students[0],
          medical_history: med[0] || null,
          iep_reports: ieps,
        });
      }

      // Default Health Check
      default:
        return res.json({
          status: 'ROH ERP Secure Node.js Gateway Online',
          version: '2.5.0-nodejs',
          database: 'Connected (MySQL roh_erp)',
          timestamp: new Date().toISOString(),
        });
    }
  } catch (err) {
    console.error(`Error processing action ${action}:`, err);
    return res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// Root health check
app.get('/', (req, res) => {
  res.json({
    app: 'Ray of Hope Center for Autism ERP',
    status: 'Operational',
    runtime: 'Node.js ' + process.version,
    framework: 'Express',
    database: 'MySQL2 / roh_erp',
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 ROH-ERP Node.js Server listening on http://127.0.0.1:${PORT}`);
});
