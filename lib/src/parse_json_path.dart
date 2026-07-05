// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

const int _dot = 0x2E; // '.'
const int _slash = 0x2F; // '/'
const int _openBracket = 0x5B; // '['
const int _closeBracket = 0x5D; // ']'
const int _zero = 0x30; // '0'
const int _nine = 0x39; // '9'

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
  final firstBracket = segment.indexOf('[');

  // No indices? The whole segment is the key.
  if (firstBracket < 0) {
    if (segment.isEmpty || segment.contains(']')) {
      _throwInvalidSegment(segment);
    }
    return (segment, const <int>[]);
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

  return (key, indices);
}

// .............................................................................
Never _throwInvalidSegment(String segment) {
  throw Exception('Invalid path segment "$segment".');
}
