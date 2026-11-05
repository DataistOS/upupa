# Upupa Dart SDK

`upupa_dart` is a Dart client library designed to seamlessly interact with the Hedeh Go-based
backend API. It provides a structured, type-safe way to manage collections, records, authentication,
and more.

## Features

* **Type-Safe Record Operations**: Easily fetch lists, single records, create, update, and delete
  records with proper mapping.
* **Authentication Support**: Built-in authentication service integration.
* **Tested & Reliable**: Fully compatible with mock testing environments (`http.testing`).

## Installation

Add `upupa_dart` to your project's `pubspec.yaml` file. If you are using it locally:

```yaml
dependencies:
  upupa_dart:
    path: /path/to/your/upupa_dart
```

## Or via Git repository:

```yaml
dependencies:
  upupa_dart:
    git:
      url: https://github.com/DataistOS/upupa/tree/heuristic/upupa_dart.git
      ref: main
```

## Then, run the following command in your terminal:

```sh
dart pub get
```

## Quick Start

Here is a quick example of how to initialize the client and use the RecordService:

```dart
import 'package:upupa_dart/upupa_dart.dart';

void main() async {
  // 1. Initialize the client with your backend base URL
  final client = UpupaClient(baseUrl: 'http://localhost:8080');

  // 2. Initialize the RecordService
  final recordService = RecordService(client);

  try {
    // 3. Fetch a paginated list of records from a collection
    final response = await recordService.getList('posts', page: 1, perPage: 10);
    print('Fetched records: $response');
  } catch (e) {
    print('Error occurred: $e');
  }
}
```

## Running Tests

To run the unit test suite and verify SDK integration, execute:

```sh
dart test
```