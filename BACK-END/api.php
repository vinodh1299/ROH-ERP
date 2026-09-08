<?php
// ============================================================================
// Ray of Hope Center for Autism ERP — Unified REST API Bridge
// Host: Apache/DreamHost | Engine: PHP 7.4+ & PDO MySQL
// ============================================================================

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ── Database Configuration ──
$db_host = getenv('DB_HOST') ?: 'localhost';
$db_name = getenv('DB_NAME') ?: 'roh_erp';
$db_user = getenv('DB_USER') ?: 'root';
$db_pass = getenv('DB_PASS') ?: '';

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name;charset=utf8mb4", $db_user, $db_pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (PDOException $e) {
    // If DB is unreachable, return connection status note for frontend mock fallback
    $pdo = null;
}

$action = $_GET['action'] ?? $_POST['action'] ?? '';
$input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

function response($data, $code = 200) {
    http_response_code($code);
    echo json_encode($data);
    exit();
}

if (!$pdo) {
    response(['error' => 'Database connection offline', 'mode' => 'fallback'], 200);
}

switch ($action) {

    // ── Authentication ──
    case 'login':
        $email = trim($input['email'] ?? '');
        $password = trim($input['password'] ?? '');

        $stmt = $pdo->prepare("SELECT id, name, email, role FROM users WHERE LOWER(email) = LOWER(?) AND password = ?");
        $stmt->execute([$email, $password]);
        $user = $stmt->fetch();

        if ($user) {
            response($user);
        } else {
            response(['error' => 'Invalid email or password'], 401);
        }
        break;

    // ── Users / Staff ──
    case 'get_therapists':
        $stmt = $pdo->query("SELECT id, name, email, status FROM users WHERE role = 'therapist' ORDER BY id DESC");
        response($stmt->fetchAll());
        break;

    case 'add_therapist':
        $stmt = $pdo->prepare("INSERT INTO users (name, email, password, role, status) VALUES (?, ?, ?, 'therapist', 'Active')");
        $stmt->execute([$input['name'] ?? '', $input['email'] ?? '', $input['password'] ?? 'therapist123']);
        response(['success' => true, 'id' => $pdo->lastInsertId()]);
        break;

    case 'get_parents':
        $stmt = $pdo->query("SELECT id, name, email, phone, status FROM users WHERE role = 'parent' ORDER BY id DESC");
        response($stmt->fetchAll());
        break;

    case 'add_parent':
        $stmt = $pdo->prepare("INSERT INTO users (name, email, password, role, phone, status) VALUES (?, ?, ?, 'parent', ?, 'Active')");
        $stmt->execute([$input['name'] ?? '', $input['email'] ?? '', $input['password'] ?? 'parent123', $input['phone'] ?? '']);
        response(['success' => true, 'id' => $pdo->lastInsertId()]);
        break;

    // ── Students ──
    case 'get_students':
        $stmt = $pdo->query("SELECT * FROM students ORDER BY id DESC");
        response($stmt->fetchAll());
        break;

    case 'add_student':
        $name = trim($input['name'] ?? '');
        $nameParts = explode(' ', $name, 2);
        $firstName = $nameParts[0] ?? $name;
        $lastName = $nameParts[1] ?? '';

        $stmt = $pdo->prepare("INSERT INTO students (first_name, last_name, dob, phone, parent_email, parent_name, status) VALUES (?, ?, ?, ?, ?, ?, 'Active')");
        $stmt->execute([
            $firstName,
            $lastName,
            $input['dob'] ?? null,
            $input['phone'] ?? '',
            $input['email'] ?? '',
            $input['parent_name'] ?? '',
        ]);
        response(['success' => true, 'id' => $pdo->lastInsertId()]);
        break;

    case 'delete_student':
        $stmt = $pdo->prepare("DELETE FROM students WHERE id = ?");
        $stmt->execute([$input['id'] ?? 0]);
        response(['success' => true]);
        break;

    // ── IEP Reports ──
    case 'get_iep_reports':
        $stmt = $pdo->query("SELECT i.*, CONCAT(s.first_name, ' ', s.last_name) AS student_name FROM iep_reports i LEFT JOIN students s ON i.student_id = s.id ORDER BY i.id DESC");
        response($stmt->fetchAll());
        break;

    case 'save_iep_report':
        $stmt = $pdo->prepare("INSERT INTO iep_reports (student_id, therapist_id, title, status, manding_score, tacting_score, listener_score, echoic_score, lrffc_score, goals_summary) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $input['student_id'] ?? 1,
            $input['therapist_id'] ?? 1,
            $input['title'] ?? 'IEP Report',
            $input['status'] ?? 'Pending Approval',
            $input['manding_score'] ?? 0,
            $input['tacting_score'] ?? 0,
            $input['listener_score'] ?? 0,
            $input['echoic_score'] ?? 0,
            $input['lrffc_score'] ?? 0,
            $input['goals_summary'] ?? '',
        ]);
        response(['success' => true, 'id' => $pdo->lastInsertId()]);
        break;

    // ── Daily Data Sheets ──
    case 'get_daily_data':
        $stmt = $pdo->query("SELECT d.*, CONCAT(s.first_name, ' ', s.last_name) AS student_name FROM daily_data_sheets d LEFT JOIN students s ON d.student_id = s.id ORDER BY d.id DESC");
        response($stmt->fetchAll());
        break;

    case 'save_daily_data':
        $stmt = $pdo->prepare("INSERT INTO daily_data_sheets (student_id, therapist_id, session_date, domain, prompt_level, trials_completed, trials_successful, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $input['student_id'] ?? 1,
            $input['therapist_id'] ?? 1,
            $input['session_date'] ?? date('Y-m-d'),
            $input['domain'] ?? 'Manding',
            $input['prompt_level'] ?? 'Independent',
            $input['trials_completed'] ?? 10,
            $input['trials_successful'] ?? 8,
            $input['notes'] ?? '',
        ]);
        response(['success' => true, 'id' => $pdo->lastInsertId()]);
        break;

    // ── Reinforcer Preference Assessments ──
    case 'get_reinforcers':
        $stmt = $pdo->query("SELECT * FROM reinforcers ORDER BY id DESC");
        response($stmt->fetchAll());
        break;

    case 'save_reinforcer':
        $stmt = $pdo->prepare("INSERT INTO reinforcers (student_id, category, item_name, rating, notes) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([
            $input['student_id'] ?? 1,
            $input['category'] ?? 'Edible',
            $input['item_name'] ?? '',
            $input['rating'] ?? 5,
            $input['notes'] ?? '',
        ]);
        response(['success' => true, 'id' => $pdo->lastInsertId()]);
        break;

    // ── VB-MAPP Assessments ──
    case 'get_vb_assessments':
        $stmt = $pdo->query("SELECT v.*, CONCAT(s.first_name, ' ', s.last_name) AS student_name FROM vb_assessments v LEFT JOIN students s ON v.student_id = s.id ORDER BY v.id DESC");
        response($stmt->fetchAll());
        break;

    case 'save_vb_assessment':
        $stmt = $pdo->prepare("INSERT INTO vb_assessments (student_id, therapist_id, level, score, max_score, milestones_data) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $input['student_id'] ?? 1,
            $input['therapist_id'] ?? 1,
            $input['level'] ?? 'Level 1',
            $input['score'] ?? 0,
            $input['max_score'] ?? 170,
            json_encode($input['milestones_data'] ?? []),
        ]);
        response(['success' => true, 'id' => $pdo->lastInsertId()]);
        break;

    default:
        response(['status' => 'ROH ERP API Service Online', 'version' => '1.0.0']);
        break;
}
