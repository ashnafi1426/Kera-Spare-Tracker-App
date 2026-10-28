# Admin Login Endpoint Routing Bugfix Design

## Overview

The Flutter app's `ApiAuthRepository` incorrectly routes all login requests to the `/auth/login` endpoint, which is intended only for business owners. Admin accounts (phone: 0900000000) must authenticate through the dedicated `/auth/admin/login` endpoint, which invokes the backend's `loginAdmin()` function with admin-specific security measures (rate limiting, IP-based lockout, audit logging).

This fix implements phone number-based routing logic to detect admin credentials and direct them to the correct endpoint, while preserving all existing owner login functionality without modification.

**Impact**: Admin users can successfully authenticate through the mobile app using their credentials.

**Scope**: Changes are isolated to the `login()` method in `ApiAuthRepository`. No database schema changes, UI modifications, or other repository changes required.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug - when the phone number is the admin phone (0900000000)
- **Property (P)**: The desired behavior for admin login - routing to `/auth/admin/login` endpoint
- **Preservation**: Existing owner login behavior that must remain unchanged - routing to `/auth/login` endpoint for all non-admin phone numbers
- **ApiAuthRepository**: The Dio-based authentication repository in `lib/features/auth/data/repositories/api_auth_repository.dart` that handles API calls
- **login() method**: The method at approximately line 555 that currently calls `/auth/login` for all users
- **Admin phone number**: The fixed identifier `0900000000` that distinguishes admin accounts from owner accounts
- **Endpoint routing**: The process of selecting the correct HTTP endpoint based on user type

## Bug Details

### Bug Condition

The bug manifests when a user attempts to login with the admin phone number (0900000000). The `login()` method in `ApiAuthRepository` unconditionally calls the `/auth/login` endpoint at line 559, which is designed for business owners and invokes the backend's `loginUser()` function. This causes authentication to fail or bypass admin-specific security measures because admin credentials must be authenticated through `/auth/admin/login` which invokes `loginAdmin()`.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type LoginRequest {phoneNumber: string, password: string}
  OUTPUT: boolean
  
  RETURN input.phoneNumber.trim() = "0900000000"
         AND login_endpoint = "/auth/login"
         AND backend_function_invoked = "loginUser()"
