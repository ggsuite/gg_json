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
  if (jsonGetOrNull<T>(json, path) == null) {
    throw Exception('Path "$path" does not exist.');
  }
  return jsonAddByArray(json: json, path: parseJsonPath(path), value: value);
}

// .............................................................................
/// Write a value into the json
Json jsonAddByArray<T>({
  required Json json,
  required Iterable<String> path,
  required T value,
}) {
  _checkType<T>(json, path);

  dynamic parent = json;

  for (int i = 0; i < path.length; i++) {
    var pathSegment = path.elementAt(i);
    final (segmentName, indices) = parseArrayIndex(pathSegment);

    if (segmentName.isEmpty) {
      continue;
    }

    // Create a child map, when needed
    if (parent is Map && !parent.containsKey(segmentName)) {
      parent[segmentName] = indices.isEmpty ? Json() : <dynamic>[];
    }
    // Chreate a child lists, when needed
    else if (parent is List<dynamic> && indices.isNotEmpty) {
      for (final index in indices) {
        if ((parent as List).length <= index) {
          final extendedList =
        }
        parent = parent[index];
      }
    }

    if (i == path.length - 1 && indices.isEmpty) {
      parent[segmentName] = value;
      break;
    }

    var child = parent[segmentName];

    if (child == null) {
      child = indices.isNotEmpty ? <dynamic>[] : <String, dynamic>{};
      parent[segmentName] = child;
    }

    if (child is List) {
      final last = indices.length - 1;
      for (var i = 0; i < indices.length; i++) {
        final index = indices.elementAt(i);
        final parentIndex = i == 0 ? null : indices.elementAt(i - 1);

        if ((child as List).length <= index) {
          // Increase length of the childNode
          child = [...child, ...List.filled(index - child.length + 1, null)];
          if (parent is List) {
            parent[parentIndex!] = child;
          } else {
            parent[segmentName] = child;
          }
        }

        if (i == last) {
          child[index] = value;
        } else {
          parent = child;
          child = child[index] ?? <dynamic>[];
        }
      }
    }

    parent = child;
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
void _checkType<T>(Json json, Iterable<String> path) {
  jsonGetByArrayOrNull<T>(
    json,
    path,
  ); // Will throw if existing value has a different type.
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
