// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';

// .............................................................................
/// Deep copies a JSON document.
Json deepCopy(Json json) {
  final copy = <String, dynamic>{};
  for (final entry in json.entries) {
    final key = entry.key;
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      copy[key] = deepCopy(value);
    } else if (value is List<dynamic>) {
      copy[key] = deepCopyList(value);
    } else {
      copy[key] = value;
    }
  }
  return copy;
}

// .............................................................................
/// Deep copies a JSON List.
List<dynamic> deepCopyList(List<dynamic> list) {
  final copy = <dynamic>[];
  for (final element in list) {
    if (element is Map<String, dynamic>) {
      copy.add(deepCopy(element));
    } else if (element is List<dynamic>) {
      copy.add(deepCopyList(element));
    } else {
      copy.add(element);
    }
  }
  return copy;
}
