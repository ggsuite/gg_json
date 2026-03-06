// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  group('Json.ls', () {
    group('returns a list of all paths in the JSON document', () {
      group('with writeValues', () {
        test('with simple object', () {
          expect({'a': 10}.ls(writeValues: true), ['.', './a = 10']);
        });

        test('with nested object', () {
          expect(
            {
              'a': {'b': 10},
            }.ls(writeValues: true),
            ['.', './a', './a/b = 10'],
          );
        });

        test('with array', () {
          expect(
            {
              'a': [10, 20],
            }.ls(writeValues: true),
            ['.', './a', './a[0] = 10', './a[1] = 20'],
          );
        });

        test('with array containing objects', () {
          expect(
            {
              'a': [
                {'b': 10},
                {'c': 20},
              ],
            }.ls(writeValues: true),
            ['.', './a', './a[0]/b = 10', './a[1]/c = 20'],
          );
        });

        test('with complex exampleJsonNested0', () {
          final paths = exampleJsonNested0.ls(writeValues: true);
          expect(
            paths,
            containsAll(<String>[
              './arrayValue[1] = 2',
              './arrayValue[2] = 3',
              './arrayValue[3]/innerKey = innerValue',
              './numbers',
              './numbers/positive = 100',
              './numbers/negative = -50',
              './numbers/floating = 0.001',
              './numbers/scientific = 1000000.0',
              './emptyObject',
              './emptyArray',
            ]),
          );
        });

        test('with line prefix', () {
          expect({'a': 10}.ls(writeValues: true, linePrefix: '>> '), [
            '>> .',
            '>> ./a = 10',
          ]);
        });

        test('with alsoComplexValues = true', () {});
      });

      group('without including values', () {
        test('with simple object', () {
          expect({'a': 10}.ls(writeValues: false), ['.', './a']);
        });

        test('with nested object', () {
          expect(
            {
              'a': {'b': 10},
            }.ls(writeValues: false),
            ['.', './a', './a/b'],
          );
        });

        test('with array', () {
          expect(
            {
              'a': [10, 20],
            }.ls(writeValues: false),
            ['.', './a', './a[0]', './a[1]'],
          );
        });

        test('with array containing objects', () {
          expect(
            {
              'a': [
                {'b': 10},
                {'c': 20},
              ],
            }.ls(writeValues: false),
            ['.', './a', './a[0]/b', './a[1]/c'],
          );
        });

        test('with complex exampleJsonNested0', () {
          final paths = exampleJsonNested0.ls(writeValues: false);
          expect(
            paths,
            containsAll(<String>[
              './arrayValue[1]',
              './arrayValue[2]',
              './arrayValue[3]/innerKey',
              './numbers',
              './numbers/positive',
              './numbers/negative',
              './numbers/floating',
              './numbers/scientific',
              './emptyObject',
              './emptyArray',
            ]),
          );
        });
      });

      test('excludes keys matching the exclude pattern', () {
        final json = {
          'a': 1,
          'b_exclude': 2,
          'c': {'b_exclude': 3},
        };

        final paths = json.ls(writeValues: true, exclude: RegExp('exclude'));

        expect(paths, ['.', './a = 1', './c']);
      });

      group('with where callback', () {
        test('filtering for values', () {
          final paths = exampleJson.ls(
            writeValues: true,
            where: ({key, path, value}) =>
                value is num && value < 10 && value >= 0,
          );

          expect(paths, [
            './arrayValue[0] = 1',
            './arrayValue[1] = 2',
            './arrayValue[2] = 3',
            './numbers/floating = 0.001',
          ]);
        });

        test('filtering for paths', () {
          final paths = exampleJson.ls(
            writeValues: true,
            where: ({key, path, value}) => path?.contains('numbers') == true,
          );

          expect(paths, [
            './numbers/positive = 100',
            './numbers/negative = -50',
            './numbers/floating = 0.001',
            './numbers/scientific = 1000000.0',
          ]);
        });

        test('filtering for keys', () {
          final paths = exampleJson.ls(
            writeValues: true,
            where: ({key, path, value}) =>
                key == 'positive' || key == 'negative',
          );

          expect(paths, [
            './numbers/positive = 100',
            './numbers/negative = -50',
          ]);
        });
      });

      group('with alsoComplexValues true', () {
        test('writes also complex values', () {
          expect(exampleJson.ls(writeValues: true, alsoComplexValues: true), [
            '. = {object: {string: nested, null: null, bool: true}, arrayValue:'
                ' [text, 123, 45.6, true, false, null, {deepKey: deepValue}, '
                '[1, 2, 3, {innerKey: innerValue}]], '
                'numbers: {positive: 100, negative: -50, floating: 0.001, '
                'scientific: 1000000.0}, emptyObject: {}, emptyArray: []}',
            './object = {string: nested, null: null, bool: true}',
            './object/string = nested',
            './object/null = null',
            './object/bool = true',
            './arrayValue = [text, 123, 45.6, true, false, null, '
                '{deepKey: deepValue}, [1, 2, 3, {innerKey: innerValue}]]',
            './arrayValue[0] = text',
            './arrayValue[1] = 123',
            './arrayValue[2] = 45.6',
            './arrayValue[3] = true',
            './arrayValue[4] = false',
            './arrayValue[5] = null',
            './arrayValue[6]/deepKey = deepValue',
            './arrayValue[0] = 1',
            './arrayValue[1] = 2',
            './arrayValue[2] = 3',
            './arrayValue[3]/innerKey = innerValue',
            './numbers = {positive: 100, '
                'negative: -50, floating: 0.001, scientific: 1000000.0}',
            './numbers/positive = 100',
            './numbers/negative = -50',
            './numbers/floating = 0.001',
            './numbers/scientific = 1000000.0',
            './emptyObject = {}',
            './emptyArray = []',
          ]);
        });
      });
    });
  });
}
