# Functional Requirements Document (FRD)
## Ray of Hope Center for Autism — Clinical Enterprise Resource Planning (ROH-ERP)

---

### Document Control

| Attribute | Details |
| :--- | :--- |
| **Project Name** | Ray of Hope Center for Autism - Clinical Care & ERP System (ROH-ERP) |
| **Document Version** | 2.5.0 (Production Master Specification) |
| **Status** | Approved / Baseline |
| **Author** | Senior Full-Stack Healthcare Software Engineer & Solutions Architect |
| **Compliant Documents** | BRD v2.5.0, OpenAPI / Swagger Specification 3.0.0 |
| **Target Audience** | Software Engineers, QA Leads, DevOps Engineers, Security Officers, UI/UX Designers |

---

## 1. System Architecture Overview

### 1.1 Technology Stack

```
+─────────────────────────────────────────────────────────────────────────+
|                           CLIENT TIER                                   |
|   Flutter Web & Multi-Platform (Dart 3.x)                              |
|   • State Management: Provider Architecture                             |
|   • Design System: Custom ROH Clinical Palette (Theme / AppColors)       |
|   • Sound Engine: Web Audio API Dual-Tone Chime Synthesis                |
|   • Storage: SharedPreferences Web + LocalStorage Sync Adapter          |
+────────────────────────────────────┬────────────────────────────────────+
                                     │ HTTPS / JSON REST API
+────────────────────────────────────▼────────────────────────────────────+
|                         APPLICATION GATEWAY                             |
|   Node.js (v18+) + Express.js API Gateway                               |
|   • Security: OWASP Top 10 Headers (CSP, HSTS, X-Frame-Options)        |
|   • Auth Engine: JWT (HMAC-SHA256, 24h Expiry) + Bcrypt Hashing (Salt 10)|
|   • API Documentation: Swagger / OpenAPI 3.0 Interactive UI             |
+────────────────────────────────────┬────────────────────────────────────+
                                     │ MySQL2 Pool Connection
+────────────────────────────────────▼────────────────────────────────────+
|                           DATABASE TIER                                 |
|   MySQL 8.0 Enterprise Relational Engine                                |
|   • 12 Relational Tables (InnoDB, UTF8mb4)                              |
|   • Connection Pooling: 20 Concurrent Connections                       |
|   • Audit Logging & Foreign Key Integrity Cascades                      |
+─────────────────────────────────────────────────────────────────────────+
```

### 1.2 Access Tiers & Portals
The platform exposes four distinct guarded sub-applications accessed via hash routing (`/#/`):
1. **Director Portal** (`/#/director?tab=X`)
2. **Administrator Portal** (`/#/admin?tab=X`)
3. **Therapist Portal** (`/#/therapist?tab=X`)
4. **Parent Portal** (`/#/parent?tab=X`)

---

## 2. Cross-Cutting Security & Authentication Framework

### 2.1 FR-SEC-01: Authentication & Token Management
* **Description**: Secure credential authentication generating signed JSON Web Tokens (JWT).
* **Specifications**:
  * Passwords must be hashed using `bcrypt` with a minimum cost factor of 10.
  * Successful authentication returns a signed JWT containing `sub` (User ID), `email`, `role`, and `name` with a 24-hour expiration window.
  * The frontend `AuthService` synchronizes authentication state across `SharedPreferences` and browser `localStorage`.
  * **API Endpoint**: `POST /api?action=login`
  * **Payload**: `{ "email": "user@roh.com", "password": "securePassword" }`
  * **Response**: `{ "id": 1, "name": "...", "role": "admin", "token": "jwt.token.string" }`

### 2.2 FR-SEC-02: Route Guards & Role-Based Access Control (RBAC)
* **Description**: Strict client-side and server-side authorization barrier.
* **Specifications**:
  * Flutter navigation utilizes `_generateGuardedRoute()` in `main.dart`.
  * Unauthenticated requests to protected routes (`/admin`, `/director`, `/therapist`, `/parent`) immediately redirect to `/login`.
  * Role mismatches (e.g., Therapist attempting to open `/admin`) are intercepted, logged, and redirected to the user's authorized home shell.
  * Server-side middleware verifies the `Authorization: Bearer <token>` header against the requested action role requirement.

