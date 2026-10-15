# ROH-ERP Flutter App: Architecture & Engineering Implementation Plan

**Project:** Ray of Hope – Autism Center ERP System (ROH-ERP)  
**Document Type:** Technical Implementation & Refactoring Plan  
**Target Architecture:** Feature-First + MVVM + Repository Pattern + Riverpod + GoRouter  
**Date:** October 7, 2026  

---

## 1. Executive Overview & Current State Gap Analysis

The ROH-ERP Flutter application currently operates with a solid UI prototype across 4 main roles (**Admin, Director, Therapist, and Parent**), powered by direct HTTP calls via `api_service.dart` and `db_queries.dart`, and local widget `setState`.

To transition to the robust, scalable architecture specified in the **Engineering Guide**, we must systematically migrate:

| Architectural Area | Current Baseline | Target Architecture |
| :--- | :--- | :--- |
| **State Management** | Ephemeral `setState` & direct static calls | **Riverpod 2.x (`Notifier`, `AsyncNotifier`, `FutureProvider.autoDispose`)** |
| **Routing & Navigation** | Imperative `Navigator.push` / IndexedStack | **`go_router` with declarative role-based redirect guards** |
| **Networking Layer** | Basic `http.Client` wrapper | **`Dio` with JWT Interceptors, token refresh, and retry logic** |
| **Data Models** | Ad-hoc `Map<String, dynamic>` maps | **Immutable models with `freezed` + `json_serializable`** |
| **Secure Storage & Cache** | In-memory / Basic shared prefs | **`flutter_secure_storage` (Tokens) + Offline Cache (`Hive` / `Drift`)** |
| **Architecture Pattern** | Flat feature pages with direct service calls | **Feature-First + MVVM + Repository Pattern (Presentation / Domain / Data)** |
| **Theming & Design Tokens** | Custom `AppColors` hardcoded purple | **Material 3 with Sage Green primary (`#7FA98A`) & calm neurodivergent tokens** |
| **CI/CD & Testing** | Manual command execution | **GitHub Actions CI/CD (Analyze, Test, Build, Release)** |

---

## 2. Target Feature-First Codebase Layout

```
FRONT-END/lib/
├── core/
│   ├── config/              # Environment configurations (dev, staging, prod), flavors
│   ├── network/             # Dio client, AuthInterceptor, error transformer, retry policy
│   ├── storage/             # FlutterSecureStorage service, local storage providers
│   ├── router/              # GoRouter configuration, role guards, redirect handlers
│   ├── theme/               # Material 3 Sage Green theme (#7FA98A), calm visuals, typography
│   ├── error/               # Failures (NetworkFailure, UnauthorizedFailure, ValidationFailure)
│   ├── widgets/             # Global reusable UI: loaders, empty states, error retry widgets
│   └── utils/               # Date formatters, score calculators
├── features/
│   ├── auth/
│   │   ├── data/            # AuthApi, AuthRepositoryImpl, UserModel
│   │   ├── domain/          # AuthState entity, LoginUseCase
│   │   └── presentation/    # LoginScreen, AuthNotifier (AsyncNotifierProvider)
│   ├── shell/               # Shared adaptive layout (Sidebar for Web/Desktop, BottomNav for Mobile)
│   ├── admin/               # Admin portal features & repositories
│   ├── director/            # Director supervision, appointments, approvals
│   ├── therapist/           # Clinical assessments & Daily Data Sheet
│   │   ├── assessments/     # Milestone, Barriers, Transition, EESA repositories & notifiers
│   │   ├── daily_data/      # DTT, Manding, ABC data sheet state notifiers
│   │   └── timetable/       # Therapist scheduling & timetable state
│   └── parent/              # Parent progress view, daily notes, reports
├── app.dart                 # ConsumerWidget with MaterialApp.router
└── main.dart                # ProviderScope entrypoint
```

---

## 3. Step-by-Step Implementation Phases

### Phase 1: Dependencies & Core Infrastructure
1. **Update `pubspec.yaml`**:
   - Add state management: `flutter_riverpod`, `riverpod_annotation`.
   - Add routing: `go_router`.
   - Add networking: `dio`.
   - Add serialization: `freezed_annotation`, `json_annotation`.
   - Add local storage: `flutter_secure_storage`, `hive_flutter`.
   - Add dev dependencies: `build_runner`, `freezed`, `json_serializable`, `mocktail`.
2. **Setup Network Layer (`lib/core/network/`)**:
   - Configure `DioProvider` with Base URL (`http://localhost:8000/api.php?action=`).
   - Implement `AuthInterceptor`:
     - Attach `Bearer <token>` from `SecureStorageService`.
     - Intercept `401 Unauthorized` to trigger token refresh or clean logout.
