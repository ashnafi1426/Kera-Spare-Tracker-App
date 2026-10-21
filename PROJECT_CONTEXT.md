# Project Context: Kera Spare Tracker

Offline-first, multi-tenant (SaaS) mobile application for spare parts business owners in Kera, Addis Ababa, Ethiopia.

## PRODUCT
- **Purpose**: Spare parts inventory and sales management mobile app.
- **Roles**: Admin and Spare Parts Owner.
- **Owner Registration**: Owners register with phone number, business name, and password.
- **Operations**: Owners manage parts, stock, and sales. Must work fully offline and sync automatically when internet connectivity returns.
- **Localization**: Amharic is the default language, English is optional (switchable in Settings). All text must be localized via ARB files.
- **Multi-tenancy & Isolation**: Each owner has a private inventory. One owner must never see another owner's data.

## SPARE PART FIELDS
- **Fields** (all optional except automatic `id` and `owner_id`):
  - Name
  - Part number
  - Photo
  - Brand
  - Category
  - Description
  - Unit
  - Quantity
  - Purchase price
  - Selling price
  - Storage location (e.g., Shelf 1, Shelf 2...)
  - Custom location
  - Notes
  - Size / specifications
- **Brands**: Configurable. Default brands: CAT, Doosan, Develon, CTP, IPD, Hitachi, SANY.

## SALES
- **Workflow**: Select parts, enter quantity, auto total, auto profit (selling price minus purchase cost at time of sale), auto stock deduction.
- **Records**: Sales history, sales details, search and filter by date and item, daily / weekly / monthly summaries.
- **Offline Support**: Fully functional offline; synchronizes once internet is available.

## TECH STACK (Do not change without explicit approval)
- **Frontend / Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Routing**: go_router
- **Local Database**: Drift (local DB with repository abstraction)
- **Localization**: intl + ARB localization (`app_am.arb`, `app_en.arb`)
- **Connectivity & Background**: connectivity_plus, workmanager
- **Security & Storage**: flutter_secure_storage
- **Media**: image_picker, flutter_image_compress
- **Analytics & Visuals**: fl_chart
- **Backend**: supabase_flutter (PostgreSQL, Auth, Storage, Row Level Security)

## ARCHITECTURE RULES
- **Offline-First**: UI and providers read and write ONLY the local Drift database through repositories. A separate sync engine communicates with the server.
- **Folder Structure (Feature-First)**:
  - `lib/core`
  - `lib/l10n`
  - `lib/data/local`
  - `lib/data/remote`
  - `lib/data/sync`
  - `lib/features/{auth,parts,stock,sales,reports,settings,admin}`
- **Identities**: All IDs are UUIDs generated on the device. Every synced table must have `id`, `owner_id`, `created_at`, `updated_at`, `deleted_at` (soft delete).
- **Ledger-based Stock**: Stock quantity is computed as the sum of `stock_movements` (an append-only ledger). Never overwrite raw quantity from multiple devices.
- **Sales Pricing Snapshot**: Sale items store a snapshot of unit cost, unit price, and part name captured at the exact moment of sale.
- **Strict Localization**: No hard-coded user-facing strings. Use localization keys in `app_am.arb` and `app_en.arb`.
- **UI Design**: Mobile-first, simple, fast UI optimized for low-end Android devices using Material 3 design standards.

## WORKING RULES
- Before coding each task, provide a concise plan.
- After coding, run `flutter analyze`, fix all warnings/errors, and run tests.
- Write clean, well-commented, and well-structured code. Add unit tests for calculations and database logic.
- Do not add packages that are not explicitly in the tech stack without asking the user.
- At the end of every task, summarize all changes made and specify clear manual verification / testing steps.
