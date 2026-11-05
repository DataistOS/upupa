# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-11-05

### Added

- **Core Client & Architecture**:
    - Initialized `upupa_dart` SDK structure to integrate with the Hedeh Go-based backend API.
    - Implemented core HTTP client (`UpupaClient`) and request/response handling.
    - Added robust exception handling (`exceptions.dart`) and local authentication state management
      (`auth_store.dart`).

- **Services & Models**:
    - Implemented `BaseService` as a foundation for API services.
    - Developed `AuthService` for handling authentication workflows.
    - Developed `RecordService` supporting comprehensive CRUD operations (`getList`, `getOne`,
      `create`, `update`, `delete`) with strict payload wrapping (`{"data": {...}}` for updates) and
      query parameter support.
    - Added core data models for `Collection` and `Record`.

- **Testing**:
    - Integrated comprehensive unit test suites using `http.testing` with `MockClient` to verify
      request construction and response parsing without requiring a live server.