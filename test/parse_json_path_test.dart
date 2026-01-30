// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  group('parseJsonPath', () {
    test('splits path into segments', () {
      expect(parseJsonPath('a/b/c'), ['a', 'b', 'c']);
      expect(parseJsonPath('/a/b/c/'), ['a', 'b', 'c']);
      expect(parseJsonPath('/a/b/c/'), ['a', 'b', 'c']);
      expect(parseJsonPath('//a/b/c/'), ['a', 'b', 'c']);
      expect(parseJsonPath('a.b.c'), ['a', 'b', 'c']);
      expect(parseJsonPath('a..b.c'), ['a', 'b', 'c']);
      expect(parseJsonPath('.a.b.c.'), ['a', 'b', 'c']);
      expect(parseJsonPath('a/b.c/d'), ['a', 'b', 'c', 'd']);
      expect(parseJsonPath('a/b[0].c/d'), ['a', 'b[0]', 'c', 'd']);
    });

    test('throws on invalid characters', () {
      var message = '';
      try {
        parseJsonPath('a/b c/d');
      } catch (e) {
        message = (e as dynamic).message as String;
      }

      expect(message, 'Invalid chars in path segment "b c".');
    });
  });

  group('parseArrayIndex', () {
    group('parses key and index', () {
      test('simpleIndex', () {
        final result = parseArrayIndex('items[0]');
        expect(result.$1, 'items');
        expect(result.$2, [0]);
      });

      test('multipleIndices', () {
        final result = parseArrayIndex('matrix[1][2]');
        expect(result.$1, 'matrix');
        expect(result.$2, [1, 2]);
      });

      test('noIndex', () {
        final result = parseArrayIndex('data');
        expect(result.$1, 'data');
        expect(result.$2, isEmpty);
      });
    });

    group('throws on invalid segment', () {
      test('non closed bracket', () {
        var message = '';
        try {
          parseArrayIndex('items[0');
        } catch (e) {
          message = (e as dynamic).message as String;
        }

        expect(message, 'Invalid path segment "items[0".');
      });

      test('nested brackets', () {
        var message = '';
        try {
          parseArrayIndex('data[[1]]');
        } catch (e) {
          message = (e as dynamic).message as String;
        }

        expect(message, 'Invalid path segment "data[[1]]".');
      });
    });
  });
}
