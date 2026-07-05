// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

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
    final result = <String>[];

    // Fast path: no filters. The line prefix is baked into the parent path
    // so no second pass over the result is needed.
    if (where == null && exclude == null) {
      final writeComplex = writeValues && alsoComplexValues;
      final root = '$linePrefix.';
      // Don't list the root element's value when only simple values are
      // requested.
      result.add(alsoComplexValues ? '$root = $this' : root);

      final walker = _FastWalker(result, writeValues, writeComplex);
      final rootLen = walker.tryInit(root);
      if (rootLen >= 0) {
        // Paths are built in a shared Latin-1 code unit buffer; each line is
        // materialized with a single String.fromCharCodes call, which is
        // considerably cheaper than string interpolation per node.
        walker.lsMap(this, rootLen);
      } else {
        // The line prefix contains non Latin-1 characters: build all paths
        // via plain string interpolation instead.
        _lsMapInterp(this, result, root, writeValues, writeComplex);
      }
      return result;
    }

    // Filtered path.
    _addFiltered(
      result,
      '',
      '.',
      this,
      where,
      alsoComplexValues,
      alsoComplexValues,
    );
    _lsMapFiltered(
      this,
      result,
      '.',
      writeValues,
      alsoComplexValues,
      exclude,
      where,
    );

    if (linePrefix.isEmpty) {
      return result;
    }
    return result.map((e) => '$linePrefix$e').toList();
  }
}

// .............................................................................
// Fast walkers (no where / exclude filters).
// .............................................................................

/// Walks a JSON tree and collects one path line per node into [paths].
///
/// The current parent path is kept as Latin-1 code units in [_buf]; each
/// line is created with a single String.fromCharCodes call. Keys or values
/// containing non Latin-1 characters fall back to interpolation-based
/// helpers for the affected entry only.
class _FastWalker {
  _FastWalker(this.paths, this.writeSimple, this.writeComplex);

  /// The collected path lines.
  final List<String> paths;

  /// Whether simple leaf values shall be written (`path = value`).
  final bool writeSimple;

  /// Whether map/list values shall be written too.
  final bool writeComplex;

  /// Shared path buffer holding Latin-1 code units.
  Uint8List _buf = Uint8List(256);

  // ...........................................................................
  /// Writes [root] into the buffer and returns its length, or -1 when
  /// [root] contains non Latin-1 characters.
  int tryInit(String root) {
    final length = root.length;
    _ensure(length);
    final buf = _buf;
    for (var i = 0; i < length; i++) {
      final c = root.codeUnitAt(i);
      if (c > 0xFF) return -1;
      buf[i] = c;
    }
    return length;
  }

  // ...........................................................................
  /// Grows the buffer so at least [capacity] code units fit.
  void _ensure(int capacity) {
    final buf = _buf;
    if (capacity > buf.length) {
      var newLength = buf.length * 2;
      while (newLength < capacity) {
        newLength *= 2;
      }
      _buf = Uint8List(newLength)..setRange(0, buf.length, buf);
    }
  }

  // ...........................................................................
  /// Lists all paths below [json]. [parentLen] is the buffer length of the
  /// already written (and prefixed) path of [json] itself.
  void lsMap(Map<String, dynamic> json, int parentLen) {
    for (final entry in json.entries) {
      final key = entry.key;
      final val = entry.value;

      // Append '/key' to the parent path.
      final keyLength = key.length;
      _ensure(parentLen + 1 + keyLength);
      var buf = _buf;
      var len = parentLen;
      buf[len++] = 0x2F; // '/'
      var latin1 = true;
      for (var i = 0; i < keyLength; i++) {
        final c = key.codeUnitAt(i);
        if (c > 0xFF) {
          latin1 = false;
          break;
        }
        buf[len++] = c;
      }
      if (!latin1) {
        // Rare: the key contains non Latin-1 characters. Handle this entry
        // (and its subtree) via interpolation-based helpers.
        _entryInterp(String.fromCharCodes(buf, 0, parentLen), key, val);
        continue;
      }

      if (val is Map<String, dynamic>) {
        final path = String.fromCharCodes(buf, 0, len);
        paths.add(writeComplex ? '$path = $val' : path);
        lsMap(val, len);
      } else if (val is List) {
        final path = String.fromCharCodes(buf, 0, len);
        paths.add(writeComplex ? '$path = $val' : path);
        lsList(val, len);
      } else if (writeSimple) {
        _addValueLine(len, val);
      } else {
        paths.add(String.fromCharCodes(buf, 0, len));
      }
    }
  }

