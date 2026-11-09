# Changelog

## [0.5.1] - 2026-11-09

### Added
- **Backend (`upupa_backend`)**:
  - Implemented OTP request and login handlers (`otp.go`).
  - Added MFA setup and verification endpoints (`mfa.go`).
  - Integrated admin user impersonation handler (`impersonate.go`).
  - Added OAuth authentication routing and provider configuration (`oauth.go`).
  - Updated JSON encoder patterns across all auth handlers.

- **Dart SDK (`upupa_dart`)**:
  - Enhanced `AuthService` and `AuthStore` to support advanced authentication flows.
  - Added comprehensive unit tests for authentication services (`auth_service_test.dart`).
  - Updated collection service error handling and type-safety definitions.

- **Flutter Frontend (`upupa_frontend`)**:
  - Created OTP login form widget (`otp_login_form.dart`).
  - Added MFA setup and QR code configuration screen (`mfa_setup_screen.dart`).
  - Developed admin users management and impersonation screen (`admin_users_screen.dart`).
  - Updated navigation routes in `main.dart` for seamless access to security features.

## [v0.5.0] - 2026-11-08

### Added
- **Backend Modular Fields:** Implemented 13 distinct modular field types (bool, date, file, geopoint, json, number, relation, select, text, etc.) with a clean factory pattern under `upupa_backend/internal/features/collections/fields/`.
- **Frontend Field Widgets:** Created modular UI form widgets corresponding to all 13 field types in `upupa_frontend/lib/features/collections/widgets/fields/`.
- **`upupa_dart` SDK Enhancement:**
    - Fully implemented `CollectionService` and `RecordService` inside the SDK.
    - Added robust data models (`Field`, `Rule`, `Collection`, `Record`).
    - Added unit tests (`collection_service_test.dart`) using `http/testing`.
- **Docker Support:**
    - Added a multi-stage `Dockerfile` to compile both Flutter Web frontend and Go backend into a single unified container image.
    - Added `docker-compose.yaml` for seamless multi-container or single-stack orchestration.

### Changed
- Refactored `record_form.dart` and `collection_schema_screen.dart` to leverage the new modular field widgets and SDK services.
- Bumped project version to `0.5.0`.

## [0.1.1] - 2026-07-04

### Added
- Automated GitHub Actions release pipeline (`release.yml`).
- Integrated version tracking and automated build processes.

### Changed
- Updated `VERSION` to 0.1.1.
- Updated `upupa_frontend/pubspec.yaml` to version 0.1.1.