# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Admin Login Incorrect Endpoint Routing
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists (admin logins incorrectly routed to `/auth/login` instead of `/auth/admin/login`)
  - **Scoped PBT Approach**: For this deterministic bug, scope the property to the concrete failing case: phone number "0900000000" with any valid password
  - Test implementation details from Bug Condition in design:
    - Create a test that intercepts or mocks the Dio HTTP client to capture the actual endpoint path called
    - Call `login()` method with phone "0900000000" and any password
    - Assert that the endpoint called is "/auth/admin/login" (NOT "/auth/login")
    - Test should work with various password values to confirm routing is phone-based only
    - Include edge case: phone " 0900000000 " with spaces (should detect after trimming)
  - The test assertions should match the Expected Behavior Properties from design:
    - Property 1: Admin login requests with phone "0900000000" should route to "/auth/admin/login"
    - Property 1: Backend should invoke `loginAdmin()` function (not `loginUser()`)
  - Run test on UNFIXED code at `lib/features/auth/data/repositories/api_auth_repository.dart`
  - **EXPECTED OUTCOME**: Test FAILS showing endpoint is "/auth/login" instead of "/auth/admin/login" (this is correct - it proves the bug exists)
  - Document counterexamples found to understand root cause:
    - Example: "login('0900000000', 'AdminPass123!') calls '/auth/login' but should call '/auth/admin/login'"
    - Example: "login(' 0900000000 ', 'password') calls '/auth/login' even after trimming"
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [-] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Owner Login Endpoint Routing Unchanged
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-admin phone numbers:
    - Run `login()` with various owner phone numbers (NOT "0900000000")
    - Observe that they all call "/auth/login" endpoint
    - Examples to test: "0912345678", "0987654321", "0123456789", " 0911111111 " (with spaces)
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements:
    - Property: For all phone numbers != "0900000000", endpoint should be "/auth/login"
    - Property: Owner authentication flow should produce identical results (tokens, profile storage)
    - Property: Offline authentication for owners should continue to work (local password hash)
    - Property: Android connectivity probing logic should continue to work for owners
    - Property: Account conflict detection should continue to work for owner switching
  - Property-based testing generates many test cases for stronger guarantees:
    - Generate random non-admin phone numbers (excluding "0900000000")
    - Test with various formats: with/without spaces, different digit patterns
    - Test with various password values to confirm endpoint routing is preserved
  - Run tests on UNFIXED code at `lib/features/auth/data/repositories/api_auth_repository.dart`
  - **EXPECTED OUTCOME**: Tests PASS on unfixed code (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ] 3. Fix for admin login endpoint routing bug

  - [~] 3.1 Implement conditional routing logic in ApiAuthRepository.login()
    - Open file: `lib/features/auth/data/repositories/api_auth_repository.dart`
    - Locate the `login()` method (approximately line 538)
    - Add admin phone detection logic before the Dio POST call (around line 559):
      ```dart
      final trimmedPhone = phoneNumber.trim();
      final isAdmin = trimmedPhone == '0900000000';
      final endpoint = isAdmin ? '/auth/admin/login' : '/auth/login';
      ```
    - Replace hardcoded '/auth/login' string in the POST call with the dynamic `endpoint` variable
    - Ensure the Android connectivity probing retry logic (around line 571) also uses the dynamic `endpoint` variable
    - Verify that `_handleSuccessfulAuthResponse()` works unchanged for both admin and owner responses
    - Verify that admin users (with `isAdmin: true`) are NOT saved to local Drift profiles table (existing check at line 585: `if (!user.isAdmin)`)
    - _Bug_Condition: isBugCondition(input) where input.phoneNumber.trim() = "0900000000" AND login_endpoint = "/auth/login"_
    - _Expected_Behavior: For admin phone "0900000000", route to "/auth/admin/login" endpoint which invokes backend loginAdmin() function (Property 1 from design)_
    - _Preservation: For all non-admin phone numbers, continue routing to "/auth/login" endpoint with unchanged authentication flow, offline support, Android probing, token management, and account conflict detection (Property 2 from design)_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

  - [~] 3.2 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Admin Login Correct Endpoint Routing
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior (admin routes to "/auth/admin/login")
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - Verify that admin phone "0900000000" now routes to "/auth/admin/login" endpoint
    - Verify that admin phone with spaces " 0900000000 " is detected after trimming
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed - admin logins correctly routed)
    - _Requirements: Property 1 from design - Admin Endpoint Routing for phone "0900000000"_

  - [~] 3.3 Verify preservation tests still pass
    - **Property 2: Preservation** - Owner Login Behavior Unchanged
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - Verify that all non-admin phone numbers still route to "/auth/login"
    - Verify that owner authentication flow produces identical results (tokens, profile storage)
    - Verify that offline authentication for owners still works
    - Verify that Android connectivity probing still works for owner logins
    - Verify that account conflict detection still works for owner switching
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions - owner logins unchanged)
    - Confirm all tests still pass after fix (no regressions introduced)

- [~] 4. Checkpoint - Ensure all tests pass
  - Run all bug condition and preservation tests together
  - Verify admin login routes to "/auth/admin/login" endpoint
  - Verify owner login still routes to "/auth/login" endpoint
  - Verify no regressions in owner authentication, offline login, Android probing, or account switching
  - If any tests fail, investigate and fix before proceeding
  - Ask the user if questions arise about test failures or unexpected behavior
