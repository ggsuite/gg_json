// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';

/// Lists all paths in the example JSON document.
extension JsonObjectPaths on Json {
  /// Lists all paths in the JSON object.
  List<String> ls({
    bool writeValues = true,
    Pattern? exclude,
    String separator = '/',
  }) => DirectJson(
    json: this,
  ).ls(writeValues: writeValues, exclude: exclude, separator: separator);
}
