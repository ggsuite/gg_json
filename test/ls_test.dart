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

      group('with special characters and long paths', () {
        test('handles keys with non Latin-1 characters', () {
          expect(
            {
              '日本語': {'inner': 1},
              'ä': 2,
            }.ls(),
            ['.', './日本語', './日本語/inner', './ä'],
          );
        });

        test('handles a nested map two levels under a non Latin-1 key', () {
          expect(
            {
              '日本語': {
                'a': {'b': 1},
              },
            }.ls(),
            ['.', './日本語', './日本語/a', './日本語/a/b'],
          );
        });

        test('writes simple values nested in a non Latin-1 key with '
            'writeValues', () {
          expect(
            {
              '日本語': {'a': 5},
            }.ls(writeValues: true),
            ['.', './日本語', './日本語/a = 5'],
          );
        });

        test('handles a nested list two levels under a non Latin-1 key', () {
          expect(
            {
              '日本語': {
                'a': [1, 2],
              },
            }.ls(writeValues: true),
            ['.', './日本語', './日本語/a', './日本語/a[0] = 1', './日本語/a[1] = 2'],
          );
        });

        test('handles a list of lists under a non Latin-1 key', () {
          // Nested lists reuse the outer list's path segment, matching the
          // behavior of the plain (Latin-1) fast path.
          expect(
            {
              '日本語': [
                [1, 2],
                [3, 4],
              ],
            }.ls(writeValues: true),
            [
              '.',
              './日本語',
              './日本語[0] = 1',
              './日本語[1] = 2',
              './日本語[0] = 3',
              './日本語[1] = 4',
            ],
          );
        });

        test('handles a map inside a list under a non Latin-1 key', () {
          expect(
            {
              '日本語': [
                {'a': 1},
              ],
            }.ls(writeValues: true),
            ['.', './日本語', './日本語[0]/a = 1'],
          );
        });

        test(
          'handles list items under a non Latin-1 key without writeValues',
          () {
            expect(
              {
                '日本語': [1, 2],
              }.ls(),
              ['.', './日本語', './日本語[0]', './日本語[1]'],
            );
          },
        );

        test('handles a simple value under a non Latin-1 key without '
            'writeValues', () {
          expect({'日本語': 5}.ls(), ['.', './日本語']);
        });

        test('handles a list value under a non Latin-1 key', () {
          expect(
            {
              '日本語': [10, 20],
            }.ls(writeValues: true),
            ['.', './日本語', './日本語[0] = 10', './日本語[1] = 20'],
          );
        });

        test('handles a simple value under a non Latin-1 key', () {
          expect({'日本語': 5}.ls(writeValues: true), ['.', './日本語 = 5']);
        });

        test('handles values with non Latin-1 characters', () {
          expect({'a': 'wörld', 'b': '→', 'c': 12}.ls(writeValues: true), [
            '.',
            './a = wörld',
            './b = →',
            './c = 12',
          ]);
        });

        test('handles line prefixes with non Latin-1 characters', () {
          expect({'a': 1}.ls(linePrefix: '→ '), ['→ .', '→ ./a']);
        });

        test('handles list indices with more than one digit', () {
          final paths = {
            'l': List<dynamic>.generate(12, (i) => i),
          }.ls(writeValues: true);
          expect(paths, contains('./l[10] = 10'));
          expect(paths, contains('./l[11] = 11'));
        });

        test('handles paths longer than the initial buffer', () {
          final keys = List<String>.generate(
            40,
            (i) => 'segment${i.toString().padLeft(2, '0')}',
          );
          final json = <String, dynamic>{};
          var node = json;
          for (final key in keys.take(39)) {
            final child = <String, dynamic>{};
            node[key] = child;
            node = child;
          }
          node[keys.last] = 1;

          final paths = json.ls(writeValues: true);
          expect(paths.last, './${keys.join('/')} = 1');
        });

        test('grows the path buffer across multiple doublings', () {
          // A single very long key forces one buffer request that jumps
          // past the initial 256-code-unit buffer by more than a single
          // doubling, so the growth loop must iterate more than once.
          final longKey = 'k' * 3000;
          final json = {longKey: 1};

          final paths = json.ls(writeValues: true);
          expect(paths, ['.', './$longKey = 1']);
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

    test('applies linePrefix on the filtered (where/exclude) path too', () {
      final json = {'a': 1, 'b': 2};
      expect(json.ls(linePrefix: '>> ', where: ({key, value, path}) => true), [
        '>> .',
        '>> ./a',
        '>> ./b',
      ]);
    });
  });
}
