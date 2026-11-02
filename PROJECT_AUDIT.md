# Kera Spare Tracker — Deep Project & Architecture Audit

**Document Version:** 1.0.0  
**Audit Date:** November 2026  
**Auditor:** Antigravity AI Architecture Team  
**Scope:** Existing Flutter Mobile Client (`c:\Users\Ashu\Kera-Spare-Tracker-App`)  
**Target:** Alignment with Google Stitch UI/UX Design System (`projects/18265425042522896944`)

---

## 1. Executive Summary

The **Kera Spare Tracker** is an offline-first, multi-tenant mobile application built for heavy-machinery and automotive spare parts shop owners in Kera, Addis Ababa, Ethiopia. It also incorporates a multi-tenant administration portal for system operators.

### Key Architectural Strengths
- **Strict Offline-First Stance**: The app strictly treats the local database (Drift/SQLite) as the single source of truth for all UI reads and writes. Network operations never block the local user workflow.
- **Append-Only Ledger for Stock Movement**: Stock is not an editable integer in the database; it is computed as the algebraic sum of append-only `stock_movements`, preserving auditability and multi-device eventual consistency.
- **Mutual Role Guards in Routing**: Clear separation in [app_router.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/lib/core/router/app_router.dart) preventing shop owners from viewing administrative views and barring admins from accessing raw inventory/sale records (preserving tenant privacy).
- **Comprehensive Bilingual Baseline**: Native support for Amharic (`app_am.arb`) and English (`app_en.arb`) with Ethiopic font integration (`NotoSansEthiopic`).

### Identified Gaps & Need for Stitch Integration
1. **Design System Fragmentation**: The app currently uses an initial Material 3 theme ([app_theme.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/lib/core/theme/app_theme.dart)) and an admin-only design token set ([admin_colors.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/lib/core/design/tokens/admin_colors.dart)). It lacks the cohesive, high-density industrial styling present in the 56 Stitch screens.
2. **Missing Screens & Shells**: While core CRUD for parts and sales exists, 18 Stitch screens (such as the dedicated *Sync Center & Diagnostics*, *Conflict Resolution*, *Language Selection Sheet*, *Best-Selling Products Breakdown*, *Owner Business Management*, and *Detailed Empty/Skeleton States*) are either incomplete or embedded inside dialogs rather than dedicated routes.
3. **Widget Rebuild Hotspots**: In [inventory_screen.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/lib/features/parts/presentation/screens/inventory_screen.dart) and [new_sale_screen.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/lib/features/sales/presentation/screens/new_sale_screen.dart), large widget trees lack selective provider listening (`ref.watch(...select(...))`), leading to unnecessary rebuilds during fast keyboard typing and search debouncing.

---

## 2. Complete Folder & File Structure

The project strictly follows a **Feature-First** architecture with shared `core` utilities and `data` abstractions:

```
c:\Users\Ashu\Kera-Spare-Tracker-App\
├── assets/
│   ├── fonts/NotoSansEthiopic.ttf         # Ethiopic unicode font
│   └── images/logo.png                    # Brand assets
├── backend/                               # Express + Prisma + MySQL server
├── lib/
│   ├── main.dart                          # App entry point, bootstrap, error boundaries
│   ├── core/
│   │   ├── constants/constants.dart       # API endpoints, timeouts, dimensions
│   │   ├── design/                        # Admin design tokens & legacy widgets
│   │   │   ├── tokens/                    # admin_colors.dart, admin_typography.dart, admin_spacing.dart
│   │   │   ├── widgets/                   # metric_card.dart, list_card.dart, skeleton_loader.dart, empty_state.dart
│   │   │   └── presentation/              # audit_action_presentation.dart
│   │   ├── errors/failure.dart            # Sealed failure hierarchies (NetworkFailure, ServerFailure, CacheFailure)
│   │   ├── providers/                     # app_config_provider.dart, locale_provider.dart, theme_provider.dart
│   │   ├── router/app_router.dart         # GoRouter setup, mutual role guards, update redirection
│   │   ├── services/                      # session_store.dart, app_lock_service.dart, image_service.dart, storage_service.dart
│   │   ├── theme/app_theme.dart           # Global Material 3 theme configuration
│   │   ├── utils/                         # currency_formatter.dart, date_formatter.dart, result.dart, validators.dart
│   │   └── widgets/                       # server_config_dialog.dart, maintenance_banner_widget.dart, suspended_account_banner_widget.dart
│   ├── data/
│   │   ├── local/                         # Drift SQLite persistence layer
│   │   │   ├── app_database.dart          # Database class, migrations, connection
│   │   │   ├── database_provider.dart     # Riverpod appDatabaseProvider
│   │   │   ├── daos/                      # parts_dao.dart, sales_dao.dart, stock_dao.dart, settings_dao.dart, sync_queue_dao.dart
│   │   │   └── tables/                    # spare_parts_table.dart, sales_table.dart, stock_movements_table.dart, sync_queue_table.dart, etc.
│   │   ├── remote/supabase_service.dart   # Remote client abstraction
│   │   └── sync/sync_engine.dart          # Sync engine entry point
│   ├── features/
│   │   ├── admin/                         # Admin portal (dashboard, owners list, audit logs, global catalog, settings)
│   │   ├── auth/                          # Authentication, login, register, change password, session banners
│   │   ├── home/                          # HomeScreen with BottomNavigationBar and IndexedStack
│   │   ├── parts/                         # Inventory list, filter bottom sheet, part form, part details
│   │   ├── reports/                       # Reports dashboard, sales summaries, charts (fl_chart), valuation
│   │   ├── sales/                         # New POS sale, shopping cart, sale details, sales history, sale success
│   │   ├── security/                      # App lock (PIN & biometric) lifecycle wrapper and screen
│   │   ├── settings/                      # Settings screen, brands, categories, locations management, backup export
│   │   ├── splash/                        # SplashScreen and UpdateRequiredScreen
│   │   ├── stock/                         # Low stock screen, stock history, stock adjustment dialog
│   │   └── sync/                          # Initial sync pull service, sync push service, initial sync screen
│   └── l10n/                              # Localization files (app_am.arb, app_en.arb, app_localizations.dart)
├── test/                                  # 34 comprehensive unit, widget, and integration test suites
└── pubspec.yaml                           # Dependency definitions & Flutter configuration
```

