// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// Returns true if [a] is a valid JSON value.
bool isJsonValue(dynamic a) {
  // Leaves are the most common case in a JSON tree, so check them first.
  if (a == null || a is String || a is num || a is bool) return true;

  if (a is Map<String, dynamic>) {
    for (final value in a.values) {
      if (!isJsonValue(value)) return false;
    }
    return true;
  }

  if (a is List<dynamic>) {
    for (var i = 0; i < a.length; i++) {
      if (!isJsonValue(a[i])) return false;
    }
    return true;
  }

  return false;
}

/// Returns true if value is a simple JSON value
bool isSimpleJsonValue(dynamic a) =>
    a == null || a is String || a is num || a is bool;

/// Returns true if value is a complex JSON value
bool isComplexJsonValue(dynamic a) =>
    a is Map<String, dynamic> || a is List<dynamic>;
