# Administrative Security Architecture & Hardening Guide

## 1. Executive Summary

This document specifies the security controls, hardening measures, and threat mitigation mechanisms implemented across the **Kera Spare Tracker** administrative layer.

The admin module is designed around the principles of **Least Privilege**, **Zero-Trust Input Validation**, **Defense in Depth**, and **Strict Tenant Isolation**.

---

## 2. Threat Modeling & Security Controls Matrix

| Threat / Attack Vector | Risk | Mitigation Implementation |
| :--- | :--- | :--- |
| **Credential Brute-Force** | High | Multi-layered rate limiting (5 attempts / 15 min per IP and per phone) with temporary sliding lockout. |
| **Account Enumeration** | Medium | Identical 401 `INVALID_CREDENTIALS` error message for non-existent numbers, wrong passwords, and non-admin roles. |
| **Weak Administrative Passwords** | High | Code-enforced complexity policy: $\ge 12$ chars, uppercase, lowercase, digit, and symbol. Mandatory change on first login. |
| **Privilege Escalation** | Critical | Public registration strictly hardcodes `role: OWNER`. Admin accounts can only be provisioned via terminal CLI or database seeds. |
| **Token Theft / Session Hijacking** | High | 10-minute short-lived admin JWT access tokens; cryptographically hashed database-stored refresh tokens with revocation; 15-minute UI inactivity timeout. |
| **Cross-Origin / Injection Attacks** | High | Strict `.env`-driven CORS whitelist (`ADMIN_CORS_ORIGIN`), Content Security Policy (CSP), Referrer Policy, 1MB body size cap. |
| **Tenant Data Leakage to Admins** | Critical | Administrative endpoints use aggregate `COUNT` queries only. Admin routes are barred from returning rows of `spare_parts`, `stock_movements`, or `sales`. |
| **Sensitive Credential Exposure** | Critical | Passwords and hashes are stripped from all responses and never written to `audit_logs`. |

---

## 3. Authentication & Rate Limiting

### 3.1 Rate Limiting and Temporary Lockout
- **Sliding Window**: 15 minutes (900,000 ms).
- **Threshold**: 5 failed attempts per IP address and per normalized phone number (`+251XXXXXXXXX`).
- **Lockout Mechanism**: Upon the 6th failed attempt within the window, the endpoint immediately returns HTTP 429 (`TOO_MANY_REQUESTS` with error message: *"Too many failed login attempts. Account or IP temporarily locked for 15 minutes."*).
- **Dual-Layer Enforcement**:
  1. **Express Middleware Layer**: `express-rate-limit` with `skipSuccessfulRequests: true` prevents network-level flooding.
  2. **Service Layer**: In-memory lockout registry tracks failed credentials by normalized phone number even across rotating proxies/IPs.
- **Successful Login**: Clears the failure counters for both the originating IP and target phone number.

### 3.2 Account Enumeration Mitigation
When an unauthenticated entity posts credentials to `POST /api/v1/auth/admin/login`:
1. If the phone number does not exist $\rightarrow$ Returns 401 `INVALID_CREDENTIALS` (*"Invalid phone number or password."*).
2. If the phone number belongs to an `OWNER` $\rightarrow$ Returns 401 `INVALID_CREDENTIALS` (*"Invalid phone number or password."*).
3. If the password hash does not match $\rightarrow$ Returns 401 `INVALID_CREDENTIALS` (*"Invalid phone number or password."*).
4. In all three cases, `action: 'ADMIN_LOGIN_FAILED'` is recorded in the append-only `audit_logs` table with client IP, user agent, and timestamp.

---

## 4. Administrative Password Policy

### 4.1 Complexity Requirements
All admin passwords (whether set during creation or changed via `POST /api/v1/auth/change-password`) must satisfy `ADMIN_PASSWORD_REGEX`:
```regex
/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~`]).{12,}$/
```
- **Minimum Length**: 12 characters
- **Character Classes**:
  - At least one lowercase letter (`a-z`)
  - At least one uppercase letter (`A-Z`)
  - At least one numerical digit (`0-9`)
  - At least one special symbol (`!@#$%^&*()_+-=[]{};':"|,.<>/?~` `)

### 4.2 Mandatory Password Change (`mustChangePassword`)
- Any admin account created via `prisma/seed.js` or `scripts/create-admin.js` is seeded with `mustChangePassword: true`.
- Authentication middleware intercepts all requests: if `user.mustChangePassword === true`, all administrative API routes (e.g. `/admin/dashboard`, `/admin/users`, `/admin/brands`, `/admin/settings`) reject the request with HTTP 403 `PASSWORD_CHANGE_REQUIRED`.
- The user is only permitted to access `/api/v1/auth/change-password`, `/api/v1/auth/me`, and `/api/v1/auth/logout`.
- Once the password is successfully changed using a password adhering to the admin complexity policy, `mustChangePassword` is flipped to `false`.

---

## 5. Session Lifecycle & Token Security

### 5.1 Short-Lived Access Tokens
- Owner access tokens: Standard 24-hour expiration (`JWT_ACCESS_EXPIRES_IN`).
- **Admin access tokens**: Enforced 10-minute expiration (`JWT_ADMIN_ACCESS_EXPIRES_IN=10m`), signed with HMAC SHA-256 containing `{ id, role: 'ADMIN', status: 'ACTIVE' }`.

