# Business Requirements Document (BRD)
## Ray of Hope Center for Autism — Clinical Enterprise Resource Planning (ROH-ERP)

---

### Document Control

| Attribute | Details |
| :--- | :--- |
| **Project Name** | Ray of Hope Center for Autism - Clinical Care & ERP System (ROH-ERP) |
| **Document Version** | 2.5.0 (Production Master) |
| **Status** | Approved / Baseline |
| **Author** | Senior Healthcare Systems Architect & Lead Clinical Informatics Analyst |
| **Target Audience** | Clinical Directors, Board of Trustees, Center Administrators, Software Engineers, Compliance Auditors |
| **Compliance Baseline** | India Digital Personal Data Protection (DPDP) Act 2023, BACB Guidelines, ISO 27001 Security Principles |

---

## 1. Executive Summary

### 1.1 Vision Statement
The **Ray of Hope Center for Autism (ROH)** is dedicated to delivering evidence-based clinical interventions (principally Applied Behavior Analysis — ABA, Speech Therapy, and Occupational Therapy) for autistic children and individuals with developmental differences. The **ROH-ERP** platform is an end-to-end, multi-portal healthcare Enterprise Resource Planning ecosystem that digitizes clinical assessments, daily ABA data collection, IEP (Individualized Education Plan) authoring, therapist timetable scheduling, and transparent parent engagement.

### 1.2 Purpose of this Document
This Business Requirements Document (BRD) establishes the business rationale, operational requirements, clinical compliance standards, and functional boundaries of the ROH-ERP software suite. It serves as the single source of truth for organizational stakeholders, product leadership, and engineering teams.

---

## 2. Business Problem & Opportunity

### 2.1 Current Operational Pain Points (Pre-ERP)
Prior to the implementation of ROH-ERP, autism intervention facilities commonly face significant operational frictions:
1. **Paper-Based Assessment Fragmentation**: Standardized assessment protocols (such as the 170-milestone VB-MAPP, 24-barrier analysis, and EESA) were administered across paper binders, leading to manual scoring errors, lost historical probes, and inability to visualize longitudinal gains.
2. **Scheduling Bottlenecks & Room Conflicts**: Complex clinical scheduling involving multi-disciplinary clinicians (BCBAs, RBTs, SLPs, OTs), specialized therapy rooms (Sensory Rooms, ABA Cabins), and student schedules resulted in accidental double-bookings or under-utilized therapeutic hours.
3. **Delayed IEP Reporting & Governance**: IEP goals drafted by therapists required physical hand-offs to the Clinical Director for audit and sign-off, creating weeks-long reporting delays for parents.
4. **Parent Disconnect & Carryover Loss**: Parents lacked real-time visibility into their child’s session progress, impeding home carryover of critical behavioral protocols.
5. **Data Privacy & Statutory Liability**: Unprotected handling of sensitive minor health records risked non-compliance with the Digital Personal Data Protection (DPDP) Act 2023.

### 2.2 Desired Future State
ROH-ERP bridges clinical delivery, facility operations, and family engagement into a unified, secure web and mobile ecosystem:
- **Instant Clinical Velocity**: 100% paperless administration of VB-MAPP assessments with automated scoring and visual multi-test progress graphing.
- **Intelligent Resource Scheduling**: Conflict-free allocation of therapists, student sessions, and clinical cabins with real-time operational status.
- **Strict Clinical Governance**: Granular Role-Based Access Control (RBAC) with digital signatures and approval queues for Clinical Directors.
- **Active Parent Inclusion**: Dedicated Parent Portal with secure daily session takeaways, real-time IEP goal mastery metrics, and DPDP-compliant consent management.

---

## 3. Business Objectives & Key Performance Indicators (KPIs)

| Objective Code | Business Objective | Target KPI / Success Metric |
| :--- | :--- | :--- |
| **OBJ-01** | **Eliminate Assessment Overhead** | Reduce the time required to administer, score, and graph VB-MAPP assessments by **70%**. |
| **OBJ-02** | **Optimize Center Caseload Capacity** | Maintain clinical utilization rate above **90%** of available therapy slots with zero room conflicts. |
| **OBJ-03** | **Accelerate IEP Delivery** | Compress IEP draft-to-approval cycle time from **21 business days to under 48 hours**. |
| **OBJ-04** | **Enforce Regulatory Privacy** | Achieve **100% digital auditability** and explicit guardian consent tracking under the DPDP Act 2023. |
| **OBJ-05** | **Enhance Parent Transparency** | Provide same-day clinical notes and objective mastery trendlines to **100%** of enrolled families. |

