# Executive Status Report: ROH-ERP Application

**Project:** Ray of Hope – Autism Center ERP System  
**Date:** October 6, 2026  
**Document Type:** Project Status Update & Roadmap  
**Prepared For:** Executive Management / Leadership  

---

## 1. Executive Summary
The ROH-ERP platform is designed to digitize clinical operations, behavior tracking, assessments, and parent-therapist communication across four user roles: **Admin, Director, Therapist, and Parent**.

At present:
* The **Frontend user interfaces and portal layouts are ~90% complete**, reflecting all clinical workflows and designs.
* The **Database schema & API Gateway architecture have been created** on PostgreSQL / Node.js.
* Active focus has shifted to **Backend business logic, real-time clinical data persistence, and dynamic, automated graph generation** driven directly by assessment and session records.

---

## 2. Key Achievements & What Has Been Done So Far

### 🎨 Frontend & User Interface (Mostly Completed)
1. **Multi-Role Portals Built:**
   - **Admin Portal:** Student & therapist management, profile creation, session scheduling, IEP review logs, and system settings.
   - **Director Portal:** Clinical oversight, caseload monitoring, IEP goal approvals/returns, and institutional reports.
   - **Therapist Portal:** Complete clinical workbench including Timetable, VB-MAPP suite, IEP target formulation, and the 7-tab Daily Data Sheet.
   - **Parent Portal:** Mobile/web view for parents to review child progress, daily takeaway reports, and session summaries.
2. **Clinical Assessment Modules (UI & Scoring Grids):**
   - VB-MAPP Milestone Assessment (Levels 1, 2, 3 across all 16 domains).
   - Barriers Assessment (24 learning barrier evaluations with 0–4 scale).
   - Transition Assessment (18 educational readiness categories).
   - EESA (Early Echoic Skills Assessment – Groups 1 & 2).
   - Preference Assessment (Reinforcer hierarchy: Edibles, Toys, Social, Activities).
3. **Daily Data Sheet Workbench (7 Clinical Sheets):**
   - Live DTT trial logging (`+`, `-`, `P`), Mand frequency tracking, ABC behavior logging, and Skill acquisition registers.

### 🗄️ Backend Foundation & Infrastructure (Initialized)
1. **Relational Database Design:**
   - PostgreSQL schema designed for students, users/therapists, timetable sessions, IEP targets, and assessment logs.
2. **Core API Gateway & Authentication:**
   - Node.js / Express backend server running on port 8000.
   - JWT-based authentication and role-based route guards.
   - Mock/simulated fallback data cleaned up to prepare for genuine database writes.

---

## 3. What Is Currently Under Development & In Progress

### ⚙️ 1. Dynamic Assessment & Progress Graphs (High Priority)
* **Status:** Under active development.
* **Goal:** Eliminate static charts and connect all visual graphs directly to raw assessment data.
* **Details:**
  - **Milestone & Barrier Cumulative Grids:** Automatically color-coding test grids (Test 1 through Test 4) based on stored numerical scores.
  - **Mand & Acquisition Graphs:** Generating longitudinal trend lines and trial-to-mastery curves directly from session inputs in the Daily Data Sheet.

### 💾 2. End-to-End Data Persistence & Live Backend Logic
* **Status:** In progress.
* **Details:**
  - Hooking up all form submissions (student intake, IEP additions, session notes) directly to the database.
  - Ensuring real-time synchronization so that session updates entered by a Therapist instantly reflect in the Director and Parent portals.

---

## 4. Next Steps & Near-Term Roadmap

| Phase | Milestone / Deliverable | Status |
| :--- | :--- | :--- |
| **Phase 1** | Complete remaining backend endpoints for VB-MAPP scoring & IEP workflow | **In Progress** |
| **Phase 2** | Finalize automated calculation engine for real-time graph rendering | **In Progress** |
| **Phase 3** | End-to-End integration testing across Admin, Director, Therapist & Parent roles | **Upcoming** |
| **Phase 4** | User Acceptance Testing (UAT) with clinical therapists & final production deployment | **Upcoming** |

---

## 5. Summary for Management
The visual and interactive foundation of the platform is solid and fully aligned with clinical specifications. The current technical sprint focuses on the data engine—ensuring every trial recorded by a therapist automatically saves to the database and recalculates student progress graphs without any manual charting overhead.
