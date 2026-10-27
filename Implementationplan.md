# ROH ERP — Implementation Plan

Written 19 Oct 2026 from the full review of the app: the clinical assessments, all four portals' workflows, and the technical, privacy and security foundations. Every finding from that review is listed below with its status. **Updated 27 Oct 2026 with your answers** (see "Decisions" at the end). Say **proceed** to start.

**Status key:** ✅ done and live · 🟡 done, in an open PR · ⏸ built, on hold · ⬜ to do · ⏭ later (your call) · ✖ dropped · ❓ still open

**Size key:** S = under half a day · M = 1–2 days · L = 3+ days

---

## 0. Already done (for reference)

| Item | Where |
|---|---|
| Every dead button wired to real data (about 30 controls) | ✅ PR #7 |
| Admin portal trimmed; Switch Portal removed; neutral director name | ✅ PR #8 |
| Error tallies no longer counted as independent successes | ✅ PR #9 |
| Mastery = governance rule (80% across 3 consecutive sessions) | ✅ PR #9 |
| Parent prompt chart, director heatmap scales, caseload bars, stopwatch seconds | ✅ PR #9 |
| Parents can't edit sessions; therapists limited to their own sessions and caseload | ✅ PR #9 |
| Plain-text password matching removed | ✅ PR #9 |
| New accounts get a one-time password and must change it | ✅ PR #9 |
| Consent per correct child, read from the server, can be withdrawn | ✅ PR #9 |
| Encrypted DB connection, nightly backups, startup column migrations | ✅ PR #9 |
| Notification centre Back/close; no Start button; 5-minute reminders; director notified on completion | 🟡 PR #11 |
| Data Sheet opens the student directly; every portal no longer runs twice | 🟡 PR #11 |
| Full VB-MAPP Barriers (24), Transition (18), EESA (100), MSWO preference | 🟡 PR #10 — to be merged (see V1) |

---

## Phase 2 — Make it work for a real family (workflows)

Goal: a new child can be enrolled, assigned, worked with and followed by their parent without any seeded data.

### 2.1 Admin — enrolment and accounts

| ID | Item | Size | Status |
|---|---|---|---|
| A1 | **Create parent accounts and link them to a child** (UI + `link_parent_to_student`; sets `students.parent_user_id`; one parent → several children; a second guardian login) | M | ⬜ |
| A2 | **Assign therapists to a student** from admin/director (primary therapist + additional). The UI uses the existing `assign_student_therapist`; the therapist is notified. | M | ⬜ |
| A3 | Intake saves every field it asks for: phone, email, address, secondary diagnoses, application date, language. Needs new `students` columns via the migration list. | M | ⬜ |
| A4 | Remove silent defaults: gender "Male", blood group "O+", DOB 2019-01-01, diagnosis "ASD Level 2". These become required or "Not recorded". Replace the hint text "Value" with real examples. | S | ⬜ |
| A5 | **Bug:** intake medical-history answers are lost (app keys ≠ server keys). Align them and add the missing seizure-protocol and paediatrician fields. | S | ⬜ |
| A6 | **Bug:** guardian phone number lost (`phone_number` vs `phone`). Emergency contacts need a phone number. | S | ⬜ |
| A7 | Student edit covers DOB, diagnosis, language and therapist, not just name, program and status. | S | ⬜ |
| A8 | Admin dashboard: Email/Phone columns come from the primary guardian; remove the age fallback "10". | S | ⬜ |
| A9 | Archive students instead of hard delete (keeps clinical history; see 5.4). | M | ⬜ |
| A10 | Director calendar: server-side conflict check, including overlapping times, not just identical start times. | S | ⬜ |
| A11 | Center name and portal title (Settings) actually brand the app header, login and PDFs. | S | ⬜ |

### 2.2 Director — supervision and governance that's enforced