---

## 4. Stakeholder & Persona Analysis

The platform serves four primary user personas with distinct clinical, administrative, and legal responsibilities:

```
+-----------------------------------------------------------------------------------+
|                               ROH-ERP ECOSYSTEM                                  |
+-------------------+--------------------+---------------------+--------------------+
|  CLINICAL DIRECTOR|       ADMIN        |      THERAPIST      |       PARENT       |
|  (Lead BCBA-D)    | (Center Operations)| (BCBA / RBT / SLP)  | (Guardian)         |
+-------------------+--------------------+---------------------+--------------------+
| • Case Oversight  | • Student Intake   | • Daily ABA Sheets  | • Daily Summary    |
| • IEP Sign-Offs   | • Staff Rostering  | • VB-MAPP Scoring   | • IEP Goal Trends  |
| • Master Schedule | • Room Allocations | • Session Execution | • Meeting Requests |
| • Security Resets | • Accounts / Admin | • IEP Goal Targets  | • DPDP Consent     |
+-------------------+--------------------+---------------------+--------------------+
```

### 4.1 Persona Profiles

#### Persona 1: Clinical Director (BCBA-D)
- **Role**: Executive clinician responsible for clinical efficacy, BACB supervisory compliance, treatment plan authorization, and therapist mentorship.
- **Core Needs**: High-level clinical dashboards, caseload capacity overview, audit-ready IEP sign-off queue, master timetable scheduling, and oversight of administrative credential resets.

#### Persona 2: Center Administrator
- **Role**: Operational management managing admissions, student billing inquiries, therapist hiring records, and facility room availability.
- **Core Needs**: Comprehensive student enrollment wizard (medical records, emergency contacts, guardian dossiers), therapist management, executive calendar booking, and portal configuration.

#### Persona 3: Therapist / Clinician (BCBA, BCaBA, RBT)
- **Role**: Frontline healthcare professionals administering direct one-on-one ABA, speech, or sensory therapy.
- **Core Needs**: Daily timetable with student cabin locations, real-time ABA daily data collection sheets (+ / - / Prompt counters), digital VB-MAPP assessments (Milestones, Barriers, Transitions, EESA), and goal tracking.

#### Persona 4: Parent / Guardian
- **Role**: Family members of the enrolled student.
- **Core Needs**: Intuitive and non-intimidating mobile/desktop portal, transparent timetable of their child's therapy sessions, actionable daily carryover instructions, clinical trend graphs, and direct appointment requests with the Clinical Director.

---

## 5. Scope of the System

### 5.1 In-Scope Capabilities
1. **Multi-Portal Shell Architecture**: Distinct, role-guarded user interfaces for Director, Admin, Therapist, and Parent.
2. **Student Lifecycle Management**: Comprehensive enrollment, multi-guardian contact directories, detailed medical/medication histories, and dietary/allergy flags.
3. **Therapy Scheduling Engine**:
   - Master scheduling across rooms (Sensory Room A, Speech & Language Cabin 1, ABA Table 2, OT Gym).
   - Director-to-Therapist session assignment with auto-notification dispatch.
   - Status tracking (`Scheduled`, `Upcoming`, `In Progress`, `Completed`, `Cancelled`).
4. **Standardized Clinical Assessment Suite**:
   - **VB-MAPP Milestones Assessment**: Levels 1, 2, 3 across 16 language/learning domains (Mand, Tact, Echoic, Intraverbal, etc.).
   - **VB-MAPP Barriers Assessment**: 24 learning barriers evaluated on a 0–4 scale with longitudinal 4-test multi-colored grid graphing.
   - **VB-MAPP Transition Assessment**: 18 transition skills assessing educational placement readiness.
   - **Early Echoic Skills Assessment (EESA)**: Detailed syllable and vocalization sub-tests.
   - **Preference Assessment**: Systematic sampling and ranking of primary, secondary, and sensory reinforcers.
