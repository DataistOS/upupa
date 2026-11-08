# Upupa Frontend

The official administrative web dashboard and client UI for the **Upupa** ecosystem, built with Flutter.

## Overview

`upupa_frontend` provides a modular, feature-first management interface designed to interact seamlessly with the Upupa Go backend via the `upupa_dart` SDK. It includes complete support for dynamic collection schema builders, 13 modular field types, record data grids, authentication flows, and system backups.

## Key Features

- **Modular Field Widgets:** Fully integrated UI components for all 13 core field types (text, number, relation, file, select, geopoint, etc.).
- **Collection Management:** Dynamic schema creation, editing, and field configuration.
- **Record Explorer:** Advanced data tables and forms for managing collection records with relational support.
- **Authentication & Security:** Secure login, token management, and password recovery interfaces.
- **Settings & Administration:** System preferences, activity logs, and database backup tools.

## Getting Started

This project serves as the Flutter frontend for the Upupa backend. To run the application locally:

1. Ensure you have the [Flutter SDK](https://docs.flutter.dev/) installed (compatible with Dart 3.3+).
2. Install dependencies:
   ```bash
   flutter pub get