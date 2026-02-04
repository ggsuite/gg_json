// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';

/// Lists all paths in the example JSON document.
extension JsonObjectPaths on Json {
  // ...........................................................................
  /// Lists all paths in the JSON object.
  List<String> ls({
    bool writeValues = false,
    Pattern? exclude,
    String linePrefix = '',
  }) {
    final result = <List<String>>[
      ['.'],
    ];
    _jsonLs(this, result, ['.'], writeValues: writeValues, exclude: exclude);

    return result.map((e) => e.join('/')).map((e) => '$linePrefix$e').toList();
  }
}

// ...........................................................................
/// List all paths in a JSON object
void _jsonLs(
  Map<String, dynamic> json,
  List<List<String>> paths,
  List<String> parent, {
  required bool writeValues,
  required Pattern? exclude,
}) {
  for (final key in json.keys) {
    // Exclude keys that match the exclude pattern
    if (exclude?.allMatches(key).isNotEmpty == true) {
      continue;
    }

    final val = json[key];
    final child = [...parent, key];

    // Handle maps
    if (val is Map<String, dynamic>) {
      paths.add(child);
      _jsonLs(val, paths, child, writeValues: writeValues, exclude: exclude);
    }
    // Handle lists
    else if (val is List) {
      paths.add(child);
      _lsList(val, paths, child, writeValues, exclude, parent, key);
    }
    // Handle other values
    else {
      final segment = writeValues ? '$key = $val' : key;
      paths.add([...parent, segment]);
    }
  }
}

// ...........................................................................
void _lsList(
  List<dynamic> val,
  List<List<String>> paths,
  List<String> child,
  bool writeValues,
  Pattern? exclude,
  List<String> parent,
  String key,
) {
  for (var i = 0; i < val.length; i++) {
    final path = [...child];
    path[path.length - 1] = '$key[$i]';

    // Handle map in list
    if (val[i] is Map<String, dynamic>) {
      _jsonLs(
        val[i] as Map<String, dynamic>,
        paths,
        path,
        writeValues: writeValues,
        exclude: exclude,
      );
    }
    // Handle list in list
    else if (val[i] is List) {
      _lsList(
        val[i] as List<dynamic>,
        paths,
        path,
        writeValues,
        exclude,
        parent,
        key,
      );
    }
    // Handle other values
    else {
      final segment = writeValues ? '$key[$i] = ${val[i]}' : '$key[$i]';
      paths.add([...parent, segment]);
    }
  }
}
