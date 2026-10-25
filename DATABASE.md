# Database Documentation: Kera Spare Tracker

This document provides a comprehensive reference for the MySQL relational database schema managed via Prisma ORM for the Kera Spare Tracker multi-tenant platform.

---

## 1. Multi-Tenant Architecture & Data Isolation

- **Tenant Isolation**: Every owner-specific record is strictly tied to `ownerId` (referencing `users.id`).
- **Admin Boundaries**: Admins manage system settings, brands, categories, units, and audit trails. **Admins are strictly prohibited from querying or mutating rows in `spare_parts`, `stock_movements`, `sales`, or `sale_items`** (aggregate `COUNT(*)` only for metrics).
- **Soft Deletion**: Records support soft-delete via `deletedAt TIMESTAMP(6)` to preserve auditability and prevent orphaned references.
- **Append-Only Auditing**: The `audit_logs` table is strictly append-only. No UPDATE or DELETE operations are exposed.

---

## 2. Table Specifications

### 2.1 `users`
Core identity table representing Spare Parts Owners and System Administrators.

| Column | Type | Constraints / Attributes | Description |
|---|---|---|---|
| `id` | `CHAR(36)` | PRIMARY KEY | UUIDv4 identifier |
| `phoneNumber` | `VARCHAR(20)` | UNIQUE, NOT NULL | E.164 formatted phone number |
| `businessName` | `VARCHAR(100)` | NOT NULL | Spare parts shop / company name |
| `passwordHash` | `VARCHAR(255)` | NOT NULL | bcrypt hashed password |
| `role` | `ENUM('OWNER', 'ADMIN')` | DEFAULT `'OWNER'` | Access role |
| `status` | `ENUM('ACTIVE', 'SUSPENDED')` | DEFAULT `'ACTIVE'` | Account status |
| `language` | `ENUM('AMHARIC', 'ENGLISH')` | DEFAULT `'AMHARIC'` | Preferred interface language |
| `lastLoginAt` | `TIMESTAMP(6)` | NULLABLE | Timestamp of most recent login |
| `lastSyncAt` | `TIMESTAMP(6)` | NULLABLE | Timestamp of most recent offline sync |
| `failedSyncCount`| `INTEGER` | DEFAULT `0` | Consecutive sync failure counter |
| `appVersion` | `VARCHAR(50)` | NULLABLE | Mobile app version reported by client |
| `mustChangePassword` | `BOOLEAN` | DEFAULT `false` | Forces password reset on next login |
| `disabledAt` | `TIMESTAMP(6)` | NULLABLE | Soft-disable timestamp |
| `suspendedReason` | `TEXT` | NULLABLE | Administrator notes on suspension |
| `suspendedAt` | `TIMESTAMP(6)` | NULLABLE | Timestamp when suspension took effect |
| `createdAt` | `TIMESTAMP(6)` | DEFAULT `now()` | Record creation timestamp |
| `updatedAt` | `TIMESTAMP(6)` | ON UPDATE `now()` | Record modification timestamp |
| `deletedAt` | `TIMESTAMP(6)` | NULLABLE | Soft-delete timestamp |

---

### 2.2 `audit_logs`
Immutable, append-only security log recording administrative actions.

| Column | Type | Constraints / Attributes | Description |
|---|---|---|---|
| `id` | `CHAR(36)` | PRIMARY KEY | UUIDv4 identifier |
| `adminId` | `CHAR(36)` | NOT NULL, FK(`users.id`) | Admin who initiated the action |
| `targetUserId` | `CHAR(36)` | NULLABLE, FK(`users.id` ON DELETE SET NULL) | Account affected (if applicable) |
| `action` | `VARCHAR(100)` | NOT NULL | Action key (e.g. `USER_SUSPENDED`, `PASSWORD_RESET`) |
| `oldValue` | `JSON` | NULLABLE | State before modification |
| `newValue` | `JSON` | NULLABLE | State after modification |
| `reason` | `TEXT` | NULLABLE | Justification entered by administrator |
| `ipAddress` | `VARCHAR(45)` | NULLABLE | Client IPv4 / IPv6 address |
| `userAgent` | `VARCHAR(255)` | NULLABLE | Browser / client User-Agent |
| `createdAt` | `TIMESTAMP(6)` | DEFAULT `now()` | Event occurrence timestamp |

**Indexes**:
- `INDEX (targetUserId, createdAt)`
- `INDEX (adminId, createdAt)`
- `INDEX (action, createdAt)`

---

### 2.3 `app_settings`
Global application settings and configuration store.

| Column | Type | Constraints / Attributes | Description |
|---|---|---|---|
| `id` | `CHAR(36)` | PRIMARY KEY | UUIDv4 identifier |
| `key` | `VARCHAR(100)` | UNIQUE, NOT NULL | Setting key (`minAppVersion`, `maintenanceMode`, `announcement`) |
| `value` | `JSON` | NOT NULL | Structured configuration payload |
| `updatedBy` | `CHAR(36)` | NULLABLE, FK(`users.id`) | Last administrator who updated the key |
| `updatedAt` | `TIMESTAMP(6)` | ON UPDATE `now()` | Update timestamp |

---

### 2.4 `brands`
Spare parts brand registry supporting global pre-seeds and owner custom brands.

