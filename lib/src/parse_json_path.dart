// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:collection';

const int _dot = 0x2E; // '.'
const int _slash = 0x2F; // '/'
const int _openBracket = 0x5B; // '['
const int _closeBracket = 0x5D; // ']'
const int _zero = 0x30; // '0'
const int _nine = 0x39; // '9'

/// Shared empty indices list for segments without array indices.
const List<int> _noIndices = <int>[];

// .............................................................................
/// A compiled JSON path segment consisting of a map [key] and optional
/// array [indices].
///
/// Compiled segments are produced by [compileJsonPath] and allow walking a
/// JSON structure without re-parsing the path string on every access.
class JsonPathSegment {
  /// Creates a segment with [key] and [indices].
  ///
  /// [raw] is the original segment text (e.g. `"a[3][4]"`) and defaults to
  /// [key] for segments without indices.
  const JsonPathSegment(this.key, this.indices, [String? raw])
    : raw = raw ?? key;

  /// The map key of this segment, e.g. `"a"` for `"a[3][4]"`.
  final String key;

  /// The array indices of this segment, e.g. `[3, 4]` for `"a[3][4]"`.
  /// Empty for segments without indices.
  final List<int> indices;

  /// The original segment text, e.g. `"a[3][4]"`.
  final String raw;
}

// .............................................................................
/// Cache mapping raw path strings to their compiled segments.
///
/// Caching parsed path strings is safe because strings are immutable and
/// the compiled segments do not reference any JSON data. Dart globals are
/// per-isolate, so no locking is needed.
final HashMap<String, List<JsonPathSegment>> _compiledPathCache =
    HashMap<String, List<JsonPathSegment>>();

/// Maximum number of cached compiled paths.
/// When the cache is full it is cleared. Overflow is rare in practice.
const int _maxCachedPaths = 4096;

// .............................................................................
/// Compiles a JSON [path] into a list of [JsonPathSegment]s.
///
/// Results are cached per isolate, keyed by the raw path string. Repeated
/// calls with the same path string perform no parsing and no allocation.
/// The returned list is shared and unmodifiable; mutating it or a segment's
/// indices throws an [UnsupportedError].
List<JsonPathSegment> compileJsonPath(String path) {
  final cached = _compiledPathCache[path];
  if (cached != null) {
    return cached;
  }

  final result = <JsonPathSegment>[];
  var start = 0;
  for (var i = 0; i < path.length; i++) {
    final char = path.codeUnitAt(i);
    if (char == _dot || char == _slash) {
      if (i > start) {
        result.add(_frozenSegment(path.substring(start, i)));
      }
      start = i + 1;
    }
  }
  if (start < path.length) {
    result.add(_frozenSegment(path.substring(start)));
  }

  if (_compiledPathCache.length >= _maxCachedPaths) {
    _compiledPathCache.clear();
  }
  final frozen = List<JsonPathSegment>.unmodifiable(result);
  _compiledPathCache[path] = frozen;
  return frozen;
}

// .............................................................................
/// Compiles a segment with unmodifiable indices, so the shared cached value
/// cannot be corrupted through the public [compileJsonPath] API.
JsonPathSegment _frozenSegment(String segment) {
  final compiled = _compileSegment(segment);
  return compiled.indices.isEmpty
      ? compiled
      : JsonPathSegment(
          compiled.key,
          List<int>.unmodifiable(compiled.indices),
          compiled.raw,
        );
}

// .............................................................................
/// Cleans and parses JSON paths.
List<String> parseJsonPath(String path) {
  final result = <String>[];
  var start = 0;
  for (var i = 0; i < path.length; i++) {
    final char = path.codeUnitAt(i);
    if (char == _dot || char == _slash) {
      if (i > start) {
        result.add(path.substring(start, i));
      }
      start = i + 1;
    }
  }
  if (start < path.length) {
    result.add(path.substring(start));
  }

  return result;
}

// .............................................................................
/// Parses a path segment with optional array indices.
(String key, Iterable<int> indices) parseArrayIndex(String segment) {
  final compiled = _compileSegment(segment);
  return (compiled.key, compiled.indices);
}

// .............................................................................
/// Compiles a single path segment into a [JsonPathSegment].
JsonPathSegment _compileSegment(String segment) {
  final firstBracket = segment.indexOf('[');

  // No indices? The whole segment is the key.
  if (firstBracket < 0) {
    if (segment.isEmpty || segment.contains(']')) {
      _throwInvalidSegment(segment);
    }
    return JsonPathSegment(segment, _noIndices);
  }

  final key = segment.substring(0, firstBracket);
  if (key.isEmpty || key.contains(']')) {
    _throwInvalidSegment(segment);
  }

  // Parse a sequence of "[digits]" groups covering the rest of the segment.
  final indices = <int>[];
  var i = firstBracket;
  while (i < segment.length) {
    if (segment.codeUnitAt(i) != _openBracket) {
      _throwInvalidSegment(segment);
    }
    i++;

    var index = 0;
    final digitsStart = i;
    while (i < segment.length) {
      final char = segment.codeUnitAt(i);
      if (char < _zero || char > _nine) {
        break;
      }
      index = index * 10 + (char - _zero);
      i++;
    }

    if (i == digitsStart ||
        i >= segment.length ||
        segment.codeUnitAt(i) != _closeBracket) {
      _throwInvalidSegment(segment);
    }
    i++;

    indices.add(index);
  }

  return JsonPathSegment(key, indices, segment);
}

// .............................................................................
Never _throwInvalidSegment(String segment) {
  throw Exception('Invalid path segment "$segment".');
}
