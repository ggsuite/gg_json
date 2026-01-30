// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';

/// Allows to call json.set() and json.get() to write and read values
extension JsonGetSet on Json {
  // ...........................................................................
  /// Lists all paths in the JSON object.
  Json set<T>(String path, T value) =>
      jsonSet(json: this, path: path, value: value);

  /// Read a value from the JSON object.
  /// Returns null if the path does not exist.
  T? get<T>(String path) => jsonGetByArrayOrNull<T>(this, parseJsonPath(path));

  /// Removes a value from the JSON object.
  void removeValue(String path) => jsonRemoveByArray(this, parseJsonPath(path));
}

// .............................................................................
/// Write a value into the json
Json jsonSet<T>({required Json json, required String path, required T value}) =>
    jsonSetByArray(json: json, path: parseJsonPath(path), value: value);

// .............................................................................
/// Write a value into the json
Json jsonSetByArray<T>({
  required Json json,
  required Iterable<String> path,
  required T value,
}) {
  _checkType<T>(json, path);

  Json node = json;

  for (int i = 0; i < path.length; i++) {
    var pathSegment = path.elementAt(i);
    if (pathSegment.isEmpty) {
      continue;
    }

    if (i == path.length - 1) {
      node[pathSegment] = value;
      break;
    }

    var childNode = node[pathSegment] as Json?;
    if (childNode == null) {
      childNode = {};
      node[pathSegment] = childNode;
    }
    node = childNode;
  }

  return json;
}

// ...........................................................................
/// Returns a value from the json by path array
T? jsonGetByArrayOrNull<T>(Json json, Iterable<String> path) {
  var node = json;
  for (var i = 0; i < path.length; i++) {
    final pathSegment = path.elementAt(i);
    if (!node.containsKey(pathSegment)) {
      return null;
    }
    if ((i == path.length - 1)) {
      final val = node[pathSegment];
      if (val is T == false) {
        throw Exception('Existing value $val is not of type $T.');
      }
      return node[pathSegment] as T;
    }
    node = node[pathSegment] as Json;
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
