// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';

// .............................................................................
/// Deep copies a JSON document.
Json deepCopy(
  Json json, {
  bool throwOnNonJsonObjects = false,
  bool ignoreNonJsonObjects = false,
  bool Function(String key, dynamic value)? where,
}) {
  final copy = <String, dynamic>{};
  for (final entry in json.entries) {
    if (where != null && where(entry.key, entry.value) == false) {
      continue; // Skip this entry if where returns false
    }

    final key = entry.key;
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      copy[key] = deepCopy(
        value,
        throwOnNonJsonObjects: throwOnNonJsonObjects,
        ignoreNonJsonObjects: ignoreNonJsonObjects,
        where: where,
      );
    } else if (value is List<dynamic>) {
      copy[key] = deepCopyList(
        value,
        throwOnNonJsonObjects: throwOnNonJsonObjects,
        ignoreNonJsonObjects: ignoreNonJsonObjects,
        where: where,
      );
    } else {
      if (isJsonValue(value) == false) {
        if (throwOnNonJsonObjects) {
          throw ArgumentError.value(
            value,
            key,
            'Value $value is not a valid JSON value.',
          );
        }

        if (ignoreNonJsonObjects) {
          continue;
        }
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
  bool ignoreNonJsonObjects = false,
  bool Function(String key, dynamic value)? where,
}) {
  final copy = <dynamic>[];
  for (final element in list) {
    if (element is Map<String, dynamic>) {
      copy.add(
        deepCopy(
          element,
          throwOnNonJsonObjects: throwOnNonJsonObjects,
          ignoreNonJsonObjects: ignoreNonJsonObjects,
          where: where,
        ),
      );
    } else if (element is List<dynamic>) {
      copy.add(
        deepCopyList(
          element,
          throwOnNonJsonObjects: throwOnNonJsonObjects,
          ignoreNonJsonObjects: ignoreNonJsonObjects,
          where: where,
        ),
      );
    } else {
      if (isJsonValue(element) == false) {
        if (throwOnNonJsonObjects) {
          throw ArgumentError.value(
            element,
            'element',
            'Value $element is not a valid JSON value.',
          );
        } else if (ignoreNonJsonObjects) {
          continue;
        }
      }

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
  Json deepCopy({
    bool throwOnNonJsonObjects = true,
    bool ignoreNonJsonObjects = false,
    bool Function(String key, dynamic value)? where,
  }) => _ds(
    this,
    throwOnNonJsonObjects: throwOnNonJsonObjects,
    ignoreNonJsonObjects: ignoreNonJsonObjects,
    where: where,
  );
}