END FUNCTION
```

### Examples

- **Admin Login Attempt**: User enters phone "0900000000" and password "AdminPassword123!" → App calls `/auth/login` → Backend invokes `loginUser()` → Authentication fails or bypasses admin security measures → **Expected**: Should call `/auth/admin/login` and invoke `loginAdmin()`

- **Owner Login Attempt**: User enters phone "0912345678" and password "ownerpass" → App calls `/auth/login` → Backend invokes `loginUser()` → Authentication succeeds normally → **Expected**: Behavior should remain unchanged

- **Admin Login with Spaces**: User enters phone " 0900000000 " (with leading/trailing spaces) → App calls `/auth/login` after trimming → Authentication fails → **Expected**: Should detect trimmed phone "0900000000" and call `/auth/admin/login`

- **Different Admin Phone Format**: If backend adds more admin accounts in the future, current implementation cannot distinguish them → **Note**: Current design assumes single admin phone number; future enhancement may require role-based detection from backend

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- All business owner login requests (any phone number != "0900000000") must continue to call `/auth/login` endpoint
- Android loopback/Wi-Fi candidate probing logic must continue to work for both admin and owner logins
- Offline authentication fallback must continue to work for owner accounts (admin accounts may not have offline support)
- Account switching conflict detection with unsynced changes must continue to work
- Token refresh logic and needsLogin state management must continue to work
- Password hash storage for offline login must continue to work for owner accounts
- Multi-account owner switching protection must continue to work

**Scope:**
All inputs where the phone number is NOT "0900000000" should be completely unaffected by this fix. This includes:
- All owner login requests with regular phone numbers
- Network error handling and connectivity probing
- Offline authentication with local password hash
- Token management and refresh interceptor logic
- Account conflict detection and resolution

## Hypothesized Root Cause

Based on the bug description and code analysis, the issue is straightforward:

1. **Hardcoded Endpoint**: The `login()` method at line 559 in `ApiAuthRepository` uses a hardcoded endpoint string `/auth/login` for all users without any conditional logic to check the phone number.

2. **No Admin Detection**: There is no code that inspects the `phoneNumber` parameter to determine if it matches the admin phone number (0900000000).

3. **Single Code Path**: Both admin and owner login attempts flow through the identical code path with no branching logic based on user type.

4. **Missing Backend Knowledge**: The Flutter app is unaware that the backend has two separate endpoints (`/auth/login` and `/auth/admin/login`) and two separate functions (`loginUser()` and `loginAdmin()`).

**Root Cause Confirmation**: The fix is a straightforward addition of conditional routing logic before the Dio POST call.

## Correctness Properties

Property 1: Bug Condition - Admin Endpoint Routing

_For any_ login request where the phone number (after trimming) equals "0900000000", the fixed `login()` method SHALL call the `/auth/admin/login` endpoint instead of `/auth/login`, causing the backend to invoke `loginAdmin()` with admin-specific security measures and authentication logic.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4**

Property 2: Preservation - Owner Login Unchanged

_For any_ login request where the phone number (after trimming) does NOT equal "0900000000", the fixed `login()` method SHALL produce exactly the same behavior as the original method, preserving the `/auth/login` endpoint call, offline authentication fallback, Android connectivity probing, token management, and all other existing functionality.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct (hardcoded endpoint without admin detection):

**File**: `lib/features/auth/data/repositories/api_auth_repository.dart`

**Function**: `login()` (approximately line 538)

**Specific Changes**:

1. **Add Admin Detection Logic**: Before the Dio POST call at line 559, add a conditional check to determine if the trimmed phone number equals "0900000000".

2. **Determine Endpoint Dynamically**: Store the endpoint path in a variable based on the admin detection result:
   - If admin: `endpoint = '/auth/admin/login'`
   - If owner: `endpoint = '/auth/login'`

3. **Use Dynamic Endpoint Variable**: Replace the hardcoded `/auth/login` string in the POST call with the dynamic endpoint variable.

4. **Apply to Android Probe Retry**: Ensure that the retry logic after Android candidate probing (around line 571) also uses the same dynamic endpoint variable, not a hardcoded string.

5. **Implementation Pseudocode**:
   ```dart
   Future<Result<AuthUser>> login({
     required String phoneNumber,
     required String password,
     bool forceDiscardUnsynced = false,
   }) async {
     try {
       final trimmedPhone = phoneNumber.trim();
       final isAdmin = trimmedPhone == '0900000000';
       final endpoint = isAdmin ? '/auth/admin/login' : '/auth/login';
       
       final deviceId = await _sessionStore.getOrCreateDeviceId();
       final response = await dio.post(
         endpoint,  // <-- Dynamic endpoint instead of hardcoded '/auth/login'
         data: {
           'phoneNumber': trimmedPhone,
           'password': password.trim(),
           'deviceId': deviceId,
         },
       );
       
       return await _handleSuccessfulAuthResponse(
         response.data['data'] as Map<String, dynamic>,
         password: password,
         forceDiscardUnsynced: forceDiscardUnsynced,
       );
     } on DioException catch (e) {
       // ... existing Android probing logic ...
       // IMPORTANT: Ensure retry also uses the dynamic 'endpoint' variable
     }
   }
   ```

6. **No Changes to Response Handling**: The `_handleSuccessfulAuthResponse()` method should work unchanged because both `/auth/login` and `/auth/admin/login` return the same response structure with `accessToken`, `refreshToken`, and `user` object.

7. **No Database Changes**: Admin users have `isAdmin: true` in their AuthUser model, so they should NOT be saved to the local Drift `profiles` table (the existing code at line 585 already has this check: `if (!user.isAdmin)`).

8. **No Offline Authentication for Admin**: Admin accounts will NOT have offline authentication support (no local password hash, no local profile row), which is acceptable because admins require online authentication for security.

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code (admin login fails or bypasses security), then verify the fix routes correctly and preserves all existing owner login behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm that admin login attempts are incorrectly routed to `/auth/login` and fail or bypass admin security measures.

**Test Plan**: Write tests that simulate admin login with phone "0900000000" and observe which endpoint is called. Use Dio interceptors or mock HTTP client to capture the actual endpoint path. Run these tests on the UNFIXED code to observe incorrect routing and authentication failure.

**Test Cases**:
1. **Admin Login Endpoint Test**: Call `login()` with phone "0900000000" and capture the endpoint path → Will show `/auth/login` instead of `/auth/admin/login` (will fail on unfixed code)
2. **Admin Login Authentication Test**: Attempt full authentication with admin credentials → Will fail with authentication error or bypass admin security (will fail on unfixed code)
3. **Admin Login with Spaces Test**: Call `login()` with phone " 0900000000 " (with spaces) → Should detect after trimming but will route to wrong endpoint (will fail on unfixed code)
4. **Owner Login Baseline Test**: Call `login()` with owner phone "0912345678" and verify it uses `/auth/login` → Should pass even on unfixed code (baseline)

**Expected Counterexamples**:
- Admin login attempts call `/auth/login` instead of `/auth/admin/login`
- Backend returns authentication error or does not apply admin-specific security measures
- Possible backend errors: "Invalid credentials", "Account not found", or successful authentication without admin security features

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds (phone = "0900000000"), the fixed function routes to the correct admin endpoint.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  endpoint := determineLoginEndpoint_fixed(input.phoneNumber)
  ASSERT endpoint = "/auth/admin/login"
  
  result := login_fixed(input.phoneNumber, input.password)
  ASSERT result.isSuccess OR (result.isFailure AND failure is NOT EndpointRoutingFailure)
END FOR
```

