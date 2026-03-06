// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';

/// Filter method for [Json.ls]
typedef WhereProp = bool Function({String? key, dynamic value, String? path});

/// Lists all paths in the example JSON document.
extension JsonObjectPaths on Json {
  // ...........................................................................
  /// Lists all paths in the JSON object.
  List<String> ls({
    bool writeValues = false,
    bool alsoComplexValues = false,
    Pattern? exclude,
    String linePrefix = '',
    WhereProp? where,
  }) {
    final result = <List<String>>[];
    _add(
      parent: [],
      paths: result,
      key: '.',
      val: this,
      where: where,
      writeValues:
          alsoComplexValues, // Don't list root element when only simple values
      alsoComplexValues: alsoComplexValues,
    );

    _jsonLs(
      this,
      result,
      ['.'],
      writeValues: writeValues,
      alsoComplexValues: alsoComplexValues,
      exclude: exclude,
      where: where,
    );

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
  required bool alsoComplexValues,
  required Pattern? exclude,
  required WhereProp? where,
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
      _add(
        parent: parent,
        paths: paths,
        key: key,
        val: val,
        where: where,
        writeValues: writeValues,
        alsoComplexValues: alsoComplexValues,
      );

      _jsonLs(
        val,
        paths,
        child,
        writeValues: writeValues,
        alsoComplexValues: alsoComplexValues,
        exclude: exclude,
        where: where,
      );
    }
    // Handle lists
    else if (val is List) {
      _add(
        parent: parent,
        paths: paths,
        key: key,
        val: val,
        where: where,
        writeValues: writeValues,
        alsoComplexValues: alsoComplexValues,
      );

      _lsList(
        val,
        paths,
        child,
        writeValues,
        alsoComplexValues,
        exclude,
        parent,
        key,
        where,
      );
    }
    // Handle other values
    else {
      _add(
        parent: parent,
        paths: paths,
        key: key,
        val: val,
        where: where,
        writeValues: writeValues,
        alsoComplexValues: alsoComplexValues,
      );
    }
  }
}

// ...........................................................................
void _lsList(
  List<dynamic> val,
  List<List<String>> paths,
  List<String> child,
  bool writeValues,
  bool alsoComplexValues,
  Pattern? exclude,
  List<String> parent,
  String key,
  WhereProp? where,
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
        alsoComplexValues: alsoComplexValues,
        exclude: exclude,
        where: where,
      );
    }
    // Handle list in list
    else if (val[i] is List) {
      _lsList(
        val[i] as List<dynamic>,
        paths,
        path,
        writeValues,
        alsoComplexValues,
        exclude,
        parent,
        key,
        where,
      );
    }
    // Handle other values
    else {
      _add(
        parent: parent,
        paths: paths,
        key: '$key[$i]',
        val: val[i],
        where: where,
        writeValues: writeValues,
        alsoComplexValues: alsoComplexValues,
      );
    }
  }
}

// ...........................................................................
void _add({
  required List<String> parent,
  required List<List<String>> paths,
  required String key,
  required dynamic val,
  required WhereProp? where,
  required bool writeValues,
  required bool alsoComplexValues,
}) {
  if (where != null && !where(key: key, value: val, path: parent.join('/'))) {
    return;
  }

  if (!alsoComplexValues) {
    writeValues = writeValues && !isComplexJsonValue(val);
  }

  final segment = writeValues ? '$key = $val' : key;
  paths.add([...parent, segment]);
}
