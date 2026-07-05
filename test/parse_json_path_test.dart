// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  group('compileJsonPath', () {
    test('compiles path segments with keys and indices', () {
      final segments = compileJsonPath('a/b[3][4].c');
      expect(segments, hasLength(3));

      expect(segments[0].key, 'a');
      expect(segments[0].indices, isEmpty);
      expect(segments[0].raw, 'a');

      expect(segments[1].key, 'b');
      expect(segments[1].indices, [3, 4]);
      expect(segments[1].raw, 'b[3][4]');

      expect(segments[2].key, 'c');
      expect(segments[2].indices, isEmpty);
      expect(segments[2].raw, 'c');
    });

    test('ignores leading, trailing and duplicate separators', () {
      expect(compileJsonPath('//a.b/c/').map((s) => s.key), ['a', 'b', 'c']);
      expect(compileJsonPath(''), isEmpty);
      expect(compileJsonPath('/'), isEmpty);
    });

    test('caches compiled paths by the raw path string', () {
      final first = compileJsonPath('x/y[1]');
      final second = compileJsonPath('x/y[1]');
      expect(identical(first, second), isTrue);
    });

    test('returns unmodifiable structures so the cache cannot be poisoned', () {
      final segments = compileJsonPath('p/q[2][3]');
      expect(() => segments.removeLast(), throwsUnsupportedError);
      expect(() => segments[0].indices.add(1), throwsUnsupportedError);
      expect(() => segments[1].indices.add(1), throwsUnsupportedError);

      // The path still resolves correctly afterwards.
      final json = <String, dynamic>{
        'p': <String, dynamic>{
          'q': <dynamic>[
            <dynamic>[],
            <dynamic>[],
            <dynamic>[0, 1, 2, 42],
          ],
        },
      };
      expect(json.get<int>('p/q[2][3]'), 42);
    });

    test('clears the cache once the entry limit is reached', () {
      // Compile more distinct paths than the internal cache bound so the
      // cache clears and refills at least once; it must keep resolving
      // paths correctly afterwards.
      for (var i = 0; i < 5000; i++) {
        final segments = compileJsonPath('p$i/q[$i]');
        expect(segments[0].key, 'p$i');
        expect(segments[1].key, 'q');
        expect(segments[1].indices, [i]);
      }

      // A path compiled before the clear still resolves correctly when
      // requested again after the cache has been cleared and refilled.
      final again = compileJsonPath('p0/q[0]');
      expect(again[0].key, 'p0');
      expect(again[1].indices, [0]);
    });

    test('throws on invalid segments', () {
      expect(
        () => compileJsonPath('a/b['),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid path segment "b[".'),
          ),
        ),
      );
    });
  });

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

      test('empty segment', () {
        expect(
          () => parseArrayIndex(''),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid path segment "".'),
            ),
          ),
        );
      });

      test('closing bracket without opening bracket', () {
        expect(
          () => parseArrayIndex('a]b'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid path segment "a]b".'),
            ),
          ),
        );
      });

      test('missing key before index', () {
        expect(
          () => parseArrayIndex('[0]'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid path segment "[0]".'),
            ),
          ),
        );
      });

      test('closing bracket within key', () {
        expect(
          () => parseArrayIndex('a]b[0]'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid path segment "a]b[0]".'),
            ),
          ),
        );
      });

      test('text after index', () {
        expect(
          () => parseArrayIndex('a[0]x'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid path segment "a[0]x".'),
            ),
          ),
        );
      });
    });
  });
}
