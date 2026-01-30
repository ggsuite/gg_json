// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:gg_json/gg_json.dart';

/// Allows to call json.set() and json.get() to write and read values
extension JsonStringGetSet on String {
  // ...........................................................................
  /// Lists all paths in the JSON object.
  String setJsonValue<T>(String path, T value, {bool prettyPrint = false}) =>
      jsonStringSet(this, path: path, value: value, prettyPrint: prettyPrint);

  /// Read a value from the JSON object.
  /// Returns null if the path does not exist.
  T? getJsonValue<T>(String path) => jsonStringGet<T>(this, path: path);

  /// Removes a value from the JSON object.
  String removeJsonValue(String path, {bool prettyPrint = false}) =>
      jsonStringRemove(this, path: path, prettyPrint: prettyPrint);
}

// ...........................................................................
/// Sets a value at [path] in a JSON string.
///
/// - If the path does not exist, it will be created.
/// - Throws when an existing value is not of type [T].
/// - Returns the updated JSON content.
String jsonStringSet<T>(
  String json, {
  required String path,
  required T value,
  bool prettyPrint = false,
}) {
  json = json.trim();
  if (json.isEmpty) {
    json = '{}';
  }
  final parsed = jsonDecode(json) as Json;
  parsed.add<T>(path, value);
  return prettyPrint
      ? const JsonEncoder.withIndent('  ').convert(parsed)
      : jsonEncode(parsed);
}

// ...........................................................................
/// Gets a value at [path] from a JSON string.
///
/// - Returns null if the value is not found.
/// - Throws when value is not of type [T].
T? jsonStringGet<T>(String json, {required String path}) {
  final parsed = jsonDecode(json) as Json;
  return parsed.getOrNull<T>(path);
}

// ...........................................................................
/// Removes a value at [path] from a JSON string.
///
/// - Returns the updated JSON content.
String jsonStringRemove(
  String json, {
  required String path,
  bool prettyPrint = false,
}) {
  final Json parsed = jsonDecode(json) as Json;
  parsed.removeValue(path);
  return prettyPrint
      ? const JsonEncoder.withIndent('  ').convert(parsed)
      : jsonEncode(parsed);
}