5. **Daily ABA Data Sheet**: Discrete trial teaching (DTT) counters, prompting levels, baseline probes, and clinical carryover takeaway notes.
6. **IEP Engine**: Multi-domain target formulation, baseline mastery criteria, therapist drafting, and Clinical Director authorization workflow.
7. **Statutory DPDP Compliance Engine**: Guardian digital consent gates, purpose-specification logging, and immutable audit trailing.
8. **Communication & Alerts**: In-app notification center, web audio chime engine, and real-time appointment dispatch.

### 5.2 Out-of-Scope (Future Enhancements)
- Automated commercial insurance claims clearinghouse billing (scheduled for v3.0).
- Third-party telehealth teleconference video streaming inside the browser.
- External wearable biometric sensor data ingestion.

---

## 6. Business Workflows & Process Models

### 6.1 Clinical Intake & Student Enrollment Workflow
```
[Parent Applies] 
       │
       ▼
[Admin Review & Intake] ──► Fills 3-Step Wizard (Demographics, Medical History, Guardians)
       │
       ▼
[Student Record Created] ──► Triggers DPDP Guardian Consent Notification to Parent
       │
       ▼
[Director Assessment Assignment] ──► Assigns Initial VB-MAPP Baseline to Lead BCBA
```

### 6.2 Session Scheduling & Execution Lifecycle
```
[Director / Admin Schedules Session]
       │
       ▼
[System Conflict Check: Therapist + Student + Cabin Available]
       │
       ▼
[Real-Time Notification Dispatched to Assigned Therapist]
       │
       ▼
[Therapist Timetable Updated]
       │
       ▼
[Therapist Clicks "Start Session"] ──► Opens Daily Data Sheet
       │
       ├── Records Discrete Trials (+ / - / Prompt Level)
       ├── Logs Clinical Notes & Behaviors
       └── Inputs "Daily Carryover Takeaway" for Home
       │
       ▼
[Session Status Marked "Completed"]
       │
       ▼
[Parent Portal Automatically Receives Daily Takeaway & Updated Graphs]
```

### 6.3 IEP Formulation & Dual-Custody Approval Workflow
```
[Therapist Drafts IEP Objectives]
       │
       ▼
[Internal Review & Probe Benchmarking]
       │
       ▼
[Submission to Director Clinical Attention Queue]
       │
       ├── Director Audits Clinical Targets & Mastery Velocity
       │
       ├── [Needs Revision] ──► Rejection with Feedback to Clinician
       │
       └── [Approved] ──► Digitally Signed by BCBA-D
                               │
                               ▼
               [Published to Parent Portal for Viewing]
```

---

## 7. Regulatory & Compliance Standards

### 7.1 Digital Personal Data Protection (DPDP) Act 2023 (India)
1. **Consent Prior to Processing**: The application explicitly mandates that parents/guardians must execute digital consent on behalf of the minor student covering:
   - Clinical and behavioral trial data collection.
   - Medical and psychiatric historical record retention.
   - Emergency disclosures for clinical safety.
2. **Right to Withdraw / Data Portability**: System architecture retains guardian rights to request data extracts and review audit trails.
3. **Immutable Audit Trails**: Every read, edit, delete, and credential change action is logged into the `audit_logs` table with actor ID, role, IP address, and timestamp.

### 7.2 Clinical ABA & BACB Standards
- Data sheets adhere to standard BACB (Behavior Analyst Certification Board) measurement principles (frequency, rate, duration, latency, and percentage of opportunities).
- Assessments mirror Dr. Mark Sundberg's standardized VB-MAPP protocol to maintain empirical validity for clinical diagnostic reviews.

---

## 8. Business Assumptions & Constraints

### 8.1 Assumptions
- Each enrolled child has at least one registered primary guardian with a valid email address.
- Center clinicians hold valid credentials (e.g., BCBA, BCaBA, RBT, or Licensed Psychologist) verified during onboarding.
- Internet connectivity is accessible across all therapy rooms and admin terminals.

### 8.2 Constraints
- **Client Deployment**: Cross-platform Flutter web application operating seamlessly across desktop displays (1920x1080 / 1600x1050) and mobile/tablet touchscreens (iPad, Android tablets).
- **Zero Data Loss**: Direct trial-by-trial collection must persist reliably without dropping session data points during intermittent network events.
