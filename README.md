# Kera Spare Tracker

Offline-first, multi-tenant (SaaS) mobile application designed specifically for spare parts business owners in Kera, Addis Ababa, Ethiopia.

## Features & Highlights
- **Offline-First Resilience**: All inventory, movements, and sales operate completely offline with automatic background sync when connectivity is restored.
- **Amharic-First Localization**: Localized in Amharic by default with optional English switching in settings.
- **Multi-Tenant Isolation**: Private inventory management where each owner's data is isolated and protected with Supabase Row Level Security (RLS).
- **Ledger-Based Inventory**: Stock quantity is tracked via append-only `stock_movements` to eliminate race conditions across offline edits.
- **Point-of-Sale (POS)**: Instant pricing, automatic profit computation, and sale-time pricing snapshots.
- **Mobile-First UX**: High-contrast Material 3 design with 48+ dp touch targets optimized for low-end Android smartphones.

---

## Tech Stack
- **Framework**: Flutter (Dart 3.x)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Routing**: `go_router`
- **Local Persistence**: `drift` & `drift_flutter` (SQLite)
- **Remote Backend**: `supabase_flutter` (PostgreSQL, Auth, Storage, RLS)
- **Localization**: `flutter_localizations` & `intl` (ARB files: `app_am.arb`, `app_en.arb`)
- **Background Tasks & Sync**: `connectivity_plus`, `workmanager`
- **Security & Storage**: `flutter_secure_storage`
- **Media**: `image_picker`, `flutter_image_compress`
- **Analytics & Charts**: `fl_chart`

---

## Project Structure
```
lib/
├── core/
│   ├── constants/       # App constants, default brands, shelves, units
│   ├── errors/          # Domain failures & exceptions
│   ├── providers/       # Core Riverpod providers (e.g. localeProvider)
│   ├── router/          # GoRouter configuration
│   ├── theme/           # Material 3 light theme & touch target dimensions
│   └── utils/           # Result types, validators, BuildContext extensions
├── data/
│   ├── local/           # Drift SQLite database & local DAOs
│   ├── remote/          # Supabase client & remote data sources
│   └── sync/            # Sync engine & background sync orchestrators
├── features/
│   ├── admin/           # Platform administration
│   ├── auth/            # Owner registration & authentication
│   ├── parts/           # Spare parts catalog & details
│   ├── reports/         # Sales summaries & profit graphs
│   ├── sales/           # POS, sales recording, and history
│   ├── settings/        # Locale switching, brand configs, profile
│   ├── splash/          # Splash screen & initial bootstrapping
│   └── stock/           # Stock movements ledger & adjustments
├── l10n/
│   ├── app_am.arb       # Amharic translations (default)
│   └── app_en.arb       # English translations
└── main.dart            # App entrypoint with ProviderScope & MaterialApp.router
```

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.13+
- Android Studio / Android SDK with Android 8.0+ (API 26+) emulator or physical device

### Installation & Run

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Generate localizations**:
   ```bash
   flutter gen-l10n
   ```

3. **Run code generators (Drift, etc.)**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Launch the application**:
   ```bash
   flutter run
   ```

### Quality Assurance & Testing

- **Run Static Analysis**:
  ```bash
  flutter analyze
  ```

- **Run Unit & Widget Tests**:
  ```bash
  flutter test
  ```