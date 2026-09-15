# Ray of Hope (ROH-ERP) — Complete Manual Testing & Demo Acceptance Checklist

> **Purpose:** Pre-demo testing guide for a 1-month external pilot.  
> **Environment:** Flutter Web / Node.js Backend (`http://localhost:8000`) / MySQL (`roh_erp`)  
> **Active Preserved Credentials:**
> - **System Administrator:** `admin@roh.com` / `admin123`
> - **Clinical Director:** `director@roh.com` / `director123`

---

## 🎯 Quick Start Test Workflow (Order of Operations)

Because the database was completely wiped, follow this natural testing flow:
1. **Log in as Admin** $\to$ Create 1 Therapist and 1 Parent account.
2. **Log in as Admin** $\to$ Enroll a new Student and assign them to the Parent and Therapist.
3. **Log in as Therapist** $\to$ Create Daily ABA Data Sheet and Draft a new IEP.
4. **Log in as Director** $\to$ Verify the notification, inspect the IEP, and electronically sign off.
5. **Log in as Parent** $\to$ Verify the approved IEP notification, view reports, and book a conference.
6. **Log in as Director** $\to$ Verify conference appointment notification and manage schedule.

---

## 📋 Comprehensive CRUD Testing Checklist

### 1. Authentication & Security
- [ ] **Admin Login:** Log in with `admin@roh.com` / `admin123`. Verify redirection to `/admin`.
- [ ] **Director Login:** Log in with `director@roh.com` / `director123`. Verify redirection to `/director`.
- [ ] **Invalid Credentials Test:** Attempt login with wrong password. Verify user-friendly error message.
- [ ] **Role Protection (RBAC):** Try accessing director routes as therapist or vice-versa; ensure access is denied.
- [ ] **Change Password:** Test changing password from Profile menu; verify new password works.
- [ ] **Password Reset Request:** Request a password reset from the login screen; verify request appears in Admin's pending resets panel.

---

### 2. User & Staff Management (CRUD) — *Admin Role*
- [ ] **[CREATE] Add Therapist:**
  - Navigate to Staff / Therapists $\to$ "Add New Therapist".
  - Fill: Name (`Dr. Sarah Lee`), Email (`therapist@roh.com`), Password (`therapist123`), Phone.
  - Submit and verify therapist appears in table with status `Active`.
- [ ] **[CREATE] Add Parent:**
  - Add user with role `Parent` (`Mr. John Wilson`, `parent@roh.com`, `parent123`).
- [ ] **[READ] Staff Listing:**
  - Verify filters (search by name, filter by status `Active`/`Inactive`).
- [ ] **[UPDATE] Staff Details:**
  - Edit phone number or name of a therapist; verify changes persist after page refresh.
- [ ] **[DELETE/DEACTIVATE] Deactivate Staff:**
  - Toggle status to `Inactive` or delete test user; verify deactivated user cannot log in.

---

### 3. Student & Client Management (CRUD) — *Admin / Director*
- [ ] **[CREATE] Student Admission / Intake:**
  - Navigate to Students $\to$ "Add New Student".
  - Enter First Name (`Alex`), Last Name (`Sam`), DOB, Gender, Blood Group.
  - Link to Parent (`Mr. John Wilson`).
  - Add primary diagnosis (`Autism Spectrum Disorder - Level 2`).
  - Save and verify new Student ID generated.
- [ ] **[READ] Student Directory & Dossier:**
  - Verify student appears in both Grid and List view.
  - Click on student card to view full dossier (Demographics, Medical, IEP history).
- [ ] **[UPDATE] Student Profile:**
  - Update address, emergency contact phone, or secondary diagnosis; verify update succeeds.
- [ ] **[UPDATE] Medical History & Medications:**
  - Add allergy info (e.g. `Peanut allergy`) and pediatric doctor details.
  - Add a medication entry (`Melatonin 2mg`); verify it saves to `medications` / `medical_histories`.
- [ ] **[DELETE] Archive / Delete Student:**
  - Test deleting a draft/dummy student; verify student and cascading records are removed.

---

### 4. ABA Clinical Data Sheets (CRUD) — *Therapist Role*
- [ ] **[CREATE] Record Daily Data Sheet:**
  - Log in as `therapist@roh.com`.
  - Select student `Alex Sam` $\to$ "New Daily Data Sheet".
  - Log discrete trials across domains:
    - **Manding (Requests):** 8/10 independent (+), 2 prompted.
    - **Tacting (Labeling):** 9/10 independent (+).
    - **Motor Imitation:** 10/10 independent.
  - Add session clinical notes.
  - Submit and verify success toast.
- [ ] **[READ] Historical Data Sheets:**
  - View historical trial sheets for student; verify percentages and prompt levels render correctly.
