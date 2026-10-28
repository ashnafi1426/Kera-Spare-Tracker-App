# Login Server Connectivity Bug Design

## Overview

The app incorrectly displays "No internet connection" error during login even when the user has working internet connectivity. The root cause is that the `_probeWorkingCandidate()` method attempts to connect to multiple candidate backend server URLs with very short timeouts (1.5 seconds each). When none of the candidate URLs successfully connect—due to incorrect IP addresses, server being offline, or network delays—the app catches the `DioException` and interprets it as a complete lack of internet connectivity, rather than an inability to reach the specific backend server. This misleading error message confuses users who have working internet but cannot connect to the backend.

The fix will improve error messaging to distinguish between:
1. **No internet connectivity** (device has no network access)
2. **Cannot reach backend server** (device has internet but server is unreachable at configured URLs)

## Glossary

- **Bug_Condition (C)**: The condition where login fails due to connection issues - specifically when `_probeWorkingCandidate()` returns null and a `NetworkFailure` is returned, but device actually has internet connectivity
- **Property (P)**: The desired behavior when server is unreachable - app should display accurate error message indicating "Cannot reach server" rather than "No internet connection"
- **Preservation**: Existing offline login behavior for users with local cached credentials must remain unchanged
- **_probeWorkingCandidate**: Method in `ApiAuthRepository` (`lib/features/auth/data/repositories/api_auth_repository.dart`) that tests multiple candidate server URLs in parallel to find a reachable backend
- **candidateAndroidBaseUrls**: Static list in `AppConstants` containing candidate server URLs (localhost, USB reverse proxy, emulator, Wi-Fi LAN IPs)
- **NetworkFailure**: Failure type returned when Dio connection fails, currently interpreted as "no internet" even when server is simply unreachable

## Bug Details

### Bug Condition

The bug manifests when a user attempts to login with working internet connectivity, but the backend server is unreachable at all candidate URLs. The `login()` method in `ApiAuthRepository` catches `DioException`, calls `_probeWorkingCandidate()` which tests all candidate URLs with 1.5-second timeouts, finds none working, returns null, and then `_mapDioError(e)` returns a `NetworkFailure`. The login screen then interprets this `NetworkFailure` as "No internet connection" and displays the misleading message `authOfflineInternetRequired`.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type LoginAttempt {phoneNumber, password, deviceNetworkState, serverReachability}
  OUTPUT: boolean
  
  RETURN input.deviceNetworkState == CONNECTED
         AND input.serverReachability == UNREACHABLE_ALL_CANDIDATES
         AND errorMessageShown == "No internet connection"
