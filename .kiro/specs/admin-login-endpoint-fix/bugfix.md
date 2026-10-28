# Bugfix Requirements Document

## Introduction

This document addresses a critical bug in the Kera Spare Parts Tracker app where admin users cannot successfully authenticate through the mobile application. The backend provides two distinct authentication endpoints (`/auth/login` for business owners and `/auth/admin/login` for administrators), but the Flutter application's `ApiAuthRepository` exclusively uses the `/auth/login` endpoint for all users, regardless of their role. This mismatch prevents administrators from logging in with their credentials (phone: 0900000000, password: AdminPassword123!) because the regular owner login endpoint does not properly authenticate admin accounts.

The fix must ensure that admin credentials are routed to the correct admin-specific endpoint while preserving all existing login functionality for regular business owners.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN a user attempts to login with admin credentials (phone: 0900000000) THEN the system calls the `/auth/login` endpoint instead of `/auth/admin/login`

1.2 WHEN the admin login request is sent to `/auth/login` THEN the backend's `loginUser()` function processes the request instead of `loginAdmin()`

1.3 WHEN admin credentials are authenticated through the wrong endpoint THEN the authentication fails or does not apply admin-specific security measures (rate limiting, IP-based lockout, audit logging)

1.4 WHEN the Flutter app receives the admin user's phone number THEN the system does not detect that it requires admin-specific authentication

### Expected Behavior (Correct)

2.1 WHEN a user attempts to login with admin credentials (phone: 0900000000) THEN the system SHALL call the `/auth/admin/login` endpoint

2.2 WHEN admin credentials are sent to `/auth/admin/login` THEN the backend's `loginAdmin()` function SHALL process the request with admin-specific security measures

2.3 WHEN admin authentication succeeds through the correct endpoint THEN the system SHALL receive proper admin tokens and role information

2.4 WHEN the Flutter app detects admin phone number (0900000000) THEN the system SHALL route the authentication request to the admin login endpoint

### Unchanged Behavior (Regression Prevention)

3.1 WHEN a regular business owner attempts to login with their credentials THEN the system SHALL CONTINUE TO call the `/auth/login` endpoint

3.2 WHEN regular owner credentials are sent to `/auth/login` THEN the backend's `loginUser()` function SHALL CONTINUE TO process the request normally

3.3 WHEN regular owner authentication succeeds THEN the system SHALL CONTINUE TO store tokens, sync local data, and handle offline authentication as before

3.4 WHEN the login method encounters network errors or connectivity issues THEN the system SHALL CONTINUE TO handle Android loopback/Wi-Fi candidate probing and offline fallback authentication

3.5 WHEN account switching is detected with unsynced changes THEN the system SHALL CONTINUE TO enforce conflict detection and protection

3.6 WHEN tokens expire or are revoked THEN the system SHALL CONTINUE TO handle refresh token logic and needsLogin state management

3.7 WHEN password hash is stored locally THEN the system SHALL CONTINUE TO enable offline login for previously authenticated users

## Bug Condition Derivation

### Bug Condition Function

```pascal
FUNCTION isBugCondition(X)
  INPUT: X of type LoginRequest {phoneNumber: string, password: string}
  OUTPUT: boolean
  
  // Returns true when the login request is for an admin user
  RETURN X.phoneNumber = "0900000000"
END FUNCTION
```

### Property Specification

```pascal
// Property: Fix Checking - Admin Endpoint Routing
FOR ALL X WHERE isBugCondition(X) DO
  endpoint ← determineLoginEndpoint(X)
  ASSERT endpoint = "/auth/admin/login"
END FOR
```

### Preservation Goal

```pascal
// Property: Preservation Checking - Owner Login Unchanged
FOR ALL X WHERE NOT isBugCondition(X) DO
  ASSERT loginBehavior_Fixed(X) = loginBehavior_Original(X)
  ASSERT endpoint_Fixed(X) = "/auth/login"
END FOR
```

This ensures that:
- **Fix Checking**: Admin credentials (phone: 0900000000) are routed to `/auth/admin/login`
- **Preservation Checking**: All non-admin login requests continue to use `/auth/login` with identical behavior
