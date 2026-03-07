// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// .............................................................................
/// Cleans and parses JSON paths.
List<String> parseJsonPath(String path) {
  final result = path
      .split(RegExp('[./]'))
      .where((segment) => segment.isNotEmpty)
      .toList();

  return result;
}

// .............................................................................
/// Parses a path segment with optional array indices.
(String key, Iterable<int> indices) parseArrayIndex(String segment) {
  final regex = RegExp(r'^([^\[\]]+)(\[(\d+)\])*$');
  final match = regex.firstMatch(segment);

  if (match == null) {
    throw Exception('Invalid path segment "$segment".');
  }

  final key = match.group(1)!;
  final indices = <int>[];

  final indexRegex = RegExp(r'\[(\d+)\]');
  final indexMatches = indexRegex.allMatches(segment);

  for (final m in indexMatches) {
    indices.add(int.parse(m.group(1)!));
  }

  return (key, indices);
}
