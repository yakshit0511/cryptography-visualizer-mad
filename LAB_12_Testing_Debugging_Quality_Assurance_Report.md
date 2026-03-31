# LAB 12 - Testing, Debugging and Quality Assurance Report
## Project: Cryptography Visualizer (Flutter, Firebase, Cloudinary)

### Student Details
- Student Name: ____________________
- Roll No: ____________________
- Course / Semester: ____________________
- Lab Title: Testing, Debugging and Quality Assurance
- Submission Date: 31 March 2026

---

## 1. Abstract
This report presents the testing, debugging, and quality assurance activities performed for the Cryptography Visualizer mobile application. The application is built with Flutter and integrates Firebase Authentication, Cloud Firestore, local/device notifications, and Cloudinary for profile image uploads. The objective of this lab work is to verify functional correctness, state consistency, data integrity, and user experience reliability across key workflows such as authentication, profile management, cipher operations, and history tracking.

---

## 2. Project Overview
### 2.1 Objective
The Cryptography Visualizer project provides an interactive platform for learning and practicing classical cryptographic techniques. The key goals are:
- Execute Caesar, Playfair, and Hill cipher operations.
- Visualize encryption and decryption flow for learning.
- Store and review cipher history.
- Maintain user profile and usage statistics.

### 2.2 Technology Stack
- Frontend: Flutter (Dart)
- State Management: Provider
- Backend: Firebase Authentication and Cloud Firestore
- Notifications: Firebase Messaging and flutter_local_notifications
- Profile Image Upload: Cloudinary (unsigned upload preset)
- Test Platform: Android physical device (SM A356E), Windows development host

### 2.3 Major Modules
- Authentication (login, signup, session state)
- Home dashboard (welcome card and counters)
- Cipher modules (Caesar, Playfair, Hill)
- History module (create, read, update, delete)
- Profile module (name, phone, gender, image)
- Drawer and route-based navigation

---

## 3. Testing Strategy
### 3.1 Test Types
1. Functional testing
2. UI and UX testing
3. Integration testing
4. Data persistence testing
5. Negative testing and error handling
6. Regression testing after each fix
7. Exploratory manual testing

### 3.2 Test Environment
- Operating System: Windows
- Device: Samsung SM A356E (Android)
- Build Mode: Debug
- Flutter Channel: Stable
- Firebase Project: cryptography-visualizer
- Network Checks: Wi-Fi and mobile data switching

### 3.3 Entry Criteria
- Application compiles successfully.
- Firebase is initialized.
- Authentication flow is operational.
- Test user account is available.

### 3.4 Exit Criteria
- Critical user journeys pass end-to-end.
- No blocking crash in primary flows.
- Firestore read/write behavior is consistent.
- Updated profile photo is visible in both profile and home screens.

---

## 4. Functional Test Cases

### 4.1 Authentication
| Test ID | Scenario | Steps | Expected Result | Status |
|---|---|---|---|---|
| AUTH-01 | Signup with valid data | Enter valid email and password, submit | Account created and user redirected | Pass |
| AUTH-02 | Login with valid credentials | Enter registered email and password | Login successful, home screen opens | Pass |
| AUTH-03 | Login with wrong password | Enter valid email and incorrect password | Error feedback shown | Pass |
| AUTH-04 | Logout | Trigger logout from drawer | Session cleared and login screen displayed | Pass |

### 4.2 Cipher Module
| Test ID | Scenario | Steps | Expected Result | Status |
|---|---|---|---|---|
| CIPH-01 | Caesar encrypt | Provide text and shift, tap encrypt | Correct encrypted output | Pass |
| CIPH-02 | Caesar decrypt | Provide encrypted text and shift, tap decrypt | Original text restored | Pass |
| CIPH-03 | Playfair encrypt | Provide key and plaintext | Correct digraph output with steps | Pass |
| CIPH-04 | Playfair visual behavior | Run conversion animation | Correct arrow direction and highlighting | Pass |
| CIPH-05 | Save result to history | Save output from cipher screen | New history record created and counter updated | Pass |

### 4.3 History CRUD
| Test ID | Scenario | Steps | Expected Result | Status |
|---|---|---|---|---|
| HIST-01 | Create history item | Save cipher result | Item persisted in Firestore | Pass |
| HIST-02 | Read history | Open history screen | Records displayed in expected order | Pass |
| HIST-03 | Update/recalculate | Edit and recalculate an item | Record updated successfully | Pass |
| HIST-04 | Delete history item | Delete with confirmation | Item removed and UI refreshed | Pass |
| HIST-05 | Empty state | Remove all records | Empty state UI is shown correctly | Pass |

### 4.4 Profile and Media
| Test ID | Scenario | Steps | Expected Result | Status |
|---|---|---|---|---|
| PROF-01 | Load profile data | Open profile screen | Name, phone, and gender loaded | Pass |
| PROF-02 | Edit profile fields | Change values and save | Firestore updated | Pass |
| PROF-03 | Upload profile image | Tap avatar and select image | Cloudinary URL saved in Firestore | Pass |
| PROF-04 | Home avatar sync | Return to home after upload | Home avatar updates immediately | Pass |
| PROF-05 | Cancel upload | Open picker and cancel | No crash; user feedback shown | Pass |

