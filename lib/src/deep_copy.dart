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
  if (where == null && !throwOnNonJsonObjects && !ignoreNonJsonObjects) {
    return _deepCopyFast(json);
  }
  return _deepCopyGeneral(
    json,
    throwOnNonJsonObjects,
    ignoreNonJsonObjects,
    where,
  );
}

// .............................................................................
/// Deep copies a JSON List.
List<dynamic> deepCopyList(
  List<dynamic> list, {
  bool throwOnNonJsonObjects = true,
  bool ignoreNonJsonObjects = false,
  bool Function(String key, dynamic value)? where,
}) {
  if (where == null && !throwOnNonJsonObjects && !ignoreNonJsonObjects) {
    return _deepCopyListFast(list);
  }
  return _deepCopyListGeneral(
    list,
    throwOnNonJsonObjects,
    ignoreNonJsonObjects,
    where,
  );
}

// .............................................................................
// Fast path: no filtering, no validation. Map.of / toList bulk-copy the
// container (simple values come along for free); afterwards only nested
// Maps/Lists are replaced by their deep copies.
Json _deepCopyFast(Json json) {
  final copy = Map<String, dynamic>.of(json);
  json.forEach((key, value) {
    if (value is Map<String, dynamic>) {
      copy[key] = _deepCopyFast(value);
    } else if (value is List) {
      copy[key] = _deepCopyListFast(value);
    }
  });
  return copy;
}

// .............................................................................
List<dynamic> _deepCopyListFast(List<dynamic> list) {
  // List<dynamic>.of (not toList) so a typed source list cannot make the
  // copy reject retyped nested elements.
  final copy = List<dynamic>.of(list);
  final length = copy.length;
  for (var i = 0; i < length; i++) {
    final element = copy[i];
    if (element is Map<String, dynamic>) {
      copy[i] = _deepCopyFast(element);
    } else if (element is List) {
      copy[i] = _deepCopyListFast(element);
    }
  }
  return copy;
}

// .............................................................................
// General path: handles where filters and non-JSON value policies.
Json _deepCopyGeneral(
  Json json,
  bool throwOnNonJsonObjects,
  bool ignoreNonJsonObjects,
  bool Function(String key, dynamic value)? where,
) {
  final copy = <String, dynamic>{};
  for (final entry in json.entries) {
    if (where != null && where(entry.key, entry.value) == false) {
      continue; // Skip this entry if where returns false
    }

    final key = entry.key;
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      copy[key] = _deepCopyGeneral(
        value,
        throwOnNonJsonObjects,
        ignoreNonJsonObjects,
        where,
      );
    } else if (value is List<dynamic>) {
      copy[key] = _deepCopyListGeneral(
        value,
        throwOnNonJsonObjects,
        ignoreNonJsonObjects,
        where,
      );
    } else {
      // Value is neither Map nor List here, so the simple check suffices.
      if (isSimpleJsonValue(value) == false) {
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
List<dynamic> _deepCopyListGeneral(
  List<dynamic> list,
  bool throwOnNonJsonObjects,
  bool ignoreNonJsonObjects,
  bool Function(String key, dynamic value)? where,
) {
  final copy = <dynamic>[];
  for (final element in list) {
    if (element is Map<String, dynamic>) {
      copy.add(
        _deepCopyGeneral(
          element,
          throwOnNonJsonObjects,
          ignoreNonJsonObjects,
          where,
        ),
      );
    } else if (element is List<dynamic>) {
      copy.add(
        _deepCopyListGeneral(
          element,
          throwOnNonJsonObjects,
          ignoreNonJsonObjects,
          where,
        ),
      );
    } else {
      // Element is neither Map nor List here, so the simple check suffices.
      if (isSimpleJsonValue(element) == false) {
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