---

## 3. Application Initialization & Startup (`main.dart`)

### Startup Pipeline
File: [main.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/lib/main.dart)

1. **Measurement**: Implements high-precision `Stopwatch` instrumentation (`[STARTUP]` logs) tracking binding initialization, error boundaries, and `runApp()` timing.
2. **Error Boundaries**:
   - `FlutterError.onError`: Intercepts framework errors and prints diagnostics.
   - `PlatformDispatcher.instance.onError`: Prevents uncaught platform asynchronous exceptions from crashing the process.
   - `ErrorWidget.builder`: Replaces the default red crash screen with a production-grade, user-friendly fallback widget.
3. **Zero Blocking on Startup**: Does not block `runApp()` on asynchronous disk I/O or keychain access. Instead, loads saved server configurations and background metadata via `WidgetsBinding.instance.addPostFrameCallback`.
4. **Root Hierarchy**:
   ```
   ProviderScope
     └── KeraSpareTrackerApp (ConsumerWidget)
           └── MaterialApp.router
                 └── AppLockLifecycleWrapper (Security & session timeout listener)
   ```

---

## 4. Routing & Navigation Architecture (`app_router.dart`)

### Routing Framework
File: [app_router.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/lib/core/router/app_router.dart)
- Powered by `go_router: ^18.1.1` and controlled via `appRouterProvider`.
- Listens to `authControllerProvider` and `appConfigNotifierProvider` using an internal `_AuthRefreshNotifier`.

### Redirection Rules Matrix
1. **Force Update Priority**: If `isUpdateRequired == true`, redirects all navigation to `/update-required`.
2. **Initial Auth Check**: Renders `/` (`SplashScreen`) while auth state is initializing.
3. **Unauthenticated Access**: Any attempt to access protected routes without an active session redirects to `/login`.
4. **Mandatory Password Reset**: If `user.mustChangePassword == true`, redirects to `/change-password`.
5. **Mutual Role Boundary Guard**:
   - `user.isAdmin == true`: Redirected to `/admin` (`AdminDashboardScreen`). If an admin navigates to `/home` or `/parts/*`, they are redirected back to `/admin`.
   - `user.isAdmin == false` (Owner): If an owner tries to access `/admin/*`, they are immediately redirected to `/home`.
6. **Admin Responsive Shell**: Admin routes (`/admin`, `/admin/owners`, `/admin/catalog`, `/admin/settings`, `/admin/audit-logs`, `/admin/account`) are wrapped in a responsive `ShellRoute` using [admin_scaffold.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/lib/features/admin/presentation/widgets/admin_scaffold.dart), adapting seamlessly between mobile drawer and desktop navigation rails.

---

## 5. State Management Architecture

- **State Management Core**: `flutter_riverpod: ^3.4.3`.
- **Primary Patterns**:
  - `Notifier` & `AsyncNotifier` classes for interactive mutation controllers (`AuthController`, `InventoryListNotifier`, `NewSaleCartNotifier`, `ThemeModeController`, `LocaleController`).
  - `Provider` & `FutureProvider` for read-only repository bindings and dependency injection.
  - `family` providers for parameterized lookups (e.g., `partByIdProvider(id)`, `stockHistoryProvider(partId)`).
  - Clean separation: UI widgets depend on Presentation Providers, which call Domain Repositories, which interact with Drift DAOs.

---

## 6. Local Database & Persistence (Drift / SQLite)