| Column | Type | Constraints / Attributes | Description |
|---|---|---|---|
| `id` | `CHAR(36)` | PRIMARY KEY | UUIDv4 identifier |
| `ownerId` | `CHAR(36)` | NULLABLE, FK(`users.id` ON DELETE CASCADE) | `NULL` for global brands, user UUID for custom |
| `name` | `VARCHAR(100)` | NOT NULL | Brand name (CAT, Doosan, Develon, etc.) |
| `isGlobal` | `BOOLEAN` | DEFAULT `false` | True if available to all tenants |
| `isActive` | `BOOLEAN` | DEFAULT `true` | Active status flag |
| `createdAt` | `TIMESTAMP(6)` | DEFAULT `now()` | Record creation timestamp |
| `updatedAt` | `TIMESTAMP(6)` | ON UPDATE `now()` | Modification timestamp |
| `deletedAt` | `TIMESTAMP(6)` | NULLABLE | Soft-delete timestamp |

---

### 2.5 `categories`
Classification registry supporting global standard categories and tenant custom categories.

| Column | Type | Constraints / Attributes | Description |
|---|---|---|---|
| `id` | `CHAR(36)` | PRIMARY KEY | UUIDv4 identifier |
| `ownerId` | `CHAR(36)` | NULLABLE, FK(`users.id` ON DELETE CASCADE) | `NULL` for global, user UUID for custom |
| `name` | `VARCHAR(100)` | NOT NULL | Category name (Filters, Seals, Engine, etc.) |
| `isGlobal` | `BOOLEAN` | DEFAULT `false` | True if available to all tenants |
| `isActive` | `BOOLEAN` | DEFAULT `true` | Active status flag |
| `createdAt` | `TIMESTAMP(6)` | DEFAULT `now()` | Record creation timestamp |
| `updatedAt` | `TIMESTAMP(6)` | ON UPDATE `now()` | Modification timestamp |
| `deletedAt` | `TIMESTAMP(6)` | NULLABLE | Soft-delete timestamp |

---

### 2.6 `units`
Measurement units registry supporting global defaults and custom definitions.

| Column | Type | Constraints / Attributes | Description |
|---|---|---|---|
| `id` | `CHAR(36)` | PRIMARY KEY | UUIDv4 identifier |
| `ownerId` | `CHAR(36)` | NULLABLE, FK(`users.id` ON DELETE CASCADE) | `NULL` for global, user UUID for custom |
| `name` | `VARCHAR(50)` | NOT NULL | Unit name (`piece`, `set`, `liter`, `meter`, `kg`) |
| `isGlobal` | `BOOLEAN` | DEFAULT `false` | True if available to all tenants |
| `isActive` | `BOOLEAN` | DEFAULT `true` | Active status flag |
| `createdAt` | `TIMESTAMP(6)` | DEFAULT `now()` | Record creation timestamp |
| `updatedAt` | `TIMESTAMP(6)` | ON UPDATE `now()` | Modification timestamp |
| `deletedAt` | `TIMESTAMP(6)` | NULLABLE | Soft-delete timestamp |

---

### 2.7 `subscription_plans`
Placeholder catalog for commercial subscription tiers.

| Column | Type | Constraints / Attributes | Description |
|---|---|---|---|
| `id` | `CHAR(36)` | PRIMARY KEY | UUIDv4 identifier |
| `name` | `VARCHAR(100)` | NOT NULL | Plan name (`Free`, `Standard`, `Premium`) |
| `price` | `DECIMAL(12, 2)`| NOT NULL | Subscription price |
| `durationDays` | `INTEGER` | NOT NULL | Duration in days |
| `isActive` | `BOOLEAN` | DEFAULT `true` | Availability status |
| `createdAt` | `TIMESTAMP(6)` | DEFAULT `now()` | Record creation timestamp |
| `updatedAt` | `TIMESTAMP(6)` | ON UPDATE `now()` | Modification timestamp |
| `deletedAt` | `TIMESTAMP(6)` | NULLABLE | Soft-delete timestamp |

---

### 2.8 Operational Tables
- **`spare_parts`**: Tenant inventory items (`id`, `ownerId`, `name`, `partNumber`, `photoUrl`, `brandId`, `categoryId`, `locationId`, `unit`, `cachedQuantity`, `purchasePrice`, `sellingPrice`).
- **`stock_movements`**: Append-only ledger recording every quantity change (`PURCHASE`, `SALE`, `ADJUSTMENT_IN`, `ADJUSTMENT_OUT`, `RETURN`).
- **`sales`**: Sales transaction receipts (`id`, `ownerId`, `receiptNumber`, `totalAmount`, `totalProfit`, `paymentMethod`, `soldAt`).
- **`sale_items`**: Line items with captured snapshots of cost, price, and part name at time of sale.
- **`locations`**: Storage bins and shelves per tenant.
- **`refresh_tokens`**: Hashed JWT refresh tokens with automatic rotation and revocation support.
- **`subscriptions`**: Active tenant subscription bindings.

---

## 3. Seed Execution & Migrations

- **Migrations Directory**: `backend/prisma/migrations/`
  - `20261025000000_init`: Base schema baseline
  - `20261025170000_add_admin_module_schema`: Admin module schema extensions
- **Seed Command**: `npm run seed` (`node prisma/seed.js`)
  - Ensures default admin user exists with `mustChangePassword = true`
  - Pre-seeds global brands: `CAT`, `Doosan`, `Develon`, `CTP`, `IPD`, `Hitachi`, `SANY`
  - Pre-seeds global categories: `Filters`, `Seals`, `Engine`, `Undercarriage`, `Ground tools`, `Electrical`
  - Pre-seeds global units: `piece`, `set`, `liter`, `meter`, `kg`
  - Pre-seeds default app settings: `minAppVersion`, `maintenanceMode`, `announcement`