### 2.3 FR-SEC-03: Dual-Custody Administrative Password Resets
* **Description**: High-security two-step workflow for resetting staff credentials.
* **Specifications**:
  * An Administrator initiates a password reset request via `AdminInitiateResetDialog`.
  * The request is flagged in the database with `status = 'pending_director_approval'`.
  * The Clinical Director reviews the reset in `DirectorPasswordResetsView` and explicitly authorizes or declines it.
  * Upon authorization, the user’s `must_change_password` flag is set to `1`.
  * Upon next login, `ForcedPasswordChangeDialog` prevents portal interaction until the user sets a strong new password.

### 2.4 FR-SEC-04: DPDP Act 2023 Digital Consent Engine
* **Description**: Statutory consent gate for minor student data handling.
* **Specifications**:
  * Upon logging into the Parent Portal, `DpdpConsentDialog.showIfNeeded()` checks the database for `dpdp_consent_student_<id>`.
  * If unrecorded, an un-dismissible modal enforces three explicit agreements:
    1. *Clinical & Therapy Data Processing*: Authorization for BCBA clinicians to record behavioral probes.
    2. *Record Retention & Portability*: Confirmation of clinical continuity and right to request dossier export.
    3. *Emergency Clinical Protocols*: Authorization to access allergy and emergency contacts during clinical incidents.
  * Submissions record an immutable entry into `audit_logs` with the parent's IP address and timestamp.

---

## 3. Module Specifications

```
+─────────────────────────────────────────────────────────────────────────+
|                         ROH-ERP FUNCTIONAL MODULES                      |
+─────────────────────────────────────────────────────────────────────────+
| 1. Director Portal     │ Executive oversight, capacity, schedule, IEP   |
| 2. Admin Portal        │ Student intake wizard, staff roster, calendar  |
| 3. Therapist Portal    │ Timetable, VB-MAPP suite, daily ABA data sheet |
| 4. Parent Portal       │ Daily takeaway, IEP goal trends, appointments  |
| 5. Notification Engine │ Real-time polling & Web Audio chime alerts     |
| 6. Scheduling Engine   │ Conflict-free room and clinician allocation    |
+─────────────────────────────────────────────────────────────────────────+
```

---

### 3.1 Module 1: Clinical Director Executive Portal (`/director`)

#### FR-DIR-01: Executive Clinical Dashboard (`tab=0`)
* **Features**:
  * **Center Caseload Capacity Bar**: Real-time visualization of total active students vs. center licensed capacity (e.g., 1 / 30 Students, 3% utilized, 29 open slots).
  * **Director Clinical Attention Queue**: Urgent clinical alerts, unassigned intake evaluations, and pending IEP approvals.
  * **Clinical Governance Metrics Cards**: Active Caseload, Mastery Velocity (targets mastered this quarter), Audit Compliance percentage, and BACB Supervised Hours counter.
  * **Therapist Timetable Strip**: Quick view of center room allocations and clinician status with a "+ Schedule Session for Therapist" modal launcher.

#### FR-DIR-02: Center Master Schedule (`tab=1`)
* **Features**:
  * Complete timeline view of all therapy sessions scheduled across the facility.
  * Filterable by Date (`Today`, `Tomorrow`, `In 2 Days`, or custom Date Picker) and Room Location.
  * Status badges indicating real-time session state: `Upcoming`, `In Progress`, `Completed`, `Cancelled`.

#### FR-DIR-03: Therapist Management Section (`tab=2`)
* **Features**:
  * Grid directory of all clinical staff displaying designation, qualifications, and active student caseload count.
  * Action menus allowing profile inspections and assignment modifications.

#### FR-DIR-04: Student Clinical Directory (`tab=3`)
* **Features**:
  * Comprehensive registry of enrolled children with photo avatar, age, admission date, and primary diagnosed domains.
  * Launch buttons for deep clinical evaluations.

#### FR-DIR-05: Longitudinal Student Progress Section (`tab=4`)
* **Features**:
  * Multi-domain mastery trackers showing cumulative milestones achieved across VB-MAPP developmental levels.
  * Trend visualizations indicating learning velocity over consecutive clinical cycles.

