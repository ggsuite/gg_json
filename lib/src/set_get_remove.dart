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
  /// If the path does not exist, it will be created.
  Json add<T>(String path, T value) =>
      jsonAdd(json: this, path: path, value: value);

  /// Adds a value at [path] in the JSON object.
  /// If the path does not exist, an exception is thrown.
  Json set<T>(String path, T value) =>
      jsonSet(json: this, path: path, value: value);

  /// Read a value from the JSON object.
  /// Returns null if the path does not exist.
  T? getOrNull<T>(String path) => jsonGetOrNull<T>(this, path);

  /// Read a value from the JSON object.
  /// Throws when the path does not exist
  /// or an existing value is not of type [T].
  T get<T>(String path) => jsonGet<T>(this, path);

  /// Removes a value from the JSON object.
  void removeValue(String path) => jsonRemoveByArray(this, parseJsonPath(path));
}

// .............................................................................
/// Write a value into the json.
/// If the path does not exist, it will be created.
Json jsonAdd<T>({required Json json, required String path, required T value}) =>
    jsonAddByArray(json: json, path: parseJsonPath(path), value: value);

/// Write a value into the json.
/// If the path does not exist, an exception is thrown.
Json jsonSet<T>({required Json json, required String path, required T value}) {
  return jsonAddByArray(
    json: json,
    path: parseJsonPath(path),
    value: value,
    throwWhenPathMissing: true,
  );
}

// .............................................................................
/// Write a value into the json
Json jsonAddByArray<T>({
  required Json json,
  required List<String> path,
  required T value,
  bool throwWhenPathMissing = false,
}) {
  // Iterate all keys in the JSON
  final currentSegment = path.first;
  final (segmentName, indices) = parseArrayIndex(currentSegment);

  // Is the last segment? Set value.
  if (path.length == 1 && indices.isEmpty) {
    final existing = json[segmentName];
    _throwWhenMissing(segmentName, existing, throwWhenPathMissing);
    _checkTypes(segmentName, json[segmentName], value);
    json[segmentName] = value;
    return json;
  }

  // No array indices?

  // If indices are not empty
  if (indices.isEmpty) {
    final existing = json[segmentName];
    _throwWhenMissing(segmentName, existing, throwWhenPathMissing);

    final child = json[segmentName] ??= Json();

    // If value is not a map, throw an exception
    if (child is! Json) {
      throw Exception('Segment "$segmentName" is not a Map.');
    }

    // Process next path segment
    if (path.length > 1) {
      final subPath = path.sublist(1);
      jsonAddByArray<T>(
        json: child,
        path: subPath,
        value: value,
        throwWhenPathMissing: throwWhenPathMissing,
      );
    }
  }
  // Handle arrays
  else if (indices.isNotEmpty) {
    // Make sure value is a list
    final existing = json[segmentName];
    _throwWhenMissing(segmentName, existing, throwWhenPathMissing);
    var child = json[segmentName] ??= <dynamic>[];
    dynamic parent = json;

    // If value is not a list, throw an exception
    if (child is! List) {
      throw Exception('Segment "$segmentName" is not a List.');
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
      _throwWhenMissing(segmentName, existing, throwWhenPathMissing);
      parent = child;

      if (i == last) {
        if (path.length == 1) {
          _checkTypes(segmentName, child[index], value);
          child[index] = value;
          return json;
        } else {
          child[index] ??= <String, dynamic>{};
        }
      } else {
        child = child[index] ??= <dynamic>[];
      }

      i++;
    }

    // Process next path segment
    if (path.length > 1) {
      final subPath = path.sublist(1);
      jsonAddByArray<T>(
        json: child as Json,
        path: subPath,
        value: value,
        throwWhenPathMissing: throwWhenPathMissing,
      );
    } else {
      // Set the value
      _checkTypes(segmentName, (child as Json)[segmentName], value);
      (child)[segmentName] = value;
    }
  }

  return json;
}

/// Returns a value from the json by path. Returns null if not found.
T? jsonGetOrNull<T>(Json json, String path) =>
    jsonGetByArrayOrNull<T>(json, parseJsonPath(path));

/// Returns a value from the json by path. Throws if not found.
T jsonGet<T>(Json json, String path) {
  final val = jsonGetByArrayOrNull<T>(json, parseJsonPath(path));
  if (val == null) {
    throw Exception('Value at path "$path" not found.');
  }
  return val;
}

// ...........................................................................
/// Returns a value from the json by path array
T? jsonGetByArrayOrNull<T>(Json json, Iterable<String> path) {
  dynamic node = json;
  var last = path.length - 1;
  for (var i = 0; i < path.length; i++) {
    final pathSegment = path.elementAt(i);
    final (segmentName, indices) = parseArrayIndex(pathSegment);

    if (node is Map && !node.containsKey(segmentName)) {
      return null;
    } else if (node is List<dynamic> && indices.isNotEmpty) {
      for (final index in indices) {
        if ((node as List).length <= index) {
          return null;
        }
        node = node[index];
      }
    }

    if (node is Map) {
      node = node[segmentName] as dynamic;
    }

    if (node is List) {
      for (final index in indices) {
        if (index >= (node as List).length) {
          return null;
        }
        node = node[index];
        if (i == last) {
          return node as T;
        }
      }
    }
  }

  return null;
}

// ...........................................................................
/// Removes a value from the JSON document.
void jsonRemoveByArray(Json doc, Iterable<String> path) {
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

void _throwWhenMissing(
  String key,
  dynamic existing,
  bool throwWhenPathMissing,
) {
  if (throwWhenPathMissing && existing == null) {
    throw Exception('Path segment "$key" does not exist.');
  }
}
