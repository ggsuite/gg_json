// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:gg_json/gg_json.dart';

/// Easily read and write values directly to and from JSON documents.
class DirectJson {
  /// Creates a new instance from a JSON document.
  DirectJson({this.json = const {}, this.prettyPrint = false});

  /// Creates a new instance from a JSON string.
  factory DirectJson.fromString({
    required String json,
    bool prettyPrint = false,
    Pattern? exclude,
  }) => DirectJson(
    prettyPrint: prettyPrint,
    json: json.isEmpty ? {} : jsonDecode(json) as Json,
  );

  /// The underlying JSON document.
  final Json json;

  /// The JSON document as a string.
  String get jsonString => _encoder(prettyPrint).convert(json);

  // ######################
  // ls
  // ######################

  // ...........................................................................
  /// Lists all paths in a JSON document
  List<String> ls({
    bool writeValues = true,
    Pattern? exclude,
    String separator = '/',
  }) {
    return json.ls(
      writeValues: writeValues,
      exclude: exclude,
      separator: separator,
    );
  }

  // ######################
  // Write
  // ######################

  // ...........................................................................
  /// Write a value into the json
  void set<T>(String path, T value) =>
      write(path: path.split(RegExp('[./]')), value: value);

  // ...........................................................................
  /// Writes a value into a JSON document.
  ///
  /// - If the path does not exist, it will be created.
  /// - Throws when an existing value is not of type [T].
  void write<T>({required Iterable<String> path, required T value}) =>
      _write<T>(json, path, value);

  // ...........................................................................
  /// Writes a value into a JSON document.
  ///
  /// - If the path does not exist, it will be created.
  /// - Throws when an existing value is not of type [T].
  /// - Returns the new JSON content.
  static String writeToString<T>({
    required String json,
    required String path,
    required T value,
    bool prettyPrint = false,
  }) {
    final dj = DirectJson.fromString(json: json, prettyPrint: prettyPrint);
    dj.write(path: path.split('/'), value: value);
    return dj.jsonString;
  }

  // ######################
  // Read
  // ######################

  /// Reads a value from the JSON document.
  T? get<T>(String path) => read<T>(path: path.split(RegExp('[./]')));

  // ...........................................................................
  /// Reads a value from a JSON document.
  ///
  /// - Returns null if the value is not found.
  /// - Throws when value is not of type [T].
  T? read<T>({required Iterable<String> path}) => _read<T>(json, path);

  // ...........................................................................
  /// Reads a value from a JSON document.
  ///
  /// - Returns null if the value is not found.
  /// - Throws when value is not of type [T].
  static T? readString<T>({required String json, required String path}) {
    final Json jsonMap = jsonDecode(json) as Json;

    return _read<T>(jsonMap, path.split('/'));
  }

  // ######################
  // Remove
  // ######################

  // ...........................................................................
  /// Removes a value from a JSON document.
  void remove({required Iterable<String> path}) => _remove(json, path);

  // ...........................................................................
  /// Is the JSON document pretty printed?
  final bool prettyPrint;

  // ######################
  // Private
  // ######################

  static JsonEncoder _encoder(bool prettyPrint) =>
      prettyPrint ? const JsonEncoder.withIndent('  ') : const JsonEncoder();

  // ...........................................................................
  static T? _read<T>(Json json, Iterable<String> path) {
    var node = json;
    for (var i = 0; i < path.length; i++) {
      final pathSegment = path.elementAt(i);
      if (!node.containsKey(pathSegment)) {
        return null;
      }
      if ((i == path.length - 1)) {
        final val = node[pathSegment];
        if (val is T == false) {
          throw Exception('Existing value is not of type $T.');
        }
        return node[pathSegment] as T;
      }
      node = node[pathSegment] as Json;
    }

    return null;
  }

  // ...........................................................................
  static void _write<T>(Json json, Iterable<String> path, T value) {
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
  }

  // ...........................................................................
  static void _remove(Json doc, Iterable<String> path) {
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

  // ...........................................................................
  static void _checkType<T>(Json json, Iterable<String> path) {
    _read<T>(json, path); // Will throw if existing value has a different type.
  }
}
