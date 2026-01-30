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
    group('json.set(json, path, value)', () {
      group('creates missing path elements', () {
        test('with an empty base object', () {
          final json = <String, dynamic>{};

          json.set('/a/b/c', 1, extend: true);
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
          json.set('a/b/d', 2, extend: true);
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

          json.set('d/e', [
            [1, 2],
            [3, 4],
            {'f': 5},
          ], extend: true);
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

          json.set<int>('e[3][2]', 66, extend: true);
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
          json.set<String>('a/b', '2');
        } catch (e) {
          message = (e as dynamic).message.toString();
        }

        expect(message, 'Cannot write key "b": int != String.');
      });

      test('throws, when array is accessed without index', () {
        final json = <String, dynamic>{'e': 5};

        var message = '';
        try {
          json.set<int>('e/a', 70);
        } catch (e) {
          message = (e as dynamic).message.toString();
        }

        expect(message, 'Segment "e" is of type "int". Map expected.');
      });

      test('throws, when index is given for a non-array', () {
        final json = <String, dynamic>{
          'a': {'b': 1},
        };

        var message = '';
        try {
          json.set<int>('a[0]', 2);
        } catch (e) {
          message = (e as dynamic).message.toString();
        }

        expect(message, 'Segment "a[0]" is not a list item.');
      });

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

        test('set last item of an arry', () {
          final json = <String, dynamic>{
            'e': {
              'f': [1, 2, 3],
            },
          };

          json.set<int>('e/f[2]', 30);
          expect(json, {
            'e': {
              'f': [1, 2, 30],
            },
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

        var message = <String>[];
        try {
          json.set<int>('a/c', 2);
        } catch (e) {
          message = ((e as dynamic).message as String).split('\n');
        }

        expect(message, [
          'Path segment "c" of "a/c" does not exist.',
          '',
          'Available paths:',
          '  - /',
          '  - /a',
          '  - /a/b',
        ]);
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
      test('read the object itself using /', () {
        final json = <String, dynamic>{
          'a': 1,
          'b': {'c': 2},
        };

        final val = json.get<Json>('/');
        expect(val, {
          'a': 1,
          'b': {'c': 2},
        });
      });

      group('allows to read values', () {
        test('with existing path', () {
          final json = <String, dynamic>{
            'a': 1,
            'b': {
              'c': 2,
              'd': {'e': 3},
            },
          };

          expect(json.get<int>('a'), 1);
          expect(json.get<Json>('b'), {
            'c': 2,
            'd': {'e': 3},
          });
          expect(json.get<int>('b/c'), 2);
          expect(json.get<int>('b/d/e'), 3);
        });
      });

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

        var message = <String>[];
        try {
          json.get<int>('b/d');
        } catch (e) {
          message = ((e as dynamic).message as String).split('\n');
        }

        expect(message, [
          'Value at path "b/d" not found.',
          '',
          'Available paths:',
          '  - /',
          '  - /a',
          '  - /b',
          '  - /b/c',
        ]);
      });

      test('throws when value is of unexpected type', () {
        final json = <String, dynamic>{
          'a': 1,
          'b': {'c': '3'},
        };

        var message = '';
        try {
          json.get<int>('b/c');
        } catch (e) {
          message = (e as dynamic).message.toString();
        }

        expect(message, 'Cannot get key "c": String != int.');
      });

      test('throws when an array is not accessed with an index', () {
        final json = <String, dynamic>{
          'e': [1, 2, 3],
        };

        var message = '';
        try {
          json.get<int>('e/a');
        } catch (e) {
          message = (e as dynamic).message.toString();
        }

        expect(message, 'Segment "e" is not a Map.');
      });

      test('throws when a non-array is accessed with an index', () {
        final json = <String, dynamic>{
          'a': {'b': 1},
        };

        var message = '';
        try {
          json.get<int>('a[0]');
        } catch (e) {
          message = (e as dynamic).message.toString();
        }

        expect(message, 'Segment "a" is not a list item.');
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