END FUNCTION
```

### Examples

- **Example 1**: User has Wi-Fi connected to home network, backend server is running on laptop at 192.168.1.50:7000, but app's candidate list only contains 192.168.137.146, 192.168.137.43, etc. User presses login → app shows "Internet is required to register or log in" even though internet works
- **Example 2**: User has mobile data connected, backend server is offline (not running). User presses login → app shows "No internet connection" rather than "Cannot reach server - check if backend is running"
- **Example 3**: User has working Wi-Fi, backend server is running but firewall blocks port 7000. User presses login → app shows "No internet connection" rather than "Cannot connect to server - check firewall settings"
- **Edge case**: User has NO internet connectivity and no cached local credentials. User presses login → app SHOULD show "No internet connection" (correct behavior to preserve)

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Offline login with cached local credentials must continue to work exactly as before
- When user has NO internet and no local cached profile, showing "Internet is required" message is correct and should remain
- The candidate URL probing mechanism (`_probeWorkingCandidate`) should continue to test multiple URLs
- First-time login still requires internet connectivity (cannot login offline without cached credentials)
- All existing auth flows (register, token refresh, password change) should remain unaffected

**Scope:**
All inputs that do NOT involve the specific case of "user has internet BUT server is unreachable" should be completely unaffected by this fix. This includes:
- True offline scenarios (no Wi-Fi, no mobile data)
- Successful login scenarios (server reachable)
- Offline login with cached credentials
- Account suspension handling
- Token refresh handling

## Hypothesized Root Cause

Based on the bug description and code analysis, the most likely issues are:

1. **Insufficient Network State Detection**: The app relies on `DioException` type to determine network issues, but `DioException.connectionTimeout` / `connectionError` / `unknown` don't distinguish between "no internet" vs "server unreachable"
   - The `_probeWorkingCandidate()` method returns null when all candidates fail
   - There's no check of actual device connectivity state before displaying the error

2. **Misleading Error Mapping**: The `_mapDioError()` method maps `DioException` to `NetworkFailure` with message "No internet connection" without verifying actual connectivity
   - The login screen checks `if (failure is OfflineInternetRequiredFailure || failure.code == 'NO_INTERNET')` and shows "Internet is required" message

3. **Missing Connectivity Check**: The app has `connectivity_plus` package available but doesn't check `Connectivity().checkConnectivity()` before showing "No internet" error
   - Other parts of the codebase (e.g., `sync_push_service.dart`) properly use `Connectivity().checkConnectivity()` to verify actual internet state

4. **Short Timeout Values**: The 1.5-second timeout per candidate URL might be too aggressive for slower networks or high-latency scenarios
   - On networks with 1+ second latency, probes may fail even when server is reachable

## Correctness Properties

Property 1: Bug Condition - Accurate Error Message When Server Unreachable

_For any_ login attempt where the device has working internet connectivity (verified via `connectivity_plus`) but the backend server is unreachable at all candidate URLs (all probes timeout/fail), the login method SHALL return a distinct failure type indicating "Cannot reach backend server" rather than "No internet connection", allowing the UI to display accurate guidance such as "Cannot connect to server - check server settings or URL configuration".

**Validates: Requirements 2.1, 2.2, 2.3**

Property 2: Preservation - True Offline Detection

_For any_ login attempt where the device has NO internet connectivity (no Wi-Fi, no mobile data, `ConnectivityResult.none`), the login method SHALL continue to produce the same result as the original implementation: returning `OfflineInternetRequiredFailure` when no local cached credentials exist, or attempting offline login when cached credentials are available, preserving all existing offline-first behavior.

**Validates: Requirements 3.1, 3.2, 3.3**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `lib/features/auth/data/repositories/api_auth_repository.dart`

**Function**: `login()` method (starting around line 461)

**Specific Changes**:
1. **Add Connectivity Check**: After `_probeWorkingCandidate()` returns null, verify actual device connectivity using `Connectivity().checkConnectivity()` before determining error type
   - If device has NO connectivity (`ConnectivityResult.none`), return existing `OfflineInternetRequiredFailure`
   - If device HAS connectivity, return new `ServerUnreachableFailure` indicating backend is unreachable

2. **Create New Failure Type**: Add `ServerUnreachableFailure` class in `lib/core/errors/failure.dart`
   - Should have code `'SERVER_UNREACHABLE'`
   - Should have descriptive message like "Cannot reach backend server"
   - Should extend `Failure` class like other failure types

3. **Update Login Screen Error Handling**: Modify `login_screen.dart` (around line 115) to handle new failure type
   - Display distinct error message: "Cannot connect to server. Please check server settings."
   - Provide actionable button to open server configuration dialog
   - Keep existing "Internet is required" message for true offline scenarios

4. **Enhance _probeWorkingCandidate**: Optionally increase timeout from 1500ms to 3000ms per candidate
   - Current 1.5-second timeout may be too aggressive for slower networks
   - OR keep timeout but add more informative logging

5. **Update Error Localization**: Add new localized strings in `lib/l10n/app_*.arb` files
   - `authServerUnreachable`: "Cannot connect to server. Please check your server configuration."
   - Both English (`app_en.arb`) and Amharic (`app_am.arb`) translations

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the misleading error message on unfixed code, then verify the fix displays accurate error messages and preserves existing offline behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm that when device has internet but server is unreachable, app incorrectly shows "No internet connection" message.

**Test Plan**: Write tests that simulate login attempts with mocked connectivity state and unreachable server. Use mock `Connectivity` showing connected state and mock `Dio` that throws connection errors. Run these tests on the UNFIXED code to observe the misleading error message.

**Test Cases**:
1. **Wi-Fi Connected, Server Offline Test**: Mock `Connectivity` returns `ConnectivityResult.wifi`, mock all candidate URL probes to fail with connection timeout → expect bug to show "No internet connection" (will fail on unfixed code - incorrect message)
2. **Mobile Data Connected, Wrong IP Test**: Mock `Connectivity` returns `ConnectivityResult.mobile`, configure incorrect candidate URLs → expect bug to show "No internet connection" instead of "Server unreachable" (will fail on unfixed code)
3. **Connected Network, Firewall Block Test**: Mock connectivity as available, simulate firewall blocking all candidate ports → expect misleading error (will fail on unfixed code)
4. **True Offline Test**: Mock `Connectivity` returns `ConnectivityResult.none`, no cached credentials → should correctly show "Internet is required" (will pass on unfixed code - this is correct behavior)

**Expected Counterexamples**:
- When device is connected but server is unreachable, error message is "No internet connection" or "Internet is required to register or log in"
- Possible causes: no connectivity check before error message, wrong failure type returned, insufficient timeout values

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds (device has internet, server unreachable), the fixed function produces accurate error messaging.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := login_fixed(input)
  ASSERT result.failure.code == 'SERVER_UNREACHABLE'
  ASSERT errorMessageShown CONTAINS "Cannot connect to server" OR "Server unreachable"
  ASSERT errorMessageShown NOT CONTAINS "No internet connection"
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold (true offline scenarios, successful connections, cached credential flows), the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT login_original(input).errorType == login_fixed(input).errorType
  ASSERT login_original(input).successPath == login_fixed(input).successPath
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss (various connectivity states, different candidate URL configurations, timing variations)
- It provides strong guarantees that existing offline login, successful login, and other auth flows are unchanged

**Test Plan**: Observe behavior on UNFIXED code first for true offline scenarios and successful logins, then write property-based tests capturing that behavior.

**Test Cases**:
1. **True Offline Preservation**: Mock `ConnectivityResult.none`, verify login returns same `OfflineInternetRequiredFailure` as before fix
2. **Successful Login Preservation**: Mock working server at first candidate URL, verify login succeeds exactly as before
3. **Offline with Cached Credentials Preservation**: Mock no connectivity, existing local profile with password hash, verify offline login succeeds exactly as before
4. **Token Refresh Preservation**: Verify token refresh flows are unaffected by connectivity check changes
5. **Register Flow Preservation**: Verify registration flow error handling is unaffected

### Unit Tests

- Test new `ServerUnreachableFailure` class creation and properties
- Test connectivity check integration in login method (mock various `ConnectivityResult` values)
- Test error message display logic in login screen for new failure type
- Test that _probeWorkingCandidate failures + connectivity.wifi triggers new error path
- Test that _probeWorkingCandidate failures + connectivity.none triggers original error path

### Property-Based Tests

- Generate random combinations of connectivity states (wifi, mobile, none, ethernet, vpn) and server reachability states to verify correct error type returned
- Generate random candidate URL lists and connectivity states to verify preservation of offline login behavior
- Generate random timing variations in probe timeouts to verify robustness of connectivity detection

### Integration Tests

- Test full login flow with mock backend server turned off and mock Wi-Fi connectivity on → verify new error message displayed
- Test full login flow with mock no connectivity → verify original "Internet required" message displayed
- Test login → server becomes unreachable → token refresh attempt → verify correct error handling
- Test switching between true offline and server unreachable states during login process