#### FR-DIR-06: IEP Governance & Authorization (`tab=5`)
* **Features**:
  * Filterable audit table of all student IEPs (`Approved`, `Pending Sign-off`, `Revision Requested`).
  * Inspection modal displaying long-term goals, short-term objectives, mastery criteria, and prompt fade schedules.
  * Director digital signature action updating status to `Approved` and notifying the parent.

#### FR-DIR-07: Center Settings & Security Management (`tab=6`)
* **Features**:
  * Facility-wide parameters, operating hours, cabin room labels.
  * Integrated view for inspecting system audit trails and managing pending credential reset approvals.

---

### 3.2 Module 2: Center Administrator Portal (`/admin`)

#### FR-ADM-01: Administrative Hub Dashboard (`tab=0`)
* **Features**:
  * Total counts for Enrolled Students, Active Clinicians, and Operations Staff.
  * Recent activity feed tracking admissions, appointments, and therapist registrations.
  * Quick-access dispatcher to coordinate parent diagnostic intakes with the Clinical Director.

#### FR-ADM-02: Director Calendar & Scheduling Dispatcher (`tab=1`)
* **Features**:
  * Interactive booking board displaying the Clinical Director's available time slots (e.g., 09:00 AM, 10:15 AM, 11:30 AM, 01:30 PM, 02:45 PM, 04:00 PM).
  * Direct booking tool to schedule parent intake assessments, diagnostic reviews, and 6-month IEP conferences with automatic notification generation.

#### FR-ADM-03: Therapists Administration (`tab=2`)
* **Features**:
  * Staff onboarding dialog (`AdminTherapistAddDialog`) capturing Employee ID, Full Name, Email, Phone, Date of Birth, Designation, and Clinical Biography.
  * Editing and credential revocation capabilities.

#### FR-ADM-04: Student Multi-Step Intake Wizard (`tab=3`)
* **Features**:
  * **Tab 1: Student Demographics**: First Name, Middle Name, Last Name, Gender, DOB, City, Pin Code, Application Date, Blood Group, Residential Address.
  * **Tab 2: Medication & Medical History**:
    * Dynamic medication grid (Medication Name, Prescribed Date, Dosage, Timeline, Indication).
    * Six clinical diagnostic screening textareas (Hospitalizations, Medical Conditions, Infectious Diseases, Allergies, Eating Habits, Sleeping Patterns).
  * **Tab 3: Guardians & Emergency Contacts**: Multi-guardian directory cards (Name, Relationship, Phone, Address, Email) + Emergency primary notification priority.

#### FR-ADM-05: Stud Progress & IEP Tracking (`tabs=4, 5`)
* **Features**: Administrative tracking of clinical milestone milestones and document storage.

#### FR-ADM-06: Application Configuration (`tab=6`)
* **Features**: Theme options, organization details, and administrator account preferences.

---

### 3.3 Module 3: Therapist Clinical Portal (`/therapist`)

#### FR-THE-01: Clinician Station Dashboard (`tab=0`)
* **Features**:
  * Personal daily queue of assigned children.
  * Quick launch bar to start active sessions and open data sheets.

#### FR-THE-02: Therapy Timetable & Daily Schedule (`tab=1`)
* **Features**:
  * Chronological card sequence of assigned therapy blocks.
  * Each card displays: Session Time (e.g., 01:00 PM - 02:15 PM), Student Name, Clinical Room/Cabin, Target Clinical Program, and a prominent green **"Start Session"** button.

#### FR-THE-03: VB-MAPP Milestones Assessment Module (`tab=2`)
* **Features**:
  * Standardized scoring across 3 Developmental Levels (0–18 months, 18–30 months, 30–48 months).
  * Evaluates 16 functional domains: *Mand, Tact, Echoic, Intraverbal, Listener Responding, Visual Perceptual / Match-to-Sample (VP-MTS), Independent Play, Social Play, Motor Imitation, Echoic (EESA), Vocal, Reading, Writing, Math, Classroom Routines, Linguistic Structure*.
  * Scored using discrete probes (0, 0.5, 1.0).

