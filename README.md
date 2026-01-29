# gg_json

`gg_json` offers small, composable helpers for working with JSON-like `Map<String, dynamic>` structures in Dart. It focuses on utility functions that make it easier to copy, inspect, and share JSON payloads across tests, tooling, and Flutter/Dart applications.

## Features

- Deep-copy JSON maps and lists while preserving nested structure.
- Access a curated `exampleJson` payload for demos, tests, or docs.
- Lightweight: no hidden dependencies beyond the Dart SDK.

## Install

Add the package to your project:

```sh
dart pub add gg_json
```

Import the helpers where you need them:

```dart
import 'package:gg_json/gg_json.dart';
```

## Usage

Deep copy a JSON map

```dart
import 'package:gg_json/gg_json.dart';

void main() {
  final data = {
    'user': {'name': 'Ada', 'skills': ['math', 'logic']},
    'active': true,
  };

  final clone = deepCopy(data);
  clone['user']?['skills']?.add('computing');

  // Original data remains untouched.
  print(data['user']?['skills']); // [math, logic]
  print(clone['user']?['skills']); // [math, logic, computing]
}
```
