# Ray of Hope (ROH-ERP) — Complete Manual Testing & CRUD Acceptance Checklist

**Target Audience:** QA Engineers, Product Managers, Clinical Evaluators, Demo Testers  
**System Under Test:** Ray of Hope Autism Center ERP (`roh_erp`)  
**Frontend URL:** [http://localhost:8080](http://localhost:8080) (Flutter Web)  
**Backend API URL:** [http://localhost:8000](http://localhost:8000) (Node.js Express Gateway)  
**Database Engine:** MySQL 8.0 on `127.0.0.1:3306` (Database: `roh_erp`)  

---

## 🔑 Preserved Production Demo Credentials

The database has been completely emptied and sanitized, leaving only the two foundational administrative accounts active:

| Role | Username / Email | Password | Landing Route | Description |
| :--- | :--- | :--- | :--- | :--- |
| **System Administrator** | `admin@roh.com` | `admin123` | `/admin` | Full system control, user provisioning, security, audit logs |
| **Clinical Director** | `director@roh.com` | `director123` | `/director` | Clinical oversight, IEP sign-off, governance, conferences |

---

## 🧭 Golden Flow: Recommended Order of Testing

Because all student, clinical, and staff tables are initially clean, execute tests in this logical sequence:

```
[1. Admin Login] ──► [2. Create Therapist & Parent] ──► [3. Admit Student & Link Accounts]
                                                                   │
                                                                   ▼
[6. Director IEP Sign-Off] ◄── [5. Draft IEP & Submit] ◄── [4. Therapist Logs In]
        │
        ├─────────────────────────────┐
        ▼                             ▼
[7. Parent Receives Alert]    [8. Therapist Receives Alert]
        │
        ▼
[9. Parent Books Conference] ──► [10. Director Receives Alert & Confirms Slot]
```

---

## 📋 Comprehensive CRUD Testing Checklist

---

### Phase 1: Authentication, Session & Security

| ID | Module / Test Case | Role | Step-by-Step Test Procedure | Expected Result | Pass / Fail |
| :---: | :--- | :---: | :--- | :--- | :---: |
| **AUTH-01** | Admin Login | Admin | Enter `admin@roh.com` / `admin123` on login screen | Authenticates successfully, stores JWT, redirects to `/admin` dashboard | [ ] |
| **AUTH-02** | Director Login | Director | Enter `director@roh.com` / `director123` | Authenticates successfully, stores JWT, redirects to `/director` dashboard | [ ] |
| **AUTH-03** | Invalid Password | Any | Enter `admin@roh.com` with `wrongpass` | HTTP 401, displays red error toast: *"Invalid email or password"* | [ ] |
| **AUTH-04** | Role-Based Access Control | Admin | Try manually navigating to `/parent` or `/therapist` routes | Route guard kicks in; prevents unauthorized panel access | [ ] |
| **AUTH-05** | Password Change | Admin / Dir | Open profile menu $\to$ "Change Password" $\to$ enter old + new password | Password updates in DB; new password works on next login | [ ] |
| **AUTH-06** | Logout & Token Invalidation | Any | Click "Logout" from the navigation drawer | Clears session/local storage, invalidates token, routes to `/login` | [ ] |

---

### Phase 2: User & Staff Provisioning (Admin Panel)

*Prerequisite: Log in as `admin@roh.com` / `admin123`*

| ID | Action | Target Entity | Test Procedure | Expected Result | Pass / Fail |
| :---: | :---: | :--- | :--- | :--- | :---: |
| **USER-01** | **CREATE** | Therapist Account | Navigate to **Staff / Therapists** $\to$ Click **Add Therapist**.<br>• Name: `Dr. Sarah Lee`<br>• Email: `therapist@roh.com`<br>• Password: `therapist123`<br>• Phone: `+1 555-010-0003` | Success toast appears; therapist record inserted into `users` table with role `therapist` | [ ] |
| **USER-02** | **CREATE** | Parent Account | Navigate to **User Management** $\to$ Click **Add User**.<br>• Name: `Mr. John Wilson`<br>• Email: `parent@roh.com`<br>• Password: `parent123`<br>• Role: `Parent` | Record created with role `parent`; visible in parent user directory | [ ] |
| **USER-03** | **READ** | Staff Directory | Open Staff Table. Filter by role (`therapist`) and search by name (`Sarah`) | Grid filters instantly; displays status `Active` and phone details | [ ] |
| **USER-04** | **UPDATE** | Staff Profile | Click Edit on `Dr. Sarah Lee` $\to$ Update phone to `+1 555-999-8888` | Modal saves; updated phone number displays on screen and persists on reload | [ ] |
| **USER-05** | **UPDATE** | Status Toggle | Toggle a test user's status from `Active` to `Inactive` | Status updates in DB; inactive user is blocked from logging in | [ ] |
| **USER-06** | **DELETE** | Delete Dummy Staff | Create dummy user `temp@roh.com`, then click Delete with confirmation | Confirmation dialog warns user; record cleanly removed from database | [ ] |

---

### Phase 3: Student Intake & Medical Dossier (Admin / Director)

*Prerequisite: Therapist (`therapist@roh.com`) and Parent (`parent@roh.com`) have been created.*

| ID | Action | Target Entity | Test Procedure | Expected Result | Pass / Fail |
| :---: | :---: | :--- | :--- | :--- | :---: |
| **STU-01** | **CREATE** | Student Admission | Navigate to **Students** $\to$ Click **Admit Student**.<br>• First Name: `Alex`<br>• Last Name: `Sam`<br>• DOB: `2019-04-12`<br>• Gender: `Male`<br>• Blood Group: `O+`<br>• Parent: Select `Mr. John Wilson`<br>• Primary Diagnosis: `Autism Spectrum Disorder - Level 2` | Student ID generated; record linked to parent in database; student card appears in directory | [ ] |
| **STU-02** | **READ** | Student Grid & Search | Search `Alex` in student directory filter; toggle between Grid and List view | Card renders with diagnosis tag, age calculation, and assigned parent name | [ ] |
| **STU-03** | **READ** | Comprehensive Dossier | Click on student card to open detailed Student Dossier | Tabbed view opens showing Demographics, Clinical Goals, Medical History, and Attendance | [ ] |
| **STU-04** | **UPDATE** | Contact / Address | Edit student address: `104 Hope Lane, Suite 4B` $\to$ Click Save | Toast confirms update; new address reflected on dossier header | [ ] |
| **STU-05** | **CREATE** | Medical & Allergy Info | On Medical tab, add:<br>• Allergies: `Peanut allergy (Severe)`<br>• Pediatrician: `Dr. Robert Vance, MD`<br>• Emergency Contact: `Sarah Wilson (+1 555-444-3333)` | Data persists in `medical_histories` / `guardians` table | [ ] |
| **STU-06** | **CREATE** | Medication Record | Click **Add Medication** $\to$ Name: `Melatonin 2mg`, Schedule: `Nightly at 8:00 PM` | Medication row appears in active prescriptions list | [ ] |
| **STU-07** | **DELETE** | Remove Medication | Click Delete icon on a test medication entry | Medication row removed with confirmation toast | [ ] |
| **STU-08** | **DELETE** | Archive / Delete Student | Test deleting a test student profile | Student record and dependent child data removed gracefully | [ ] |

---

### Phase 4: ABA Daily Data Sheets & Discrete Trials (Therapist Panel)

*Prerequisite: Log in as `therapist@roh.com` / `therapist123`*

| ID | Action | Target Entity | Test Procedure | Expected Result | Pass / Fail |
| :---: | :---: | :--- | :--- | :--- | :---: |
| **ABA-01** | **CREATE** | Discrete Trial Session | Select student `Alex Sam` $\to$ Click **New Daily Data Sheet**.<br>Log trials across domains:<br>• **Manding:** 8 independent (+), 2 prompted (P)<br>• **Tacting:** 9 independent (+), 1 error (-)<br>• **Motor Imitation:** 10 independent (+)<br>• Add Session Clinical Note: *"High engagement with token economy."* | Sheet saves to `daily_data_sheets`; percentage scores calculate automatically (e.g. 80%, 90%, 100%) | [ ] |
| **ABA-02** | **READ** | Historical Trial Sheets | Navigate to **Session History** tab for student `Alex Sam` | Past sessions listed in reverse chronological order with date stamps and score badges | [ ] |
| **ABA-03** | **UPDATE** | Revise Session Notes | Open today's data sheet $\to$ Update therapist notes $\to$ Save | Changes saved; updated timestamp reflected | [ ] |
| **ABA-04** | **DELETE** | Discard Draft Sheet | Start a new sheet, click "Discard / Cancel" | System prompts confirmation; cancels without writing dirty data to database | [ ] |

---

### Phase 5: VB-MAPP Assessments (Therapist / Director)

| ID | Action | Target Entity | Test Procedure | Expected Result | Pass / Fail |
| :---: | :---: | :--- | :--- | :--- | :---: |
| **VBM-01** | **CREATE** | Milestone Assessment | Navigate to **Assessments** $\to$ **VB-MAPP** $\to$ New Assessment.<br>Score domains: Mand, Tact, Listener Responding, Visual Perceptual | Scores recorded per domain; cumulative score aggregates accurately | [ ] |
| **VBM-02** | **READ** | Radar / Visual Grid | Open student assessment visual summary | 16-domain visual grid/radar chart renders with color-coded milestone levels (Level 1, 2, 3) | [ ] |
| **VBM-03** | **UPDATE** | Milestone Re-test | Adjust a domain score based on reassessment (e.g. Tact: from 3.5 to 4.5) | Total score recalculates in real-time; updates persisted in `vb_assessments` | [ ] |

---

### Phase 6: IEP Treatment Plans & Approval Workflow (Therapist $\leftrightarrow$ Director)

*This is the core clinical workflow of the ERP.*

| ID | Action | Role | Test Procedure | Expected Result | Pass / Fail |
| :---: | :---: | :---: | :--- | :--- | :---: |
| **IEP-01** | **CREATE** | Therapist | Navigate to **IEP Reports** $\to$ **Create New IEP**.<br>• Title: `Q4 2026 Comprehensive ABA Plan`<br>• Measurable Goals: `1. Independent peer greeting, 2. Two-step instructions`<br>• Baseline: `20%`<br>• Target: `80% across 3 sessions`<br>• Status: Select **Pending Approval** $\to$ Submit | IEP saved with status `Pending Approval`.<br>🔔 **Notification Dispatched to Director** | [ ] |
| **IEP-02** | **READ** | Director | Log in as `director@roh.com` $\to$ Check notification drawer & IEP queue | Notification badge shows unread item: *"Action Required: New IEP Awaiting Approval"*. IEP appears in Pending Reviews | [ ] |
| **IEP-03** | **UPDATE** | Director | Open the pending IEP $\to$ Review goals against Clinical Governance Criteria (80% threshold) | Director review panel renders all targets, baseline metrics, and therapist notes | [ ] |
| **IEP-04** | **SIGN-OFF** | Director | Click **Electronically Sign & Approve**.<br>System stamps digital signature: `Dr. Sterling Vance (BCBA-D)` | IEP status updates to `Active`.<br>🔔 **Dual Notifications Dispatched**: 1 to Parent, 1 to Therapist | [ ] |
| **IEP-05** | **READ** | Therapist | Log in as `therapist@roh.com` $\to$ Inspect notifications | Unread notification present: *"IEP Approved by Clinical Director"* | [ ] |
| **IEP-06** | **READ** | Parent | Log in as `parent@roh.com` $\to$ Inspect notifications & IEP tab | Unread notification present: *"Your Child's IEP Report is Ready for Review"*. Parent can read the finalized PDF/dossier | [ ] |
| **IEP-07** | **DELETE** | Therapist / Dir | Attempt to delete an `Active` (approved) IEP | Deletion prevented or restricted; only draft/unapproved IEPs can be deleted | [ ] |

---

### Phase 7: Appointments & Conferences (Parent $\leftrightarrow$ Director)

| ID | Action | Role | Test Procedure | Expected Result | Pass / Fail |
| :---: | :---: | :---: | :--- | :--- | :---: |
| **APT-01** | **CREATE** | Parent | Log in as `parent@roh.com` $\to$ Navigate to **Appointments** $\to$ **Book Conference**.<br>• Select Date: Tomorrow<br>• Select Time Slot: `10:00 AM`<br>• Purpose: `Review Alex Q4 IEP Goals` $\to$ Confirm Booking | Booking created with status `Scheduled`.<br>🔔 **Notification Dispatched to Director** | [ ] |
| **APT-02** | **READ** | Director | Log in as `director@roh.com` $\to$ Open Appointments Calendar | Notification received: *"New Appointment Scheduled: Parent IEP Conference"*. Slot booked on calendar | [ ] |
| **APT-03** | **UPDATE** | Director | Open the appointment card $\to$ Add Google Meet link / Room 2 $\to$ Confirm | Status updates to `Confirmed`; parent dashboard reflects updated room info | [ ] |
| **APT-04** | **DELETE** | Parent / Dir | Click **Cancel Appointment** with cancellation reason | Appointment status transitions to `Cancelled`; slot is released | [ ] |

---

### Phase 8: Digital Consent & Regulatory Compliance (Parent & Admin)

| ID | Action | Role | Test Procedure | Expected Result | Pass / Fail |
| :---: | :---: | :---: | :--- | :--- | :---: |
| **CNS-01** | **CREATE** | Parent | Open pending **Parental Consent** dialog (e.g. `Photo/Video Therapy Documentation Consent`) $\to$ Accept terms $\to$ Sign digitally | Consent saved in `parental_consents` table with IP, device, and timestamp | [ ] |
| **CNS-02** | **READ** | Admin | Log in as `admin@roh.com` $\to$ Open **Audit Logs** | Immutable regulatory record verified: showing user ID, event type `CONSENT_RECORDED`, and timestamp | [ ] |

---

## 🔔 Real-Time Notification Verification Matrix

Verify each event triggers properly across browsers or browser windows:

```
┌───────────────────────────┬──────────────┬──────────────────┬─────────────────────────────────────────────────────────┬────────┐
│ Event Trigger             │ Initiator    │ Recipient        │ Expected In-App Notification Message                    │ Tested │
├───────────────────────────┼──────────────┼──────────────────┼─────────────────────────────────────────────────────────┼────────┤
│ 1. IEP Submission         │ Therapist    │ Director         │ "Action Required: New IEP Awaiting Approval"            │  [ ]   │
│ 2. IEP Electronic Sign-off│ Director     │ Parent           │ "Your Child's IEP Report is Ready for Review"           │  [ ]   │
│ 3. IEP Electronic Sign-off│ Director     │ Therapist        │ "IEP Approved by Clinical Director"                     │  [ ]   │
│ 4. Conference Booking     │ Parent       │ Director         │ "New Appointment Scheduled: Parent IEP Conference"      │  [ ]   │
│ 5. Notification Dismissal │ Any User     │ Self             │ Unread badge counter decrements by 1; item marks read   │  [ ]   │
└───────────────────────────┴──────────────┴──────────────────┴─────────────────────────────────────────────────────────┴────────┘
```

---

## 🛠️ Rapid Reset Tool for Demo Administration

If demo testers input dummy data, invalid entries, or you want to restart with a clean slate at any time during the 1-month trial, run this command in terminal:

```bash
cd /Users/acamedia/VINODH/ROH-ERP-APP/BACK-END
node clean_for_demo.js
```

This will instantly:
1. Truncate all 18 transactional tables back to 0 records.
2. Re-establish clean, verified `admin@roh.com` (`admin123`) and `director@roh.com` (`director123`) accounts.
3. Keep clinical governance configuration intact without breaking server operation.
