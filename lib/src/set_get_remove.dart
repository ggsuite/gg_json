// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';

/// Allows to call json.set() and json.getOrNull() to write and read values
extension JsonGetSetRemove on Json {
  // ...........................................................................
  /// Adds a value at [path] in the JSON object.
  /// If the path does not exist, an exception is thrown.
  Json set<T>(String path, T value, {bool extend = false}) =>
      _Set<T>(json: this, path: path, value: value, extend: extend).result;

  /// Read a value from the JSON object.
  /// Returns null if the path does not exist.
  T? getOrNull<T>(String path) => _jsonGetOrNull<T>(this, path);

  /// Read a value from the JSON object.
  /// Throws when the path does not exist
  /// or an existing value is not of type [T].
  T get<T>(String path) => _jsonGet<T>(this, path);

  /// Removes a value from the JSON object.
  void removeValue(String path) =>
      _jsonRemoveByArray(this, parseJsonPath(path));
}

// .............................................................................
class _Set<T> {
  _Set({
    required this.json,
    required this.path,
    required this.value,
    required this.extend,
  }) : segments = parseJsonPath(path);

  final Json json;
  final String path;
  final List<String> segments;
  final T value;
  final bool extend;

  // ...........................................................................
  Json get result => _calc(path: segments, json: json);

  // ...........................................................................
  /// Write a value into the json
  Json _calc({required List<String> path, required Json json}) {
    if (path.isEmpty) {
      assert(value is Json);
      json.clear();
      json.addAll(value as Json);
      return json;
    }

    // Iterate all keys in the JSON
    final currentSegment = path.first;
    final (segmentName, indices) = parseArrayIndex(currentSegment);

    // Is the last segment? Set value.
    if (path.length == 1 && indices.isEmpty) {
      final existing = json[segmentName];
      _throwWhenMissing(segmentName, existing);
      _checkTypes(segmentName, json[segmentName], value);
      json[segmentName] = value;
      return json;
    }

    // No array indices?

    // If indices are not empty
    if (indices.isEmpty) {
      final existing = json[segmentName];
      _throwWhenMissing(segmentName, existing);

      final child = json[segmentName] ??= Json();

      // If value is not a map, throw an exception
      if (child is! Json) {
        throw Exception(
          'Segment "$segmentName" is of type "${child.runtimeType}". '
          'Map expected.',
        );
      }

      // Process next path segment
      if (path.length > 1) {
        final subPath = path.sublist(1);
        _calc(json: child, path: subPath);
      }
    }
    // Handle arrays
    else if (indices.isNotEmpty) {
      // Make sure value is a list
      final existing = json[segmentName];
      _throwWhenMissing(segmentName, existing);
      var child = json[segmentName] ??= <dynamic>[];
      dynamic parent = json;

      // If value is not a list, throw an exception
      if (child is! List) {
        throw Exception('Segment "$currentSegment" is not a list item.');
      }

      // Create sub arrays
      var i = 0;
      var last = indices.length - 1;
      for (final index in indices) {
        // Add missing items
        final missingItems = index + 1 - (child as List).length;
        if (missingItems > 0) {
          child = [...child, ...List<dynamic>.filled(missingItems, null)];
          if (i == 0) {
            parent[segmentName] = child;
          } else {
            parent[indices.elementAt(i - 1)] = child;
          }
        }

        // Add initial object
        final existing = child[index];
        _throwWhenMissing(segmentName, existing);
        parent = child;

        if (i == last) {
          if (path.length == 1) {
            _checkTypes(segmentName, child[index], value);
            child[index] = value;
            return json;
          } else {
            child = child[index] ??= <String, dynamic>{};
          }
        } else {
          child = child[index] ??= <dynamic>[];
        }

        i++;
      }

      // Process next path segment
      final subPath = path.sublist(1);
      _calc(json: child as Json, path: subPath);
    }

    return json; // coverage:ignore-line
  }

