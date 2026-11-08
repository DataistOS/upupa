# Changelog

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