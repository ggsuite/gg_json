// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// Returns true if [a] is a valid JSON value.
bool isJsonValue(dynamic a) {
  if (a is Map<String, dynamic>) {
    for (final value in a.values) {
      if (!isJsonValue(value)) return false;
    }
    return true;
  } else if (a is List<dynamic>) {
    for (final element in a) {
      if (!isJsonValue(element)) return false;
    }
    return true;
  } else {
    return a is String || a is num || a is bool || a == null;
  }
}
