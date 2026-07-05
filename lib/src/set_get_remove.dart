// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:collection';

import 'package:gg_json/gg_json.dart';

/// Allows to call json.set() and json.getOrNull() to write and read values
extension JsonGetSetRemove on Json {
  // ...........................................................................
  /// Adds a value at [path] in the JSON object.
  /// If the path does not exist, an exception is thrown.
  ///
  /// Compiled path segments are cached per isolate, keyed by the raw path
  /// string. Repeated calls with the same path string therefore perform no
  /// parsing and run in O(segments) with no per-call allocations.
  Json set<T>(String path, T value, {bool extend = false}) {
    final segments = compileJsonPath(path);
    final segmentCount = segments.length;

    // An empty path replaces the whole object.
    if (segmentCount == 0) {
      assert(value is Json);
      clear();
      addAll(value as Json);
      return this;
    }

    final lastSegmentIndex = segmentCount - 1;
    Json node = this;

    // Walk all segments but the last one.
    for (var s = 0; s < lastSegmentIndex; s++) {
      final segment = segments[s];
      final key = segment.key;
      final indices = segment.indices;
      final existing = node[key];

      // No array indices? Descend into or create the child map.
      if (indices.isEmpty) {
        if (existing is Json) {
          node = existing;
        } else if (existing == null) {
          if (!extend) {
            _throwMissingSegment(this, key, path);
          }
          final child = Json();
          node[key] = child;
          node = child;
        } else {
          throw Exception(
            'Segment "$key" is of type "${existing.runtimeType}". '
            'Map expected.',
          );
        }
      }
      // Handle arrays
      else {
        node = _descendArray(this, node, existing, segment, path, extend);
      }
    }

    // Handle the last segment.
    final segment = segments[lastSegmentIndex];
    final key = segment.key;
    final indices = segment.indices;
    final existing = node[key];

    // No array indices? Set the value directly.
    if (indices.isEmpty) {
      if (existing == null) {
        if (!extend) {
          _throwMissingSegment(this, key, path);
        }
      } else if (!(existing is num && value is num) &&
          existing.runtimeType != value.runtimeType) {
        _throwTypeMismatch(key, existing, value);
      }
      node[key] = value;
      return this;
    }

    // Handle arrays
    _setInArray(this, node, existing, segment, path, value, extend);
    return this;
  }

  /// Read a value from the JSON object.
  /// Returns null if the path does not exist.
  ///
  /// Compiled path segments are cached per isolate, keyed by the raw path
  /// string. Repeated calls with the same path string therefore perform no
  /// parsing and run in O(segments) with no per-call allocations.
  T? getOrNull<T>(String path, {bool throwWhenNotFound = false}) {
    final result = _getBySegments<T>(this, compileJsonPath(path));
    if (result == null && throwWhenNotFound) {
      _throwNotFound(this, path);
    }
    return result;
  }

  /// Read a value from the JSON object.
  /// Throws when the path does not exist
  /// or an existing value is not of type [T].
  T get<T>(String path) {
    final result = _getBySegments<T>(this, compileJsonPath(path));
    if (result == null) {
      _throwNotFound(this, path);
    }
    return result;
  }

  /// Removes a value from the JSON object.
  void removeValue(String path) =>
      _jsonRemoveByArray(this, _parseLiteralPath(path));
}

// .............................................................................
/// Writes [value] into the array at the last path [segment].
void _setInArray(
  Json root,
  Json node,
  dynamic existing,
  JsonPathSegment segment,
  String path,
  Object? value,
  bool extend,
) {
  final key = segment.key;
  final indices = segment.indices;
  final list = _enterArray(root, node, existing, segment, path, extend);
  dynamic child = list;
  dynamic parent = node;
  final lastIndex = indices.length - 1;
  for (var i = 0; i <= lastIndex; i++) {
    final index = indices[i];
    var current = child as List;

    // Add missing items via a grown copy assigned back to the parent.
    if (index >= current.length) {
      final grown = _growList(current, index + 1);
      if (i == 0) {
        parent[key] = grown;
      } else {
        parent[indices[i - 1]] = grown;
      }
      current = grown;
      child = grown;
    }

    final item = current[index];
    if (item == null && !extend) {
      _throwMissingSegment(root, key, path);
    }
    parent = current;

    if (i == lastIndex) {
      _checkTypes(key, item, value);
      current[index] = value;
      return;
    }

    if (item != null) {
      child = item;
    } else {
      final sub = <dynamic>[];
      current[index] = sub;
      child = sub;
    }
  }
}

// .............................................................................
/// Descends into an array segment while setting values.
/// Returns the map found or created at the segment's last index.
Json _descendArray(
  Json root,
  Json node,
  dynamic existing,
  JsonPathSegment segment,
  String path,
  bool extend,
) {
  final key = segment.key;
  final indices = segment.indices;
  dynamic child = _enterArray(root, node, existing, segment, path, extend);
  dynamic parent = node;
  final lastIndex = indices.length - 1;
  for (var i = 0; i <= lastIndex; i++) {
    final index = indices[i];
    var current = child as List;

    // Add missing items via a grown copy assigned back to the parent.
    if (index >= current.length) {
      final grown = _growList(current, index + 1);
      if (i == 0) {
        parent[key] = grown;
      } else {
        parent[indices[i - 1]] = grown;
      }
      current = grown;
      child = grown;
    }

    final item = current[index];
    if (item == null && !extend) {
      _throwMissingSegment(root, key, path);
    }
    parent = current;

    if (i == lastIndex) {
      // The last index holds the map to descend into.
      if (item != null) {
        child = item;
      } else {
        final map = <String, dynamic>{};
        current[index] = map;
        child = map;
      }
    } else {
      // Intermediate indices hold nested lists.
      if (item != null) {
        child = item;
      } else {
        final sub = <dynamic>[];
        current[index] = sub;
        child = sub;
      }
    }
  }

  return child as Json;
}