  void _throwWhenMissing(String key, dynamic existing) {
    if (!extend && existing == null) {
      throw Exception(
        [
          'Path segment "$key" of "$path" does not exist.',
          '',
          'Available paths:',
          ...json.ls(linePrefix: '  - '),
        ].join('\n'),
      );
    }
  }
}

/// Returns a value from the json by path. Returns null if not found.
T? _jsonGetOrNull<T>(Json json, String path) =>
    _jsonGetByArrayOrNull<T>(json, parseJsonPath(path));

/// Returns a value from the json by path. Throws if not found.
T _jsonGet<T>(Json json, String path) {
  final val = _jsonGetByArrayOrNull<T>(json, parseJsonPath(path));
  if (val == null) {
    throw Exception(
      [
        'Value at path "$path" not found.',
        '',
        'Available paths:',
        ...json.ls(linePrefix: '  - '),
      ].join('\n'),
    );
  }
  return val;
}

// .............................................................................
/// Returns a value from the json by path array
T? _jsonGetByArrayOrNull<T>(Json json, List<String> path) {
  if (path.isEmpty) {
    return json as T?;
  }

  // Iterate all keys in the JSON
  final currentSegment = path.first;
  final (segmentName, indices) = parseArrayIndex(currentSegment);

  // Is the last segment? Return value.
  if (path.length == 1 && indices.isEmpty) {
    final existing = json[segmentName];
    if (existing != null && existing is! T) {
      throw Exception(
        'Cannot get key "$segmentName": '
        '${existing.runtimeType} != $T.',
      );
    }
    return existing as T?;
  }

  // No array indices?

  // If indices are  empty
  if (indices.isEmpty) {
    final existing = json[segmentName];
    if (existing == null) {
      return null;
    }

    final child = existing;

    // If value is not a map, throw an exception
    if (child is! Json) {
      throw Exception('Segment "$segmentName" is not a Map.');
    }

    // Process next path segment
    if (path.length > 1) {
      final subPath = path.sublist(1);
      return _jsonGetByArrayOrNull<T>(child, subPath);
    }
  }
  // Handle arrays
  else if (indices.isNotEmpty) {
    // Make sure value is a list
    final existing = json[segmentName];
    if (existing == null) {
      return null;
    }

    var child = existing;

    // If value is not a list, throw an exception
    if (child is! List) {
      throw Exception('Segment "$segmentName" is not a list item.');
    }

    // Create sub arrays
    var i = 0;
    var last = indices.length - 1;
    for (final index in indices) {
      // Add missing items
      final missingItems = index + 1 - (child as List).length;
      if (missingItems > 0) {
        return null;
      }

      // Add initial object
      final existing = child[index];
      if (existing == null) {
        return null;
      }

      if (i == last) {
        if (path.length == 1) {
          return existing as T;
        } else {
          child = existing;
        }
      } else {
        child = existing;
      }

      i++;
    }

    // Process next path segment
    final subPath = path.sublist(1);
    return _jsonGetByArrayOrNull<T>(child as Json, subPath);
  }

  return null;
}

// .............................................................................
/// Removes a value from the JSON document.
void _jsonRemoveByArray(Json doc, Iterable<String> path) {
  var node = doc;
  for (int i = 0; i < path.length; i++) {
    final pathSegment = path.elementAt(i);
    if (!node.containsKey(pathSegment)) {
      break;
    }

    if (i == path.length - 1) {
      node.remove(pathSegment);
      break;
    }
    node = node[pathSegment] as Json;
  }
}

// .............................................................................
/// Throws when [existing] and [newElement] are of different types.
void _checkTypes(String key, dynamic existing, dynamic newElement) {
  if (existing == null) {
    return;
  }

  if (existing.runtimeType != newElement.runtimeType) {
    throw Exception(
      'Cannot write key "$key": ${existing.runtimeType} != '
      '${newElement.runtimeType}.',
    );
  }
}
