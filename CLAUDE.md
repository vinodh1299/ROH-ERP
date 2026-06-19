# ROH ERP – CLAUDE.md
## Ray of Hope Center for Autism — Flutter ERP

This file is the **resume checkpoint** for Claude. Read it every time before continuing work on this project.

---

## Project Overview

A multi-platform Flutter ERP (web, Android, iOS, Windows, macOS) for the **Ray of Hope Center for Autism**.

Three user roles with separate dashboards:
| Role | Login | Password | Section folder |
|---|---|---|---|
| Director | director@roh.com | director123 | `lib/features/director/` |
| Therapist | therapist@roh.com | therapist123 | `lib/features/therapist/` |
| Parent | parent@roh.com | parent123 | `lib/features/parent/` |

---

## Folder Structure

```
roh_erp/
├── .env                        # DB / API secrets (never commit)
├── CLAUDE.md                   # ← you are here
├── pubspec.yaml
├── assets/images/
└── lib/
    ├── main.dart
    ├── core/
    │   ├── constants/
    │   │   ├── app_colors.dart
    │   │   └── app_constants.dart
    │   ├── models/
    │   │   └── user_model.dart
    │   ├── theme/
    │   │   └── app_theme.dart
    │   └── widgets/
    │       └── coming_soon_page.dart   # placeholder for unbuilt panels
    └── features/
        ├── auth/
        │   ├── auth_service.dart       # Provider; login/logout + SharedPrefs
        │   └── login_page.dart         # Responsive split-panel login
        ├── director/
        │   ├── director_shell.dart     # ✅ BUILT – sidebar + top bar
        │   ├── dashboard/
        │   │   └── director_dashboard_page.dart  # ✅ BUILT – matches Figma
        │   ├── therapist_section/      # stub – replace with real panel
        │   ├── students_section/       # stub – replace with real panel
        │   ├── stud_progress_section/  # stub – replace with real panel
        │   ├── iep_reports_section/    # stub – replace with real panel
        │   └── settings_section/       # stub – replace with real panel
        ├── therapist/
        │   └── therapist_shell.dart    # placeholder
        └── parent/
            └── parent_shell.dart       # placeholder
```

---

## What Is Built

- ✅ Login page (responsive split-panel, roles → separate dashboards)
- ✅ Director Shell (sidebar, top bar, responsive mobile/tablet/desktop)
- ✅ Director Dashboard (Welcome card, Pending IEP card, Stats, Recent Activities table)
- ✅ All Director sub-page stubs (Therapist / Students / Stud Progress / IEP Reports / Settings)
- ✅ Therapist Shell placeholder
- ✅ Parent Shell placeholder
- ✅ Color system (`app_colors.dart`) matching Figma purple/violet theme
- ✅ `.env` template for MySQL / PHP API credentials

## What Needs to Be Added

- 🔲 Connect MySQL / phpMyAdmin via PHP REST API (see `.env`)
- 🔲 Replace stubs with real panel widgets as designs are provided
- 🔲 Therapist dashboard panels (user will provide Figma designs)
- 🔲 Parent dashboard panels (user will provide Figma designs)
- 🔲 Real auth API (replace dummy credentials in `auth_service.dart`)

---

## Design System

Figma source: Director Dashboard panel (purple/violet brand).

| Token | Value |
|---|---|
| Primary | `#7B2FBE` |
| Primary Light | `#9C4FD6` |
| Accent Teal | `#00BCD4` |
| Scaffold BG | `#F5F5F5` |
| Card BG | `#FFFFFF` |
| Welcome Gradient | `#7B2FBE → #4A1080` |
| Status Pending | `#FF9800` |
| Status Active | `#4CAF50` |
| Status Deactivated | `#E53935` |

Font: **Poppins** (via google_fonts or pubspec override).

---

## Database

Connection details go in `.env`. Two options:

**Option A – Direct MySQL (Flutter native)**
```
DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
```
Package: `mysql_client` (uncomment in pubspec.yaml).

**Option B – PHP REST API Bridge (recommended for web/mobile)**
```
API_BASE_URL=http://yourserver.com/roh_api/
```
Package: `http` (already in pubspec).
Create PHP endpoints in `roh_api/` folder on your server.

---

## How to Add a New Panel

1. Create a new `.dart` file inside the relevant section folder
   - e.g. `lib/features/director/students_section/students_list_page.dart`
2. Replace the `ComingSoonPage` stub in the corresponding `*_page.dart` with the new widget
3. If adding new routes, update `main.dart` routes map
4. Tell Claude: *"Here is the Figma for [Section Name], it belongs to [director/therapist/parent] section, it opens when [sidebar item / button / etc.]"*

---

## Running the App

```bash
# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on Android
flutter run -d android

# Run on Windows
flutter run -d windows

# Build release
flutter build apk        # Android
flutter build web        # Web
flutter build windows    # Windows
flutter build macos      # macOS (on Mac)
flutter build ipa        # iOS (on Mac)
```

---

## Resume Prompt for Claude

> "Read CLAUDE.md and resume working on the ROH ERP Flutter project. Here is the next panel: [paste Figma screenshot]. It belongs to the **[director/therapist/parent]** section and should open when **[describe navigation trigger]**."