#### FR-THE-04: VB-MAPP Barriers Assessment & Visual Master Chart (`tab=3`)
* **Features**:
  * Evaluation of 24 learning barriers:
    1. *Negative Behaviors*
    2. *Instructional Control (Escaping demands)*
    3. *Impaired Mand*
    4. *Impaired Tact*
    5. *Impaired Motor Imitation*
    6. *Impaired Echoic*
    7. *Impaired VP-MTS*
    8. *Impaired Listener Responding*
    9. *Impaired Intraverbal*
    10. *Impaired Social Skills*
    11. *Prompt Dependent*
    12. *Scrolling (guessing/cycling responses)*
    13. *Impaired Scanning*
    14. *Impaired Conditional Discrimination*
    15. *Failure to Generalize*
    16. *Weak Motivators (MO)*
    17. *Response Requirement Weakens MO*
    18. *Reinforcer Dependent*
    19. *Self-Stimulatory Behaviors*
    20. *Hyperactive Behavior*
    21. *Sensory Defensiveness*
    22. *Impaired Articulation*
    23. *Obsessive / Ritualistic Behaviors*
    24. *Impaired Receptive Language*
  * **Scoring Criteria**: Standardized 0–4 severity scale (0 = No problem, 4 = Severe problem).
  * **Visual Master Chart (Graph Tab)**: 24 distinct grid cards, each displaying 5 vertical levels (0 to 4) across 4 horizontal testing iterations, color-coded:
    * Test 1 = 🟧 Orange
    * Test 2 = 🟪 Purple
    * Test 3 = 🟩 Green
    * Test 4 = 🟦 Blue

#### FR-THE-05: VB-MAPP Transition Assessment (`tab=4`)
* **Features**:
  * 18 transition domains evaluating the child's readiness for placement in a less restrictive educational environment (e.g., mainstream inclusive classroom).

#### FR-THE-06: Early Echoic Skills Assessment - EESA (`tab=5`)
* **Features**:
  * Detailed probe scoring across simple vowels, consonant-vowel combinations, multi-syllabic words, and prosody/inflection variations.

#### FR-THE-07: Preference Assessment Module (`tab=6`)
* **Features**:
  * Systematic recording of MSWO (Multiple Stimulus Without Replacement) or Paired-Choice reinforcer sampling.
  * Outputs a ranked hierarchy of primary tangible, social, and sensory reinforcers.

#### FR-THE-08: VB-MAPP Comprehensive Report Form (`tab=7`)
* **Features**:
  * Unified report aggregating Milestones, Barriers, and Transitions into a printable clinical diagnostic evaluation.

#### FR-THE-09: Individualized Education Plan (IEP) Formulator (`tab=8`)
* **Features**:
  * Direct formulation of IEP goals based on identified assessment deficits.
  * Defines Domain, Target Name, Baseline Score, Mastery Criteria (e.g., 80% accuracy over 3 consecutive sessions across 2 clinicians), and Review Date.

#### FR-THE-10: Daily Data Collection Sheet (`tab=9`)
* **Features**:
  * Real-time Discrete Trial Training (DTT) recorder.
  * Interactive trial counters: Correct (`+`), Incorrect (`-`), Prompted (`P`).
  * Prompt Hierarchy tracking: Full Physical, Partial Physical, Model, Verbal, Visual, Gestural, Independent.
  * Daily Behavioral Notes & **Parent Carryover Takeaway** formulation.

#### FR-THE-11: Clinician Profile (`tab=10`)
* **Features**: Credentials, contact details, assigned caseload.

---

### 3.4 Module 4: Parent Engagement Portal (`/parent`)

#### FR-PAR-01: Parent Station Dashboard (`tab=0`)
* **Features**:
  * Greeting banner showing enrolled child name (*Abhishek Kumar*).
  * **Today's Therapy Timetable**: Real-time view of scheduled sessions, assigned clinician (*Dr. Sarah Lee*), and therapy room.
  * **Today's Clinical Takeaway & Home Carryover**: Highlights practical instructions from the therapist (e.g., prompting strategy to use at dinner).
  * **Director Consultations Card**: View booked meetings with the Clinical Director or launch the "+ Request Meeting with Director" booking dialog.
  * **Clinical Progress Summary**: Mastered targets count and attendance percentage.

#### FR-PAR-02: Clinical Progress Reports (`tab=1`)
* **Features**: Access to therapist progress summaries and quarterly development notes.