  // ...........................................................................
  /// Lists all items of [list]. [pathLen] is the buffer length of the
  /// already written path of the list itself.
  void lsList(List<dynamic> list, int pathLen) {
    final length = list.length;
    for (var i = 0; i < length; i++) {
      final val = list[i];
      // Append '[i]' to the list path.
      _ensure(pathLen + 22);
      var len = _appendIndex(pathLen, i);
      // Handle map in list
      if (val is Map<String, dynamic>) {
        lsMap(val, len);
      }
      // Handle list in list
      else if (val is List) {
        lsList(val, pathLen);
      }
      // Handle other values
      else if (writeSimple) {
        _addValueLine(len, val);
      } else {
        paths.add(String.fromCharCodes(_buf, 0, len));
      }
    }
  }

  // ...........................................................................
  /// Appends '[index]' at buffer position [len]; returns the new length.
  /// The caller must have ensured capacity.
  int _appendIndex(int len, int index) {
    final buf = _buf;
    buf[len++] = 0x5B; // '['
    if (index < 10) {
      buf[len++] = 0x30 + index;
    } else {
      final digits = index.toString();
      final digitCount = digits.length;
      for (var i = 0; i < digitCount; i++) {
        buf[len++] = digits.codeUnitAt(i);
      }
    }
    buf[len++] = 0x5D; // ']'
    return len;
  }

  // ...........................................................................
  /// Adds a 'path = value' line where the path occupies the first [len]
  /// buffer code units.
  void _addValueLine(int len, dynamic val) {
    final text = val.toString();
    final textLength = text.length;
    final pathLen = len;
    _ensure(len + 3 + textLength);
    final buf = _buf;
    buf[len++] = 0x20; // ' '
    buf[len++] = 0x3D; // '='
    buf[len++] = 0x20; // ' '
    for (var i = 0; i < textLength; i++) {
      final c = text.codeUnitAt(i);
      if (c > 0xFF) {
        // Rare: the value contains non Latin-1 characters.
        paths.add('${String.fromCharCodes(buf, 0, pathLen)} = $text');
        return;
      }
      buf[len++] = c;
    }
    paths.add(String.fromCharCodes(buf, 0, len));
  }

  // ...........................................................................
  /// Handles a single map entry whose key contains non Latin-1 characters
  /// using interpolation-based path building for its whole subtree.
  void _entryInterp(String parent, String key, dynamic val) {
    if (val is Map<String, dynamic>) {
      final path = '$parent/$key';
      paths.add(writeComplex ? '$path = $val' : path);
      _lsMapInterp(val, paths, path, writeSimple, writeComplex);
    } else if (val is List) {
      final path = '$parent/$key';
      paths.add(writeComplex ? '$path = $val' : path);
      _lsListInterp(val, paths, path, writeSimple, writeComplex);
    } else if (writeSimple) {
      paths.add('$parent/$key = $val');
    } else {
      paths.add('$parent/$key');
    }
  }
}

// ...........................................................................
/// Interpolation-based fallback walker for non Latin-1 paths. [parent] is
/// the already joined (and prefixed) path of [json] itself.
void _lsMapInterp(
  Map<String, dynamic> json,
  List<String> paths,
  String parent,
  bool writeSimple,
  bool writeComplex,
) {
  for (final entry in json.entries) {
    final key = entry.key;
    final val = entry.value;
    if (val is Map<String, dynamic>) {
      final path = '$parent/$key';
      paths.add(writeComplex ? '$path = $val' : path);
      _lsMapInterp(val, paths, path, writeSimple, writeComplex);
    } else if (val is List) {
      final path = '$parent/$key';
      paths.add(writeComplex ? '$path = $val' : path);
      _lsListInterp(val, paths, path, writeSimple, writeComplex);
    } else if (writeSimple) {
      paths.add('$parent/$key = $val');
    } else {
      paths.add('$parent/$key');
    }
  }
}

