// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';

// .............................................................................
/// Deep copies a JSON document.
Json deepCopy(Json json, {bool throwOnNonJsonObjects = true}) {
  final copy = <String, dynamic>{};
  for (final entry in json.entries) {
    final key = entry.key;
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      copy[key] = deepCopy(value, throwOnNonJsonObjects: throwOnNonJsonObjects);
    } else if (value is List<dynamic>) {
      copy[key] = deepCopyList(
        value,
        throwOnNonJsonObjects: throwOnNonJsonObjects,
      );
    } else {
      if (throwOnNonJsonObjects && isJsonValue(value) == false) {
        throw ArgumentError.value(
          value,
          key,
          'Value $value is not a valid JSON value.',
        );
      }
      copy[key] = value;
    }
  }
  return copy;
}

// .............................................................................
/// Deep copies a JSON List.
List<dynamic> deepCopyList(
  List<dynamic> list, {
  bool throwOnNonJsonObjects = true,
}) {
  final copy = <dynamic>[];
  for (final element in list) {
    if (element is Map<String, dynamic>) {
      copy.add(deepCopy(element, throwOnNonJsonObjects: throwOnNonJsonObjects));
    } else if (element is List<dynamic>) {
      copy.add(
        deepCopyList(element, throwOnNonJsonObjects: throwOnNonJsonObjects),
      );
    } else {
      copy.add(element);
    }
  }
  return copy;
}

const _ds = deepCopy;

// .............................................................................
/// Allows to call json.deepCopy()
extension DeepCopyJson on Json {
  /// Returns a deep copy of this JSON document.
  Json deepCopy({bool throwOnNonJsonObjects = true}) =>
      _ds(this, throwOnNonJsonObjects: throwOnNonJsonObjects);
}