---

## 5. Defect Report and Debugging Log

### 5.1 Defect Summary Table
| Defect ID | Title | Severity | Status |
|---|---|---|---|
| DEF-01 | Firebase Storage dependency conflict | High | Closed |
| DEF-02 | Firebase billing setup blocked (`OR_BACR2_44`) | High | Closed (workaround) |
| DEF-03 | Home avatar not updating after profile image change | High | Closed |
| DEF-04 | Cipher counter refresh delay | Medium | Closed |

### 5.2 Detailed Defects
### Defect 1: Firebase Storage dependency conflict
- Symptom: Build failed due to package resolution/version mismatch.
- Root Cause: `firebase_storage` dependency was incompatible with existing Firebase dependency constraints.
- Fix: Removed Firebase Storage integration for profile upload path and migrated to Cloudinary.
- Verification: Build and runtime upload path function correctly with Cloudinary.

### Defect 2: Firebase billing activation blocked
- Symptom: Profile image upload failed; billing flow returned `OR_BACR2_44`.
- Root Cause: Cloud Storage activation could not be completed due to billing verification failure.
- Fix: Implemented Cloudinary unsigned upload flow.
- Verification: Uploaded image URL is stored and retrieved successfully.

### Defect 3: Home avatar did not refresh after profile image update
- Symptom: New profile image was visible on profile screen but not on home screen.
- Root Cause:
1. Uploaded URL was not propagated into provider state immediately.
2. Home avatar renderer expected local file path only.
- Fix:
1. Pushed uploaded URL to provider right after successful upload.
2. Updated home image renderer to support both URL and local file paths.
3. Added URL/path discrimination to prevent invalid file handling.
- Verification: Home avatar updates immediately after upload.

### Defect 4: Counter update delay
- Symptom: Cipher counters occasionally appeared stale after operations.
- Root Cause: State refresh and persistence update were not fully synchronized in some flows.
- Fix: Improved local state mutation, listener notification, and refresh sequence.
- Verification: Counters now update consistently across sessions and screen transitions.

---

## 6. Debugging Techniques Used
1. Flutter analyzer and IDE Problems panel.
2. Runtime console log analysis from `flutter run`.
3. Layer-wise isolation of issue source:
   - Service layer
   - Provider state layer
   - UI render layer
4. Controlled reproduction with fixed steps.
5. Fix-verify-regression cycle for each resolved defect.

---

## 7. Quality Assurance Activities
### 7.1 Code Quality
- Applied structured async error handling via try/catch.
- Maintained separation of concerns among UI, providers, and services.
- Enforced input validation for profile fields.

### 7.2 Reliability and Data Integrity
- User-scoped profile and history operations by authenticated identity.
- Persistence checks across app restarts and login cycles.
- Fallback UI behavior for image loading failures.

### 7.3 UX Verification
- Snackbar feedback for action outcomes.
- Confirmation prompts for destructive actions.
- Loading indicators for async tasks.
- Empty/error states validated for history and profile flows.

### 7.4 Security Review
- Authentication required for profile/history data flows.
- No API secret exposed in mobile code for Cloudinary upload.
- Sensitive values handled cautiously in client configuration.

---

## 8. Regression Testing Summary
Regression checks were run after each major bug fix for the following flows:
1. Login -> Home -> Profile -> Upload -> Home sync
2. Cipher operation -> Save history -> Counter update
3. Logout -> Login -> Data restore
4. History CRUD operations
5. Playfair animation and visual path rendering

Result: No new blocking regressions were observed in primary user journeys.

---

## 9. Performance and Stability Observations
- App startup and navigation are smooth on target Android device.
- No critical runtime crashes observed during the test cycle.
- Provider-driven UI updates are responsive.
- Network-dependent actions fail gracefully with user feedback.

---

## 10. Limitations and Future Improvements
1. Add unit tests for cipher and provider logic.
2. Add widget tests for profile and home avatar synchronization.
3. Add integration tests for complete authentication-to-history flows.
4. Add retry and backoff strategy for transient network upload failures.
5. Introduce optional signed-upload backend flow for stricter media control.

---

## 11. Conclusion
The Cryptography Visualizer project was systematically tested and debugged under Lab 12 objectives. Core workflows, including authentication, cipher execution, history CRUD, profile editing, and cross-screen state synchronization, are stable and verified. Key blockers were diagnosed and resolved through targeted fixes and controlled regression testing. The project demonstrates acceptable software quality for academic submission and live demonstration.

---

## 12. Appendix A - Evidence Checklist
- Build and dependency resolution logs reviewed.
- Runtime logs inspected for state and upload workflows.
- Firestore records verified for profile and history updates.
- UI behavior validated on physical Android device.

## 13. Appendix B - Files Referenced During QA
- lib/screens/profile/profile_screen.dart
- lib/screens/home/home_screen.dart
- lib/services/user_profile_service.dart
- lib/providers/auth_provider.dart
- lib/providers/cipher_provider.dart
- lib/screens/ciphers/playfair_cipher_screen.dart
- lib/services/history_service.dart
- BUG_FIXES_SUMMARY.md
- CRUD_TESTING_GUIDE.md
- IMPLEMENTATION_SUMMARY.md
