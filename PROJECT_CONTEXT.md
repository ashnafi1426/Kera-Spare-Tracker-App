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

## ADMIN MODULE
Who: the admin runs the service (Yonas or his company). The admin is NOT a shop owner. Role is stored in the user record (OWNER or ADMIN).

Requirement duties (from the client):
1. Manage and monitor registered spare parts owners.
2. View and manage user accounts.
3. Manage the overall application and its settings.

Duty 1, monitor owners: list of owners with business name, phone, registration date, status (ACTIVE or SUSPENDED), last sync time, and subscription plan and expiry (future). Search by phone or business name. Filters: active, suspended, inactive for 30 days. Dashboard numbers: total owners, new owners this week, active owners, total parts count and total sales count of the whole system (COUNTS ONLY, never contents), owners with sync problems (no sync for a long time, or many failed syncs), app versions in use (proposed).

Duty 2, manage accounts: view account details, suspend (a suspended owner cannot sync and sees a clear message), reactivate, reset password (proposed), edit basic details such as business name and phone (proposed), disable or delete an account with confirmation (proposed, soft delete only). EVERY admin action must be written to an audit log: who, which account, action, old and new values, reason, time, IP.

Duty 3, app settings: global brand list (CAT, Doosan, Develon, CTP, IPD, Hitachi, SANY and more; owners may also add their own private brands), global categories and units (proposed), minimum required app version (proposed), announcement or maintenance message (proposed), subscription plans and prices (future, only a placeholder now).

WHAT THE ADMIN MUST NEVER DO (very important):
- Never read an owner's parts, prices, stock, sales, or profit.
- Never edit or delete an owner's inventory or sales.
- Never record sales for an owner.
Admin code may use COUNT aggregates on inventory tables for statistics only. No admin endpoint may return rows of spare_parts, stock_movements, sales, or sale_items.

SECURITY RULES: the admin role is checked on the server in middleware (never only hidden in the app). The first admin is created by a seed script (never by public registration). Admin routes are under /api/v1/admin and return 403 for normal owners. Admin login is rate limited. Admin passwords need a strong policy. All admin actions go to the audit log inside the same database transaction as the change.

ADMIN DATABASE SCHEMA & TABLES:
- `users`: Extended with `lastLoginAt`, `lastSyncAt`, `failedSyncCount`, `appVersion`, `mustChangePassword`, `disabledAt`, `suspendedReason`, `suspendedAt`.
- `audit_logs`: Append-only audit trail (`id`, `adminId`, `targetUserId`, `action`, `oldValue`, `newValue`, `reason`, `ipAddress`, `userAgent`, `createdAt`). Indexed on `(targetUserId, createdAt)`, `(adminId, createdAt)`, and `(action, createdAt)`.
- `app_settings`: System settings key-value store (`key`, `value` JSON, `updatedBy`, `updatedAt`).
- `units`: Standardized units (`id`, `ownerId`, `name`, `isGlobal`, `isActive`). Default global: piece, set, liter, meter, kg.
- `categories`: Standardized categories (`id`, `ownerId`, `name`, `isGlobal`, `isActive`). Default global: Filters, Seals, Engine, Undercarriage, Ground tools, Electrical.
- `brands`: Brand catalog (`id`, `ownerId`, `name`, `isGlobal`, `isActive`). Default global: CAT, Doosan, Develon, CTP, IPD, Hitachi, SANY.
- `subscription_plans`: Placeholder catalog (`id`, `name`, `price`, `durationDays`, `isActive`). Existing `subscriptions` table maintained.

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

## SESSION AND OFFLINE RULES
1. Registration, first login, and login on a new or empty phone REQUIRE internet. Show a clear localized message (Amharic and English) when offline: Internet is required to register or log in.
2. After a successful login the app stores: access token and refresh token in flutter_secure_storage (never in plain files or shared preferences), and the owner profile in the local Drift database.
3. On startup the app decides locally, without calling the server: if a stored session and a local profile exist, open the inventory screen immediately, online or offline. All screens read and write only the local database.
4. Tokens are used only for server calls (sync, change password, config). Offline use never depends on a valid access token.
5. Token policy from .env: ACCESS_TOKEN_MINUTES=15, REFRESH_TOKEN_DAYS=90, OFFLINE_MAX_DAYS=90. Refresh tokens rotate on every use and are stored hashed on the server so they can be revoked.
6. NEVER delete local data automatically when a token expires, a refresh fails, or the account is suspended. Unsynced changes are the owner's real work.
7. If the refresh token is expired or revoked, the app keeps working locally, marks sync as needing login, and asks the owner to log in again when internet is available. Pending changes are kept and sent after the new login for the SAME owner id only.
8. Logout rules: if there are pending (unsynced) changes, logout is blocked or requires a strong warning; the local data is wiped on logout only when nothing is pending. If the phone is offline, explain that logging in again will need internet.
9. Suspended account: the server returns 403 ACCOUNT_SUSPENDED; sync stops, a localized message shows, local data stays readable.
10. Optional app lock (PIN or fingerprint) is a local screen lock only; it does not replace server login.
11. The server remains the final judge: every API call re-checks the token, account status, and owner id.