3. **Setup Error Handling (`lib/core/error/`)**:
   - Implement typed `Failure` union classes (`ServerFailure`, `NetworkFailure`, `AuthFailure`).

---

### Phase 2: Authentication & Role-Based Navigation Guard
1. **Auth State with Riverpod**:
   - Define `AuthState` model (`initial`, `loading`, `authenticated`, `unauthenticated`).
   - Implement `AuthNotifier extends AsyncNotifier<AuthState>`:
     - Methods: `login(email, password)`, `logout()`, `restoreSession()`.
     - Secure token storage using `flutter_secure_storage`.
2. **Declarative Routing with `go_router`**:
   - Configure router provider:
     ```dart
     final routerProvider = Provider<GoRouter>((ref) {
       final auth = ref.watch(authNotifierProvider);
       return GoRouter(
         initialLocation: '/login',
         redirect: (context, state) {
           final user = auth.valueOrNull?.user;
           final isLoggingIn = state.matchedLocation == '/login';
           if (user == null) return isLoggingIn ? null : '/login';
           if (isLoggingIn) return '/${user.role}';
           if (state.matchedLocation.startsWith('/director') && user.role != Role.director) return '/unauthorized';
           if (state.matchedLocation.startsWith('/therapist') && user.role != Role.therapist) return '/unauthorized';
           if (state.matchedLocation.startsWith('/admin') && user.role != Role.admin) return '/unauthorized';
           if (state.matchedLocation.startsWith('/parent') && user.role != Role.parent) return '/unauthorized';
           return null;
         },
         routes: [ ... ],
       );
     });
     ```

---

### Phase 3: Clinical Assessment & Data Repositories (Therapist Feature)
1. **Repository Layer Migration**:
   - Migrate from raw static methods to typed repositories:
     - `MilestoneAssessmentRepository`: Fetches and persists tests 1–4 across 16 domains.
     - `BarriersAssessmentRepository`: Manages 24 barrier ratings (0–4 scale).
     - `TransitionAssessmentRepository`: Manages 18 educational areas (1–5 scale).
     - `EesaAssessmentRepository`: Manages syllable and vowel responses.
     - `DailyDataSheetRepository`: Manages DTT trials, Mand rates, and ABC behavior tracking.
2. **Riverpod ViewModel / Notifiers**:
   - Create `AsyncNotifierProvider` for assessments:
     ```dart
     final milestoneAssessmentProvider = AsyncNotifierProvider.family<
         MilestoneAssessmentNotifier, List<MilestoneAssessment>, int>(
       MilestoneAssessmentNotifier.new,
     );
     ```
   - Enables compile-safe `.when(data: ..., loading: ..., error: ...)` in UI widgets.

---

### Phase 4: Dynamic & Automated Graph Engine
1. **Decouple Graph Rendering from Mock State**:
   - Connect Milestone, Barriers, and Daily Data graphs directly to Riverpod providers.
   - Graph calculations run on clean repository data streams without manual recalculation.
2. **Automated Visual Color-Coding**:
   - Dynamically paint Test 1 (Yellow), Test 2 (Green), Test 3 (Blue), Test 4 (Red) directly from the `milestone_assessments` database table.

---

### Phase 5: Design System & Neurodivergent Accessibility
1. **Material 3 Theme Update**:
   - Primary Seed: **Sage Green (`#7FA98A`)** with soft complementary neutral tones.
   - High contrast, predictable layouts, minimum 48dp touch targets.
   - Motion reduced to provide calm visuals for neurodiverse children and clinicians.

---

### Phase 6: Testing Strategy & CI/CD Pipeline
1. **Testing**:
   - **Unit Tests:** Test all Notifiers and Repositories with `mocktail`.
   - **Widget Tests:** Use `ProviderScope(overrides: [...])` to test screens without network dependencies.
   - **Integration Tests:** Verify Login -> Role Shell -> Assessment Flow.
2. **CI/CD Automation (`.github/workflows/ci.yml`)**:
   - Trigger on every Pull Request and push to `main` and `develop`.
   - Automated `flutter analyze`, `dart format`, and `flutter test --coverage`.

---

## 4. Definition of Done Checklist (Per Feature)

- [ ] Clear separation between Presentation (Widget), ViewModel (Notifier), and Data (Repository).
- [ ] Comprehensive handling of **Loading**, **Empty**, **Error**, and **Success** states.
- [ ] Three-level security: Router guards, UI control visibility, and Backend API validation.
- [ ] No hardcoded colors, magic strings, or raw endpoints.
- [ ] 100% warning-free `flutter analyze`.
- [ ] Automated tests written and passing in CI pipeline.