### 5.2 Revocable Refresh Tokens
- Refresh tokens are cryptographically hashed using SHA-256 before being stored in the `refresh_tokens` database table.
- Changing password or calling `POST /api/v1/auth/logout` sets `revokedAt = NOW()` across active tokens, invalidating any leaked or stolen refresh tokens.

### 5.3 Frontend Inactivity Session Timeout
- The Flutter Admin web/mobile portal (`lib/features/admin/presentation/widgets/admin_scaffold.dart`) wraps the entire administrative interface with an active gesture listener (`Listener` checking `onPointerDown` and `onPointerMove`).
- Any user interaction resets a 15-minute countdown timer.
- If 15 minutes elapse without interaction:
  1. The Flutter client invokes `ref.read(authControllerProvider.notifier).logout()`, sending a revocation request to the backend.
  2. Local secure storage tokens are cleared.
  3. The administrator is navigated back to `/login` with an informational snackbar notification.

---

## 6. Network & HTTP Hardening

1. **Helmet HTTP Headers**:
   - `Content-Security-Policy`: Default `'self'`, scripts `'self'`, styles `'self' 'unsafe-inline'`, connections restricted to API origins and specified admin origins.
   - `Referrer-Policy`: `strict-origin-when-cross-origin`.
   - `X-Content-Type-Options`: `nosniff`.
   - `X-Frame-Options`: `DENY` (prevents clickjacking).
2. **CORS Allowlist**:
   - `ADMIN_CORS_ORIGIN` (configured in `.env`, e.g. `http://localhost:3000,http://localhost:5173,https://admin.keraspare.et`).
   - Non-browser clients (native mobile app, curl) are permitted without Origin headers.
   - Unauthorized web origins receive a CORS rejection error.
3. **Payload Limits**:
   - JSON and URL-encoded body parser limits are capped at `1mb` to defend against denial-of-service memory exhaustion attacks.

---

## 7. Protected Administrator Provisioning CLI

To prevent public registration vulnerabilities:
- Public endpoint `POST /api/v1/auth/register` hardcodes `role: 'OWNER'`, stripping any `role` or privilege parameters supplied by the client.
- Administrative accounts must be created using the protected CLI script:
  ```bash
  # Interactive mode
  npm run create-admin

  # Script flags
  npm run create-admin -- --phone 0911223344 --name "System Operations" --password "SuperStrongPass123!#"
  ```
- The script validates the Ethiopian phone number format, checks the 12+ character complexity regex, creates the account with `mustChangePassword: true`, and writes an immutable `ADMIN_CREATED_CLI` entry to the `audit_logs` table.

---

## 8. Privacy & Data Leak Protection

- **No Passwords or Hashes**: Search queries and serialization exclude `passwordHash`.
- **Temporary Passwords**: Generated when an admin resets an owner's password (`POST /admin/users/:id/reset-password`). Returned **once** in the API response for the admin to convey to the owner, but recorded in the audit log solely as `{ passwordReset: true }` (the plain text is never logged).
- **Aggregates Only**: Admin dashboard numbers execute SQL `COUNT` queries only. No administrative route returns rows of `spare_parts`, `stock_movements`, or `sales`.

---

## 9. Stretch Goal: Two-Factor Authentication (TOTP) Design

### 9.1 Overview
Time-Based One-Time Password (TOTP) algorithm (RFC 6238) providing an additional authentication factor for administrative users.

### 9.2 Database Schema Migration
To support TOTP, the Prisma `User` model will be extended with:
```prisma
model User {
  // ... existing fields ...
  totpSecret    String?   @db.VarChar(128)  // AES-256 encrypted base32 secret
  totpEnabled   Boolean   @default(false)
  backupCodes   Json?                       // Hashed one-time recovery codes
  totpVerifiedAt DateTime? @db.Timestamp(6)
}
```

### 9.3 TOTP Workflow
1. **Enrollment (`POST /admin/2fa/setup`)**:
   - Admin requests 2FA setup.
   - Backend generates a 32-byte secret (`otplib` or `crypto`), creates an `otpauth://totp/KeraTracker:<phone>?secret=...&issuer=KeraTracker` URI.
   - Secret is encrypted with `APP_ENCRYPTION_KEY` and saved temporarily.
   - Generates 8 single-use 8-digit backup recovery codes (hashed with SHA-256 before storage).
   - Returns QR code data URL and manual setup key.
2. **Verification & Activation (`POST /admin/2fa/verify`)**:
   - Admin submits the 6-digit code generated by Google Authenticator / Authy.
   - If verified, sets `totpEnabled = true`.
   - Records `TOTP_ENABLED` in `audit_logs`.
3. **Login Integration (`POST /auth/admin/login`)**:
   - Step 1: Validates phone + password.
   - If `totpEnabled === true`, returns `{ tempToken, requires2FA: true }`.
   - Step 2 (`POST /auth/admin/login/verify-2fa`): Submits `{ tempToken, totpCode }`.
   - If valid (or valid backup code), issues full administrative JWT tokens.