#### FR-PAR-03: IEP Goal Data Hub (`tab=2`)
* **Features**:
  * Real-time tracking of active IEP objectives.
  * Visual progress bars depicting mastery status across Expressive Language, Receptive Language, Social Skills, and Daily Living.

#### FR-PAR-04: Real-Time Clinical Trend Graphs (`tab=3`)
* **Features**:
  * Cumulative target mastery graphs over time.
  * Visual verification of behavioral rate reductions.

#### FR-PAR-05: Family Profile (`tab=4`)
* **Features**: Emergency contacts, registered phone numbers, and child dietary restrictions.

---

### 3.5 Module 5: Real-Time Notification & Audio Alerting Engine

#### FR-NOT-01: Notification Dispatch & Polling
* **Features**:
  * Background polling every 8–10 seconds via `NotificationService`.
  * Triggered notifications for:
    * Director assigns new therapy session to therapist.
    * Parent books consultation with Director.
    * IEP report submitted for sign-off or approved.
    * Emergency contact or medication update.
  * Interactive slide-out **Notification Center Drawer** with unread counters and "Mark All as Read" actions.

#### FR-NOT-02: Web Audio Dual-Tone Bell Chime
* **Features**:
  * Synthesizes audio in real time using the native HTML5 / Dart Web Audio API without requiring external MP3/WAV asset downloads.
  * Dual-harmonic bell structure:
    * Tone 1: 587.33 Hz (D5) soft attack (0.35s).
    * Tone 2: 880.00 Hz (A5) clear bell harmonic (0.55s).
    * Tone 3: 1174.66 Hz (D6) sparkling finish (0.70s).
  * Includes automated user gesture unlocking on first tap/click.

---

## 4. Data Dictionary & Database Architecture

The backend utilizes 12 relational MySQL tables configured with UTF8mb4 character sets:

```
+─────────────────────+       +──────────────────────+       +─────────────────────+
|        users        | 1   * |   therapy_sessions   | *   1 |      students       |
|─────────────────────|───────|──────────────────────|───────|─────────────────────|
| id (PK)             |       | id (PK)              |       | id (PK)             |
| email               |       | student_id (FK)      |       | first_name          |
| password_hash       |       | therapist_id (FK)    |       | last_name           |
| name                |       | session_date         |       | dob                 |
| role                |       | start_time           |       | gender              |
| must_change_password|       | end_time             |       | blood_group         |
+─────────────────────+       | room_name            |       +─────────────────────+
         │ 1                  | program_name         |                  │ 1
         │                    | status               |                  │
         │ *                  | clinical_notes       |                  │ *
+─────────────────────+       | parent_takeaway      |       +─────────────────────+
|    notifications    |       +──────────────────────+       |     guardians       |
|─────────────────────|                                      |─────────────────────|
| id (PK)             |                                      | id (PK)             |
| recipient_user_id(FK)                                      | student_id (FK)     |
| title               |                                      | name                |
| message             |                                      | relationship        |
| is_read             |                                      | phone               |
+─────────────────────+                                      +─────────────────────+
```

### Table 1: `users`
* `id`: INT AUTO_INCREMENT, PRIMARY KEY
* `email`: VARCHAR(191) NOT NULL UNIQUE
* `password_hash`: VARCHAR(255) NOT NULL
* `name`: VARCHAR(150) NOT NULL
* `role`: ENUM('admin', 'director', 'therapist', 'parent') NOT NULL
* `must_change_password`: TINYINT(1) DEFAULT 0
* `created_at`: TIMESTAMP DEFAULT CURRENT_TIMESTAMP

### Table 2: `students`
* `id`: INT AUTO_INCREMENT, PRIMARY KEY
* `first_name`: VARCHAR(100) NOT NULL
* `middle_name`: VARCHAR(100)
* `last_name`: VARCHAR(100) NOT NULL
* `dob`: DATE NOT NULL
* `gender`: ENUM('Male', 'Female', 'Other')
* `blood_group`: VARCHAR(10)
* `city`: VARCHAR(100)
* `pin_code`: VARCHAR(20)
* `address`: TEXT
* `status`: ENUM('Active', 'De-Activated', 'Waitlist') DEFAULT 'Active'