| ID | Item | Size | Status |
|---|---|---|---|
| D1 | `sign_off_iep` / `request_iep_revision` only from the correct status (no re-signing an Active plan). | S | ⬜ |
| D2 | IEPs get a review date and expiry; dashboard flags plans due for review. | M | ⬜ |
| D3 | **Reassessment reminders** from `reassessment_frequency` (e.g. every 6 months after the last VB-MAPP test). | M | ⬜ |
| D4 | Capacity and caseload limits become real settings, replacing the hard-coded "30 students / 6 cases / 08:00–18:00" text. | S | ⬜ |
| D5 | Session scheduling conflict check: overlapping times, room double-booking, **student double-booking**. | M | ⬜ |
| D6 | Mobile bottom bar includes Master Schedule and Settings (now drawer-only). | S | ⬜ |
| D7 | **Bug:** appointment type "staff consultation" shows as "diagnostic intake" after reload. | S | ⬜ |
| D8 | Time sorting everywhere by real time, not "hh:mm AM" text: SQL `ORDER BY` and the remaining lists (the therapist list is fixed in PR #11). | S | ⬜ |
| D9 | `require_two_therapists` → inter-observer agreement (IOA) checks; see T6. | M | ⏭ later |
| D10 | `dual_signoff_crisis` → behaviour plans that need two sign-offs; see T8. | M | ⏭ later |

### 2.3 Therapist — daily session workflow

| ID | Item | Size | Status |
|---|---|---|---|
| T1 | Mark a session **Absent / No-show / Cancelled** (with reason); attendance feeds parent and director views. | S | ⬜ |
| T2 | **Session notes** (short SOAP-style note) on completion, visible to the director; a parent-safe summary is optional. | M | ⬜ |
| T3 | Link each daily data entry to its session (`session_id`). | S | ⬜ |
| T4 | **Trial recording for Listener, Tact and VP/MTS** (today only Manding can be entered). | L | ⬜ |
| T5 | Therapists see the director's IEP revision notes on the IEP page, not just in the notification. | S | ⬜ |
| T6 | IOA: a second observer records the same trials; agreement % stored. | M | ⏭ later |
| T7 | **Offline data entry:** data sheets, ABC data and session notes can be recorded without internet, stored encrypted on the device, and synced automatically when back online, with a visible "waiting to sync" count and conflict handling. | L | ⬜ |
| T8 | Behaviour plan (BRP) becomes structured: operational definition, function, replacement behaviour, antecedent and consequence strategies, crisis steps, review date. | M | ⬜ |
| T9 | ABC data: operational definitions for each behaviour; a summary of A→B→C patterns. | M | ⬜ |
| T10 | Remove name-guessing fallbacks (student ids guessed from names in the assessment and data-sheet pages); dead `ReinforcerQueries`. | S | ⬜ |
| T11 | Manding sheet labels: FP = Full Physical, PP = Partial Physical, FM/FV = Full Model / Full Verbal, PM/PV = Partial Model / Partial Verbal, shown as on-screen explanations. | S | ⬜ |
| T12 | **Correct what counts as independent.** "Vocal" is independent only when the child requests **spontaneously, without any prompt**. Today every "Vocal" tally counts as an independent success (set in PR #9). The sheet needs a separate *spontaneous* mark, and only those count as success. | M | ⬜ — needs the clinic's original sheet (Q1) |
| T13 | Meaning of F3, F5, F6 and the second "F6", taken from the clinic's original data sheet. | S | ❓ Q1 |

### 2.4 Parent — sees the right things, clearly

| ID | Item | Size | Status |
|---|---|---|---|
| P1 | **Parents see only approved IEPs** (not Pending or Returned drafts). | S | ⬜ |
| P2 | **Hide internal clinical notes and raw behaviour notes** from parents; show a parent-safe session summary instead. | S | ⬜ |
| P3 | Parents with several children can switch between them (today only the first child shows). | M | ⬜ |
| P4 | Sessions matched to the child by id, not by name text. | S | ⬜ |
| P5 | **IEP Goals tab** shows the real approved goals and progress (today a static placeholder). | M | ⬜ |
| P6 | **Home programme:** therapist writes 1–3 home practice tips per week; parent can tick "practised". | M | ⬜ |
| P7 | Parent appointment requests start as "Requested", and the director confirms (today auto-confirmed). | S | ⬜ |
| P8 | Notification preferences are honoured by the server, not just stored on the phone. | S | ⬜ |
| P9 | **Parent–therapist messaging:** one conversation per child between the parent and the child's therapists (the director can see it); text plus read receipts; notifications; nothing deleted (kept for the record); director can mute a thread. | L | ⬜ |
| P10 | Download the child's progress report as PDF. | S | ⬜ |

### 2.5 Notifications that are missing today

| ID | Event → who | Status |
|---|---|---|
| N1 | Session cancelled or deleted → parent + therapist | ⬜ |
| N2 | Session completed → parent (optional, per preference) | ⬜ |
| N3 | Admin books an appointment → the attendee | ⬜ |
| N4 | Parent cancels an appointment → director | ⬜ |
| N5 | Student assigned → therapist (the existing call has its arguments in the wrong order) | ⬜ |
| N6 | IEP review due / reassessment due → therapist + director | ⬜ |

---

## Phase 3 — Assessments to the published standard

| ID | Item | Status |
|---|---|---|
| V1 | 24 barriers, 18 transition areas, 100-item EESA feeding Echoic, MSWO preference, score validation. **Bring PR #10 up to date with main and merge it.** The protocol wording, EESA items, score bands and Echoic table stay as placeholders in `assets/vbmapp/protocol_content.json` until the centre's licence arrives; then the centre fills them in. | ⬜ (licence in progress) |
| V2 | Trial recording for Listener/Tact/VP | moved to T4 |

---

## Phase 4 — IEP quality, autism-sensitive language and accessibility

### 4.1 IEP

| ID | Item | Size | Status |
|---|---|---|---|
| I1 | **SMART goals:** each goal has a baseline, target, mastery criterion, measurement, responsible person and target date. | M | ⬜ |
| I2 | Goals suggested from the child's latest milestone gaps and barriers (therapist picks and edits). | M | ⬜ |
| I3 | Goals for all domains, not just Manding and Tacting; keep ½ milestone scores (not rounded to integers). | S | ⬜ |
| I4 | Use the latest test number's scores, not the newest database row. | S | ⬜ |
| I5 | Goal progress on the IEP comes from daily data (mastered / in progress / not started). | M | ⬜ |

### 4.2 Language (respectful, plain, consistent)

| ID | Item | Status |
|---|---|---|
| L1 | Replace the remaining "Stagnation / Sentinel" wording everywhere, including settings and old appointment titles. | ⬜ |
| L2 | "Problem Behaviour" → "Behaviours of concern"; review the intake questions for deficit framing. | ⬜ |
| L3 | **Parent portal in plain language:** no "Manding/Tacting/Echoic/BCBA/Clinical Tracking Station" without an explanation. Add a short glossary. | ⬜ |
| L4 | Barrier names use the published neutral style (in PR #10). | ⬜ with V1 |
| L5 | Preferred terms: keep the current wording; no further terminology changes beyond L1–L3. | ✅ decided |

### 4.3 Accessibility (WCAG 2.1 AA target)

| ID | Item | Status |
|---|---|---|
| X1 | Screen-reader labels on icons, buttons, charts and status chips (none today). | ⬜ |
| X2 | Minimum text size 12 px (body 14); there are about 225 uses of 8–11 px now. | ⬜ |
| X3 | Fix low-contrast hint/disabled text (2.3:1 → at least 4.5:1). | ⬜ |
| X4 | Status never shown by colour alone (add icon or text). | ⬜ |
| X5 | Respect the phone's text-size setting without breaking layouts. | ⬜ |
| X6 | Tap targets at least 44×44; reduced-motion support. | ⬜ |

### 4.4 Languages and formats

| ID | Item | Status |
|---|---|---|
| F1 | One date style everywhere, **dd/MM/yyyy** (today six formats, including US MM/dd), and one time style. | ⬜ |
| F2 | Translation framework. | ✖ English only |
| F3 | Languages beyond English. | ✖ English only |

---

## Phase 5 — Safety, privacy and reliability (remaining)

### 5.1 Security hardening

| ID | Item | Size | Status |
|---|---|---|---|
| S1 | **Stop leaking error traces:** malformed requests currently return an HTML stack trace with server paths. Use JSON errors and never send `err.message`. | S | 🟡 step 1 PR |
| S2 | **Rate limiting** on login and the API; generic login errors (today they reveal whether an email exists). | S | 🟡 step 1 PR |
| S3 | Only POST can change data (today GET requests can perform writes, and tokens can end up in URLs and logs). | S | 🟡 step 1 PR |
| S4 | Security headers (Helmet: HSTS, CSP); CORS never falls back to `*`. | S | 🟡 step 1 PR |
| S5 | Swagger API docs and the version banner off in production. | S | 🟡 step 1 PR |
| S6 | Shorter sessions: 30-day token → e.g. 8–12 h plus refresh; idle timeout on shared centre devices. | M | 🟡 step 1 PR |
| S7 | Mobile apps keep the token in secure storage (Keychain/Keystore), not plain preferences. | S | 🟡 step 1 PR |
| S8 | Password reset: an admin can't reset another admin or director, or their own account; `logout_all_devices` validates its target. | S | 🟡 step 1 PR |
| S9 | Strip debug logging of API URLs and response bodies from release builds. | S | 🟡 step 1 PR |
| S10 | **Demo accounts with public passwords:** remove from CLAUDE.md and lock or rotate them after the demo; make the GitHub repo private. | S | ⏭ waiting for your word (Q8) |
| S11 | Seed/reset/demo scripts refuse to run against the production database. | S | 🟡 step 1 PR |

### 5.2 Privacy (India DPDP Act 2023)

| ID | Item | Size | Status |
|---|---|---|---|
| R1 | **Consent gate on the server:** the admin can create the child's record and the parent's login, but **no assessments, data sheets, sessions or IEPs can be recorded until the parent has given consent in the app.** Withdrawing consent stops new recording the same way; existing records are kept. Staff see a clear "Waiting for parent consent" badge. | M | ⬜ — please confirm the reading (Q9) |
| R2 | **Complete data export** for a child: every table, not just 3; available to the director and on parent request. | M | ⬜ |
| R3 | Parent requests: correction and erasure requests logged and tracked to completion. | M | ⬜ |
| R4 | Retention: **records are kept indefinitely** (archived, never auto-deleted) until you set a period. Only old notifications and used password-reset requests are purged. | S | ⬜ (period not decided yet) |
| R5 | Audit gaps: guardian deletes, emergency contacts, notification reads; **audit reads** of medical and IEP data. | S | ⬜ |
| R6 | **Audit log viewer** for admin/director (filters by person, child, action, date). | M | ⬜ |
| R7 | Less personal data in audit text and notification titles (ids, not names and emails). | S | ⬜ |
| R8 | **Encrypt sensitive fields at rest:** diagnosis, medical history, medications, allergies and guardian contact details. AES-256 with the key outside the database; existing rows are migrated. | M | ⬜ |
| R9 | Hosting location: DreamHost is US-based; decide whether children's health data must stay in India. | — | ❓ Q12 (not sure yet) |

### 5.3 Reliability and performance

| ID | Item | Size | Status |
|---|---|---|---|
| P-1 | **Polling load:** today every open screen calls the server about every 3–4 s, and the full tables are re-sent each time. Slow down (e.g. 30–60 s), pause when the app is in the background, fetch only changes, add pagination. | M | 🟡 step 1 PR |
| P-2 | Timers stop on sign-out (they keep running today). | S | 🟡 step 1 PR |
| P-3 | The app shows real errors: the API layer distinguishes signed-out / forbidden / server error / offline instead of showing empty data. | M | ⬜ |
| P-4 | **Off-server backup copy** (weekly download or cloud storage) and a tested restore. | S | 🟡 step 1 PR |
| P-5 | Uptime monitoring and error alerts (e.g. a free uptime checker plus pm2 log alerts). | S | ⬜ |
| P-6 | **Push notifications** when the app is closed (messages, IEP decisions, session changes) via APNs/Firebase, plus **TestFlight / App Store distribution** so installs no longer expire every 7 days. Starts once the paid Apple Developer account exists. | M | ⬜ (waiting for the account) |

### 5.4 Code health

| ID | Item | Size | Status |
|---|---|---|---|
| C1 | **Automated tests:** a backend permission matrix (who can call what), mastery/progress unit tests, key widget tests. | L | ⬜ |
| C2 | **CI on GitHub:** analyze + tests on every PR. | S | ⬜ |
| C3 | Proper numbered migrations (beyond the startup column list). | M | ⬜ |
| C4 | Split the 2,000-line `server.js` into route modules with shared auth middleware. | L | ⬜ |
| C5 | One state-management and HTTP approach: remove the unused Riverpod/dio path and the duplicate `deploy/backend/server.js` (the offline code is rebuilt properly under T7). | M | ⬜ |
| C6 | Repo clean-up: backup tarballs, APKs, logs, screenshots; a stale swagger spec. | S | ⬜ |
| C7 | Production on a proper domain (today it's `test.rohautism.org`). | S | ❓ Q14 (not sure yet) |

---

## Phase 6 — Centre operations (larger features)

| ID | Item | Size | Status |
|---|---|---|---|
| O1 | Attendance register and monthly attendance reports | M | ⬜ |
| O2 | Fees, invoices and payment records | L | ✖ not needed |
| O3 | Staff leave and availability (feeds scheduling) | M | ⬜ |
| O4 | Document storage: Aadhaar, birth certificate, medical reports (encrypted, access-controlled) | L | ⬜ |
| O5 | Reports: caseload, attendance, progress by therapist and domain; CSV/PDF export | M | ⬜ |
| O6 | Recurring session templates (e.g. Mon/Wed/Fri 10:00 for 12 weeks) | M | ⬜ |
| O7 | Enquiry and waitlist pipeline (the empty "Admissions" tab) | M | ⬜ |

---

## Proposed order

1. **Quick safety pass** — 5.1 (S1–S9, S11), P-1/P-2 polling load, P-4 off-server backup. *About 2–3 days.*
2. **VB-MAPP and data accuracy** — V1 (merge PR #10), T11, and T12/T13 once the original sheet arrives. *About 2 days.*
3. **Real families** — A1–A8, R1 consent gate, P1–P5, P7–P8, N1–N6. *About 1–1.5 weeks.*
4. **Therapist day** — T1–T5, T8–T10, D1–D8, then **T7 offline entry**. *About 2 weeks.*
5. **Parent–therapist messaging** — P9 and P6 home programme. *About 1 week.*
6. **IEP, language, accessibility** — I1–I5, L1–L4, X1–X6, F1. *About 1–2 weeks.*
7. **Privacy and code health** — R2–R8 (including R8 encryption), C1–C6. *About 1–2 weeks.*
8. **Operations** — O1, O3–O7 as you prioritise. **Push notifications and App Store (P-6)** as soon as the Apple account exists.

Each step ships as its own PR, is tested locally, and goes live only when you say so.

---

## Decisions (your answers, 27 Oct)

| # | Question | Answer → effect on the plan |
|---|---|---|
| Q1 | Manding columns | FP / PP / FM-FV / PM-PV defined (T11). "Vocal" is independent only when spontaneous and unprompted (T12). **Still open:** F3, F5, F6 and the second F6. Please share a photo of the clinic's original data sheet. |
| Q2 | VB-MAPP licence | Being obtained. **Proceed with VB-MAPP:** merge PR #10 with placeholder protocol content (V1). |
| Q3 | IOA and dual sign-off | Later (D9, D10, T6 ⏭). |
| Q4 | Languages | English only (F2, F3 ✖). |
| Q5 | Offline data entry | Yes. Build it properly (T7). |
| Q6 | Parent–therapist messaging | Yes (P9). |
| Q7 | Terminology | Current wording is fine (L5 ✅). |
| Q8 | Lock demo accounts / private repo | Not yet; you'll say when (S10 ⏭). |
| Q9 | Recording before consent | **No.** Nothing clinical is recorded until the parent consents (R1). *Confirm:* withdrawal also stops new recording but keeps existing records. |
| Q10 | Retention | Keep always, for now (R4). |
| Q11 | Encrypt sensitive fields | Yes (R8). |
| Q12 | Hosting in India | Not sure yet (R9 ❓). |
| Q13 | Paid Apple Developer account | Yes. Push notifications and App Store / TestFlight follow once it exists (P-6). |
| Q14 | Production web address | Not sure yet (C7 ❓). |
| Q15 | Fees and invoices | No (O2 ✖). |

**Still open:** Q1 (F3/F5/F6, original sheet), Q9 (confirm withdrawal rule), Q12 (hosting), Q14 (domain). None of these blocks step 1.
