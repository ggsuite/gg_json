// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';

/// Cleans and parses JSON paths.
List<String> parseJsonPath(String path) {
  final result = path
      .split(RegExp('[./]'))
      .where((segment) => segment.isNotEmpty)
      .toList();

  _throwOnInvalidJsonPath(result);

  return result;
}

/// Throws an exception if the JSON path contains invalid characters.
void _throwOnInvalidJsonPath(List<String> segments) {
  for (final segment in segments) {
    if (!isValidJsonKey(segment)) {
      throw Exception('Invalid chars in path segment "$segment".');
    }
  }
}
