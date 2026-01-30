// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];

  setUp(() {
    messages.clear();
  });

  group('JsonGetSetRemove', () {
    group('json.add(json, path, value)', () {
      group('creates missing path elements', () {
        test('with an empty base object', () {
          final json = <String, dynamic>{};

          json.add('/a/b/c', 1);
          expect(json, {
            'a': {
              'b': {'c': 1},
            },
          });
        });

        test('with an pure map object', () {
          final json = {
            'a': {
              'b': {'c': 1},
            },
          };
          json.add('a/b/d', 2);
          expect(
            json,
            deepCopy({
              'a': {
                'b': {'c': 1, 'd': 2},
              },
            }),
          );
        });

        test('with an array object', () {
          final json = deepCopy({
            'a': {
              'b': {'c': 1, 'd': 2},
            },
          });

          json.add('d/e', [
            [1, 2],
            [3, 4],
            {'f': 5},
          ]);

          expect(json, {
            'a': {
              'b': {'c': 1, 'd': 2},
            },
            'd': {
              'e': [
                [1, 2],
                [3, 4],
                {'f': 5},
              ],
            },
          });
        });

        test('with an index exceeding the current length', () {
          final json = <String, dynamic>{
            'e': [
              [10, 20],
              [30, 40],
              [50, 60],
            ],
          };

          json.add<int>('e[3][2]', 66);
          expect(json, {
            'e': [
              [10, 20],
              [30, 40],
              [50, 60],
              [null, null, 66],
            ],
          });
        });
      });

      test('throws when an existing value is not of type T', () {
        final json = <String, dynamic>{
          'a': {'b': 1},
        };

        var message = '';
        try {
          json.add<String>('a/b', '2');
        } catch (e) {
          message = (e as dynamic).message.toString();
        }

        expect(message, 'Cannot write key "b": int != String.');
      });
    });

    group('json.set(json, path, value)', () {
      test('updates existing path elements', () {
        final json = <String, dynamic>{
          'a': {
            'b': {'c': 1},
          },
        };

        json.set<int>('a/b/c', 2);
        expect(json, {
          'a': {
            'b': {'c': 2},
          },
        });
      });

      group('updates array values', () {
        test('with a single index', () {
          final json = <String, dynamic>{
            'e': [1, 2, 3],
          };

          json.set<int>('e[1]', 20);
          expect(json, {
            'e': [1, 20, 3],
          });
        });

        test('with a nested index', () {
          final json = <String, dynamic>{
            'e': [
              [10, 20],
              [30, 40],
              [50, 60],
            ],
          };

          json.set<int>('e[1][1]', 55);
          expect(json, {
            'e': [
              [10, 20],
              [30, 55],
              [50, 60],
            ],
          });
        });

        test('with three fold nested index', () {
          final json = <String, dynamic>{
            'e': [
              [
                [100, 200],
                [300, 400],
              ],
              [
                [500, 600],
                [700, 800],
              ],
            ],
          };

          json.set<int>('e[1][0][1]', 650);
          expect(json, {
            'e': [
              [
                [100, 200],
                [300, 400],
              ],
              [
                [500, 650],
                [700, 800],
              ],
            ],
          });
        });

        test('with deeper arrays', () {
          final json = {
            'a': [
              [
                [
                  {
                    'b': [1, 2, 3],
                  },
                ],
              ],
            ],
          };

          json.set<int>('a[0][0][0]/b[1]', 20);
          expect(json.get<int>('a[0][0][0]/b[1]'), 20);
        });
      });

      test('throws when the path does not exist', () {
        final json = <String, dynamic>{
          'a': {'b': 1},
        };

        var message = '';
        try {
          json.set<int>('a/c', 2);
        } catch (e) {
          message = (e as dynamic).message.toString();
        }

        expect(message, 'Path segment "c" does not exist.');
      });
    });

    group('json.getOrNull(json, path)', () {
      test('returns null for non-existing path', () {
        final json = <String, dynamic>{
          'a': 1,
          'b': {'c': 3},
        };

        final val = json.getOrNull<int>('b/d');
        expect(val, isNull);
      });
    });

    group('json.get(json, path)', () {
      group('allows to read from arrays', () {
        test('with single index', () {
          final json = <String, dynamic>{
            'e': [1, 2, 3],
          };
          expect(json.get<int>('e[0]'), 1);
          expect(json.get<int>('e[1]'), 2);
          expect(json.get<int>('e[2]'), 3);
          expect(json.getOrNull<int>('e[3]'), isNull);
        });
        test('with multi indices', () {
          final json = <String, dynamic>{
            'e': [
              [10, 20],
              [30, 40],
              [50, 60],
            ],
          };
          expect(json.get<int>('e[0][0]'), 10);
          expect(json.get<int>('e[0][1]'), 20);
          expect(json.get<int>('e[1][0]'), 30);
          expect(json.get<int>('e[1][1]'), 40);
          expect(json.get<int>('e[2][0]'), 50);
          expect(json.get<int>('e[2][1]'), 60);
          expect(json.getOrNull<int>('e[3][0]'), isNull);
          expect(json.getOrNull<int>('e[0][2]'), isNull);
        });
      });

      test('throws when path is not found', () {
        final json = <String, dynamic>{
          'a': 1,
          'b': {'c': 3},
        };

        var message = '';
        try {
          json.get<int>('b/d');
        } catch (e) {
          message = (e as dynamic).message.toString();
        }

        expect(message, 'Value at path "b/d" not found.');
      });
    });

    group('removeValue(json, path)', () {
      group('removes the value from json', () {
        test('- with an existing value', () {
          final json = <String, dynamic>{
            'a': {'b': 1},
          };

          json.removeValue('/a/b');
          expect(json, {'a': <String, dynamic>{}});
        });

        test('- with a non-existing value', () {
          final json = <String, dynamic>{
            'a': {'b': 1},
          };
          json.removeValue('/a/c');
          expect(json, {
            'a': {'b': 1},
          });
        });
      });
    });
  });
}

const prettyPrintResult = '''
{
  "a": {
    "b": 1,
    "c": 2
  }
}''';