### Table 3: `therapy_sessions`
* `id`: INT AUTO_INCREMENT, PRIMARY KEY
* `student_id`: INT NOT NULL, FOREIGN KEY (`student_id`) REFERENCES `students`(`id`)
* `therapist_id`: INT NOT NULL, FOREIGN KEY (`therapist_id`) REFERENCES `users`(`id`)
* `session_date`: DATE NOT NULL
* `start_time`: TIME NOT NULL
* `end_time`: TIME NOT NULL
* `room_name`: VARCHAR(100) NOT NULL
* `program_name`: VARCHAR(150) NOT NULL
* `status`: ENUM('Upcoming', 'In Progress', 'Completed', 'Cancelled') DEFAULT 'Upcoming'
* `clinical_notes`: TEXT
* `parent_takeaway`: TEXT

### Table 4: `director_appointments`
* `id`: INT AUTO_INCREMENT, PRIMARY KEY
* `parent_name`: VARCHAR(150) NOT NULL
* `student_name`: VARCHAR(150) NOT NULL
* `appointment_date`: DATE NOT NULL
* `start_time`: VARCHAR(50) NOT NULL
* `purpose`: VARCHAR(255) NOT NULL
* `status`: ENUM('Pending', 'Confirmed', 'Completed', 'Cancelled') DEFAULT 'Pending'

### Table 5: `iep_reports`
* `id`: INT AUTO_INCREMENT, PRIMARY KEY
* `student_id`: INT NOT NULL, FOREIGN KEY (`student_id`) REFERENCES `students`(`id`)
* `therapist_id`: INT NOT NULL, FOREIGN KEY (`therapist_id`) REFERENCES `users`(`id`)
* `title`: VARCHAR(200) NOT NULL
* `status`: ENUM('Pending', 'Approved', 'Cancelled') DEFAULT 'Pending'
* `director_signature`: VARCHAR(150)
* `sign_off_date`: DATETIME

### Table 6: `audit_logs`
* `id`: INT AUTO_INCREMENT, PRIMARY KEY
* `user_id`: INT
* `user_role`: VARCHAR(50)
* `action`: VARCHAR(100) NOT NULL
* `target_entity`: VARCHAR(100)
* `target_id`: INT
* `ip_address`: VARCHAR(45)
* `user_agent`: TEXT
* `details`: TEXT
* `created_at`: TIMESTAMP DEFAULT CURRENT_TIMESTAMP

---

## 5. Non-Functional Requirements (NFRs)

| NFR Code | Requirement Category | Specification Standard |
| :--- | :--- | :--- |
| **NFR-01** | **Performance** | Web page initial bundle boot time < 1.8s; hash-tab switching latency < 100ms. |
| **NFR-02** | **Concurrency** | API Gateway handles minimum 100 concurrent clinician requests with < 200ms latency. |
| **NFR-03** | **Data Integrity** | Zero data loss on daily ABA trial increments with local offline caching fallbacks. |
| **NFR-04** | **Security** | TLS 1.3 encryption in transit; Bcrypt password storage; JWT token expiry enforcement. |
| **NFR-05** | **Availability** | 99.9% uptime for therapy session collection during center working hours (08:00 - 19:00). |
| **NFR-06** | **Usability & A11y** | WCAG 2.1 AA compliant contrast ratios; adaptive responsive layouts for tablet touchscreens. |

---

## 6. Requirements Traceability Matrix (RTM)

| Business Objective (BRD) | Functional Requirement (FRD) | Target Verification |
| :--- | :--- | :--- |
| **OBJ-01 (Assessments)** | FR-THE-03, FR-THE-04, FR-THE-05, FR-THE-08 | Automated scoring in Milestones, Barriers, and EESA. |
| **OBJ-02 (Caseload Capacity)** | FR-DIR-01, FR-DIR-02, FR-ADM-02 | Center capacity bar and conflict-free room scheduling. |
| **OBJ-03 (IEP Delivery)** | FR-DIR-06, FR-THE-09, FR-PAR-03 | Digital submission, BCBA-D approval queue, and parent view. |
| **OBJ-04 (DPDP Compliance)** | FR-SEC-03, FR-SEC-04, FR-NOT-01 | Statutory consent gate and immutable MySQL audit logs. |
| **OBJ-05 (Parent Inclusion)** | FR-PAR-01, FR-PAR-04, FR-THE-10 | Same-day parent carryover note and real-time graph updates. |