**Test Cases**:
1. **Admin Endpoint Routing Test**: Verify that phone "0900000000" routes to `/auth/admin/login`
2. **Admin Authentication Success Test**: Mock successful backend response and verify full authentication flow works
3. **Admin Token Storage Test**: Verify that admin authentication stores tokens correctly
4. **Admin No Offline Profile Test**: Verify that admin user is NOT saved to local Drift profiles table

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold (phone != "0900000000"), the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  endpoint_original := "/auth/login"
  endpoint_fixed := determineLoginEndpoint_fixed(input.phoneNumber)
  ASSERT endpoint_fixed = endpoint_original
  
  // Verify identical behavior for non-admin logins
  ASSERT login_original(input) ≈ login_fixed(input)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain (various phone numbers)
- It catches edge cases that manual unit tests might miss (phone numbers with spaces, different formats, etc.)
- It provides strong guarantees that behavior is unchanged for all non-admin inputs

**Test Plan**: Observe behavior on UNFIXED code first for owner logins with various phone numbers, then write property-based tests capturing that the endpoint routing, response handling, and token storage remain identical after the fix.

**Test Cases**:
1. **Owner Endpoint Routing Preservation**: Generate random owner phone numbers (not "0900000000") and verify they all route to `/auth/login`
2. **Owner Authentication Preservation**: Verify that owner login success flow remains unchanged (tokens, profile storage, password hash)
3. **Offline Authentication Preservation**: Verify that owner offline authentication with local password hash continues to work
4. **Android Probing Preservation**: Verify that Android loopback/Wi-Fi candidate probing continues to work for owner logins
5. **Account Conflict Preservation**: Verify that multi-account owner switching conflict detection continues to work
6. **Token Refresh Preservation**: Verify that token refresh interceptor logic continues to work for owner tokens

### Unit Tests

- Test admin phone detection logic with exact match "0900000000"
- Test admin phone detection with leading/trailing spaces " 0900000000 "
- Test owner phone numbers are NOT detected as admin (various formats)
- Test endpoint selection returns "/auth/admin/login" for admin
- Test endpoint selection returns "/auth/login" for owners
- Test that admin authentication response is handled correctly by `_handleSuccessfulAuthResponse()`
- Test that admin user is NOT saved to local Drift profiles table

### Property-Based Tests

- Generate random phone numbers (excluding "0900000000") and verify they all route to `/auth/login`
- Generate random phone numbers with various whitespace patterns and verify admin detection after trimming
- Generate random password strings and verify endpoint routing is based only on phone number, not password
- Test that forceDiscardUnsynced flag does not affect endpoint routing logic
- Test that all owner phone numbers produce identical endpoint routing before and after fix

### Integration Tests

- Test full admin login flow from UI input through API call to token storage
- Test full owner login flow remains unchanged after fix
- Test Android connectivity probing with admin credentials
- Test admin login failure handling (network errors, authentication errors)
- Test that admin user cannot perform offline authentication (no local profile)
- Test account switching from owner to admin (no conflict detection because admin has no local data)
- Test account switching from admin to owner (normal owner authentication flow)