// ...........................................................................
/// Interpolation-based fallback walker for list items. [path] is the
/// already joined path of the list itself.
void _lsListInterp(
  List<dynamic> list,
  List<String> paths,
  String path,
  bool writeSimple,
  bool writeComplex,
) {
  final length = list.length;
  for (var i = 0; i < length; i++) {
    final val = list[i];
    // Handle map in list
    if (val is Map<String, dynamic>) {
      _lsMapInterp(val, paths, '$path[$i]', writeSimple, writeComplex);
    }
    // Handle list in list
    else if (val is List) {
      _lsListInterp(val, paths, path, writeSimple, writeComplex);
    }
    // Handle other values
    else if (writeSimple) {
      paths.add('$path[$i] = $val');
    } else {
      paths.add('$path[$i]');
    }
  }
}

// .............................................................................
// Filtered walkers (where and/or exclude given).
// .............................................................................

// ...........................................................................
/// List all paths in a JSON object.
/// [parent] is the already joined path of the object itself.
void _lsMapFiltered(
  Map<String, dynamic> json,
  List<String> paths,
  String parent,
  bool writeValues,
  bool alsoComplexValues,
  Pattern? exclude,
  WhereProp? where,
) {
  for (final entry in json.entries) {
    final key = entry.key;

    // Exclude keys that match the exclude pattern
    if (exclude != null && exclude.allMatches(key).isNotEmpty) {
      continue;
    }

    final val = entry.value;

    // Handle maps
    if (val is Map<String, dynamic>) {
      _addFiltered(
        paths,
        parent,
        key,
        val,
        where,
        writeValues,
        alsoComplexValues,
      );
      _lsMapFiltered(
        val,
        paths,
        '$parent/$key',
        writeValues,
        alsoComplexValues,
        exclude,
        where,
      );
    }
    // Handle lists
    else if (val is List) {
      _addFiltered(
        paths,
        parent,
        key,
        val,
        where,
        writeValues,
        alsoComplexValues,
      );
      _lsListFiltered(
        val,
        paths,
        parent,
        key,
        writeValues,
        alsoComplexValues,
        exclude,
        where,
      );
    }
    // Handle other values
    else {
      _addFiltered(
        paths,
        parent,
        key,
        val,
        where,
        writeValues,
        alsoComplexValues,
      );
    }
  }
}

// ...........................................................................
void _lsListFiltered(
  List<dynamic> list,
  List<String> paths,
  String parent,
  String key,
  bool writeValues,
  bool alsoComplexValues,
  Pattern? exclude,
  WhereProp? where,
) {
  final length = list.length;
  for (var i = 0; i < length; i++) {
    final val = list[i];
    // Handle map in list
    if (val is Map<String, dynamic>) {
      _lsMapFiltered(
        val,
        paths,
        '$parent/$key[$i]',
        writeValues,
        alsoComplexValues,
        exclude,
        where,
      );
    }
    // Handle list in list
    else if (val is List) {
      _lsListFiltered(
        val,
        paths,
        parent,
        key,
        writeValues,
        alsoComplexValues,
        exclude,
        where,
      );
    }
    // Handle other values
    else {
      _addFiltered(
        paths,
        parent,
        '$key[$i]',
        val,
        where,
        writeValues,
        alsoComplexValues,
      );
    }
  }
}

// ...........................................................................
void _addFiltered(
  List<String> paths,
  String parent,
  String key,
  dynamic val,
  WhereProp? where,
  bool writeValues,
  bool alsoComplexValues,
) {
  if (where != null && !where(key: key, value: val, path: parent)) {
    return;
  }

  if (!alsoComplexValues) {
    writeValues = writeValues && !isComplexJsonValue(val);
  }

  final segment = writeValues ? '$key = $val' : key;
  paths.add(parent.isEmpty ? segment : '$parent/$segment');
}