### Architecture
File: [app_database.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/lib/data/local/app_database.dart)
- Uses `drift: ^2.35.2` and `drift_flutter: ^0.3.1` storing data in a local SQLite file (`kera_spare_tracker.sqlite`).
- **Data Isolation**: All primary tables enforce `ownerId` filtering.
- **Entities & Tables**:
  - `SparePartsTable`: Core catalog entity with cached quantity, part number, brand, category, shelf, unit, and prices.
  - `StockMovementsTable`: **Append-only ledger** recording every stock addition, sale deduction, physical inventory count correction, and damage write-off.
  - `SalesTable`: Order header containing total price, total cost, profit, customer notes, and offline status.
  - `SaleItemsTable`: Point-in-time snapshot of unit cost, selling price, and quantity at the exact instant of sale.
  - `SyncQueueTable`: Outbox queue tracking all local mutations that must be pushed to the remote server.
  - `BrandsTable`, `CategoriesTable`, `LocationsTable`: Metadata supporting both global pre-seeded values and custom tenant values.
  - `AppSettingsTable`, `ProfilesTable`, `SyncMetaTable`: Operational state storage.

---

## 7. Synchronization & Offline Engine

### Current Mechanism
1. **Push Sync** ([sync_push_service.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/lib/features/sync/data/services/sync_push_service.dart)):
   - Checks `Connectivity().checkConnectivity()`.
   - Reads pending items in batches of 50 from `syncQueueDao`.
   - Sends payload to `POST /sync/push`.
   - On HTTP 200, deletes batch from `syncQueue` and updates `SessionStore.recordOnlineActivity()`.
   - On error, increments failure count and records the server error message in the queue record.
2. **Pull Sync (Initial Catalog)** ([initial_sync_service.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/lib/features/sync/data/services/initial_sync_service.dart)):
   - Streams `InitialSyncProgress` for new device onboarding.
   - Paginates `GET /parts?limit=50&offset=X`.
   - As soon as the first 50 items are written to Drift, emits `firstBatchReady: true`, allowing the user to enter the app without waiting for thousands of parts to finish downloading.
3. **Gaps to Address for Stitch**:
   - Stitch provides dedicated screens for:
     - `1. Sync Center & Queue — የዳታ ማመሳከሪያ ማዕከል` (`b8ca61d2422142fc9708c95af09eb0ac`)
     - `3. Conflict Resolution — የዳታ ግጭት መፍቻ` (`3553c1239f2d46fe8f85fda7c1c0c1d9`)
     - `4. Sync Success & Error Diagnostics — የማመሳከሪያ ውጤት እና ስህተት` (`0b15ccf164604a2087f13ff0ad120e35`)
   - Currently, these are not exposed as dedicated routes in GoRouter.

---

## 8. Authentication, Authorization & Security

1. **Authentication Flow**:
   - Phone number normalized to E.164 (`+251XXXXXXXXX`).
   - Secure token storage via `flutter_secure_storage: ^10.3.4` (Access Token, Refresh Token, Biometric PIN).
   - In-memory token expiration handling with automatic background token refresh via Dio interceptors.
2. **Offline Session Continuity**:
   - After initial login, session credentials and owner profile persist in SQLite.
   - The app boots directly to `/home` offline without requiring an active server handshake.
   - Token expiration does NOT purge local data; it flags `needsLogin` and restricts remote sync until the owner re-authenticates.
3. **Administrative Security**:
   - Admin login rate-limiting, bcrypt complexity enforcement, forced password reset (`mustChangePassword`).
   - 15-minute inactivity session timeout with automatic logout.
   - Append-only audit logging for every admin mutation.

---

## 9. Localization & Internationalization (Amharic & English)

- **Engine**: Flutter `intl` package driven by `l10n.yaml` and ARB files:
  - `lib/l10n/app_am.arb` (Amharic - Default primary language)
  - `lib/l10n/app_en.arb` (English - Secondary option)
- **Typography Integration**: Uses `NotoSansEthiopic` font family mapped in `pubspec.yaml`.
- **Audit Findings**:
  - Over 180 localized keys already exist covering parts, sales, auth, stock, and reports.
  - A small number of hardcoded English strings exist in recent admin dialogs and error toasts.
  - Stitch designs feature rich bilingual headers (e.g., `የሽያጭ ሂደት / Sales Trends`), which need standardized styling so text does not clip or crowd on smaller screens.

---

## 10. Existing Tests & Verification Suite

The repository contains an impressive, robust automated testing suite with **34 test files**:
- **Database & DAO tests**: [app_database_test.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/test/data/local/app_database_test.dart) verifies table migrations, UUID generation, soft-delete, and stock ledger calculations.
- **Auth & Offline rules**: [session_and_offline_rules_test.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/test/features/auth/session_and_offline_rules_test.dart) tests 90-day offline grace periods, protected logout, and token revocation.
- **Sales & Calculation tests**: [sales_repository_test.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/test/features/sales/repositories/sales_repository_test.dart) checks profit margins, negative stock prevention, and transaction consistency.
- **Admin & Security tests**: [admin_ui_responsive_test.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/test/features/admin/admin_ui_responsive_test.dart) verifies tablet/desktop rails, audit logging, and role guards.
- **Integration flows**: [mvp_flow_test.dart](file:///c:/Users/Ashu/Kera-Spare-Tracker-App/test/integration/mvp_flow_test.dart) tests complete login $\rightarrow$ catalog $\rightarrow$ sale $\rightarrow$ reports flows.