// .............................................................................
/// Returns the list stored at an array segment's key,
/// creating it when missing and [extend] is true.
List<dynamic> _enterArray(
  Json root,
  Json node,
  dynamic existing,
  JsonPathSegment segment,
  String path,
  bool extend,
) {
  if (existing == null) {
    if (!extend) {
      _throwMissingSegment(root, segment.key, path);
    }
    final list = <dynamic>[];
    node[segment.key] = list;
    return list;
  }

  // If value is not a list, throw an exception
  if (existing is! List) {
    throw Exception('Segment "${segment.raw}" is not a list item.');
  }
  return existing;
}

// .............................................................................
/// Returns a growable copy of [list] with [newLength] items,
/// filling missing slots with nulls.
List<dynamic> _growList(List<dynamic> list, int newLength) {
  final grown = List<dynamic>.filled(newLength, null, growable: true);
  for (var j = 0; j < list.length; j++) {
    grown[j] = list[j];
  }
  return grown;
}

// .............................................................................
/// Returns a value from the json by compiled path segments.
/// Returns null if not found.
T? _getBySegments<T>(Json json, List<JsonPathSegment> segments) {
  final segmentCount = segments.length;
  if (segmentCount == 0) {
    return json as T?;
  }

  final lastSegmentIndex = segmentCount - 1;
  Json node = json;

  for (var s = 0; s < segmentCount; s++) {
    final segment = segments[s];
    final key = segment.key;
    final indices = segment.indices;
    final isLastSegment = s == lastSegmentIndex;

    // No array indices?
    if (indices.isEmpty) {
      final existing = node[key];

      // Is the last segment? Return value.
      if (isLastSegment) {
        if (existing != null && existing is! T) {
          throw Exception(
            'Cannot get key "$key": '
            '${existing.runtimeType} != $T.',
          );
        }
        return existing as T?;
      }

      if (existing == null) {
        return null;
      }

      // If value is not a map, throw an exception
      if (existing is! Json) {
        throw Exception('Segment "$key" is not a Map.');
      }

      // Process next path segment
      node = existing;
    }
    // Handle arrays
    else {
      final existing = node[key];
      if (existing == null) {
        return null;
      }

      // If value is not a list, throw an exception
      if (existing is! List) {
        throw Exception('Segment "$key" is not a list item.');
      }

      dynamic child = existing;
      final lastIndex = indices.length - 1;
      for (var i = 0; i <= lastIndex; i++) {
        final index = indices[i];
        final list = child as List;
        if (index >= list.length) {
          return null;
        }

        final item = list[index];
        if (item == null) {
          return null;
        }

        if (i == lastIndex && isLastSegment) {
          return item as T;
        }
        child = item;
      }

      // Process next path segment
      node = child as Json;
    }
  }

  return null; // coverage:ignore-line
}

// .............................................................................
/// Cache mapping raw path strings to their literal segments as used by
/// removeValue, which treats segments as literal map keys.
///
/// Caching parsed path strings is safe because strings are immutable.
/// Dart globals are per-isolate, so no locking is needed.
final HashMap<String, List<String>> _literalPathCache =
    HashMap<String, List<String>>();

/// Maximum number of cached literal paths.
/// When the cache is full it is cleared. Overflow is rare in practice.
const int _maxCachedLiteralPaths = 4096;

/// Parses [path] into literal segments, using the cache.
/// The returned list is shared and must not be modified.
List<String> _parseLiteralPath(String path) {
  final cached = _literalPathCache[path];
  if (cached != null) {
    return cached;
  }
  final result = parseJsonPath(path);
  if (_literalPathCache.length >= _maxCachedLiteralPaths) {
    _literalPathCache.clear();
  }
  _literalPathCache[path] = result;
  return result;
}

// .............................................................................
/// Removes a value from the JSON document.
void _jsonRemoveByArray(Json doc, List<String> path) {
  var node = doc;
  final lastSegmentIndex = path.length - 1;
  for (var i = 0; i < path.length; i++) {
    final pathSegment = path[i];
    if (i == lastSegmentIndex) {
      node.remove(pathSegment);
      return;
    }

    final child = node[pathSegment];
    if (child == null && !node.containsKey(pathSegment)) {
      return;
    }
    node = child as Json;
  }
}

// .............................................................................
/// Throws when a path segment does not exist and extend is false.
Never _throwMissingSegment(Json root, String key, String path) {
  throw Exception(
    [
      'Path segment "$key" of "$path" does not exist.',
      '',
      'Available paths:',
      ...root.ls(linePrefix: '  - '),
    ].join('\n'),
  );
}

// .............................................................................
/// Throws when a value at [path] is not found.
Never _throwNotFound(Json root, String path) {
  throw Exception(
    [
      'Value at path "$path" not found.',
      '',
      'Available paths:',
      ...root.ls(linePrefix: '  - '),
    ].join('\n'),
  );
}

// .............................................................................
/// Throws when [existing] and [newElement] are of different types.
void _checkTypes(String key, dynamic existing, dynamic newElement) {
  if (existing == null) {
    return;
  }

  if (existing is num && newElement is num) {
    return;
  }

  if (existing.runtimeType != newElement.runtimeType) {
    _throwTypeMismatch(key, existing, newElement);
  }
}

// .............................................................................
/// Throws a type-mismatch error when writing [newElement] over [existing].
Never _throwTypeMismatch(String key, Object? existing, Object? newElement) {
  throw Exception(
    'Cannot write key "$key": ${existing.runtimeType} != '
    '${newElement.runtimeType}.',
  );
}