- [ ] **[UPDATE] Edit Session Entry:**
  - Update notes or score on today's sheet; verify revision saves.

---

### 5. VB-MAPP Assessments (CRUD) — *Therapist / Director*
- [ ] **[CREATE] Start VB-MAPP Evaluation:**
  - Navigate to Assessments $\to$ VB-MAPP Milestone Assessment.
  - Score domains: Milestones (Levels 1-3), Barriers, Transition.
  - Save assessment draft.
- [ ] **[READ] VB-MAPP Radar / Grid View:**
  - Inspect color-coded visual scoring grid; ensure scores match inputs.
- [ ] **[UPDATE] Update Domain Score:**
  - Re-evaluate a milestone and update score; verify cumulative total recalculates.

---

### 6. IEP (Individualized Education Program) Treatment Plans (CRUD) — *Therapist & Director*
- [ ] **[CREATE] Draft Q4 IEP Plan (Therapist):**
  - Therapist creates new IEP: Title `Q4 2026 Comprehensive ABA Intervention Plan`.
  - Enter Measurable Objectives, Baseline Scores, Target Completion Date.
  - Status: Set to `Pending Approval`.
  - **🔔 Notification Event 1:** Verify Director receives `IEP_SUBMITTED` alert.
- [ ] **[READ] IEP Listing:**
  - Director reviews pending IEPs under "IEP Reviews" tab.
- [ ] **[UPDATE & SIGN-OFF] Director Electronic Approval:**
  - Director opens the IEP, reviews goals, checks clinical governance mastery threshold (80%).
  - Click "Electronically Sign & Approve".
  - **🔔 Notification Event 2:** Verify Director sign-off updates status to `Active` and dispatches:
    - Notification to Parent: `REPORT_READY`
    - Notification to Therapist: `IEP_APPROVED`
- [ ] **[UPDATE] Revise IEP Goals:**
  - Test updating baseline or targets prior to final sign-off.
- [ ] **[DELETE] Delete Draft IEP:**
  - Verify only unapproved/draft IEPs can be deleted.

---

### 7. Appointments & Parent Conferences (CRUD) — *Parent & Director*
- [ ] **[CREATE] Parent Books IEP Conference:**
  - Log in as `parent@roh.com`.
  - Navigate to Appointments $\to$ "Book Conference with Director".
  - Select Date, Time Slot, and Reason (`Review Alex Q4 IEP Goals`).
  - Submit booking.
  - **🔔 Notification Event 3:** Verify Director receives `APPOINTMENT_SCHEDULED` notification.
- [ ] **[READ] Calendar & Schedule:**
  - Director views Appointments calendar; confirm new conference appears in the correct slot.
- [ ] **[UPDATE] Reschedule / Confirm Appointment:**
  - Director updates status to `Confirmed` or modifies meeting link/room.
- [ ] **[DELETE/CANCEL] Cancel Appointment:**
  - Test canceling appointment; verify status updates to `Cancelled`.

---

### 8. Parental Consent & DPDP Act Compliance — *Parent Role*
- [ ] **[CREATE] Submit Digital Consent:**
  - Parent opens pending consent dialog (e.g. `Clinical Data Sharing & Photo/Video Consent`).
  - Checks consent terms and submits electronic agreement.
  - Verify record is saved in `parental_consents` table.
- [ ] **[READ] Audit Trail (Admin):**
  - Admin inspects `audit_logs` $\to$ verify consent timestamp, IP, and user ID are recorded.

---

## 🔔 Real-Time Notifications Verification Matrix

| Event | Initiator Role | Action Taken | Target Recipient | Expected Notification Message | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **1. IEP Submission** | Therapist | Submits new IEP for review | **Director** | *"Action Required: New IEP Awaiting Approval"* | [ ] |
| **2. IEP Sign-Off** | Director | Electronically signs & approves IEP | **Parent** | *"Your Child's IEP Report is Ready for Review"* | [ ] |
| **3. IEP Approval** | Director | Electronically signs & approves IEP | **Therapist** | *"IEP Approved by Clinical Director"* | [ ] |
| **4. Parent Booking**| Parent | Books conference slot | **Director** | *"New Appointment Scheduled: Parent IEP Conference"* | [ ] |
| **5. Mark As Read** | Any | Clicks notification / "Mark as Read" | **Self** | Badge counter decrements; status = `Read` | [ ] |

---

## 💡 Demo Pilot Best Practices (1-Month Run)
1. **Backup Database Before Handover:**
   ```bash
   mysqldump -u root -pACAdev@123 roh_erp > /Users/acamedia/VINODH/ROH-ERP-APP/backup_demo_start.sql
   ```
2. **Restore if Testers Corrupt Data:**
   You can run `node clean_for_demo.js` at any time to return to this clean state!
