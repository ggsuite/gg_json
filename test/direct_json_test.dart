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

  group('DirectJson()', () {
    group('ls()', () {
      test('returns all paths in a JSON', () {
        final dj = DirectJson(
          json: {
            'a': {
              'b': 1,
              'c': {'d': 2},
            },
            'e': 3,
          },
        );
        final paths = dj.ls();
        expect(paths, ['/', '/a', '/a/b', '/a/c', '/a/c/d', '/e']);
      });
    });

    test('set, get', () {
      final dj = DirectJson(
        json: {
          'a': 1,
          'b': {'c': 3},
        },
        prettyPrint: false,
      );

      dj.set('/b/c', 4);
      expect(dj.jsonString, '{"a":1,"b":{"c":4}}');

      dj.set('b.c', 5);
      expect(dj.jsonString, '{"a":1,"b":{"c":5}}');

      dj.set('.b.c', 6);
      expect(dj.jsonString, '{"a":1,"b":{"c":6}}');

      final val = dj.get<int>('b/c');
      expect(val, 6);

      final val2 = dj.get<Map<String, dynamic>>('b');
      expect(val2, {'c': 6});
    });
    group('write:', () {
      group('write(json, path, value)', () {
        group('writes the value into json', () {
          test('- with an empty json', () {
            final json = <String, dynamic>{};
            DirectJson(json: json).write(path: ['a', 'b'], value: 1);
            expect(json, {
              'a': {'b': 1},
            });
          });

          test('- with an existing value', () {
            final json = <String, dynamic>{
              'a': {'b': 1},
            };
            DirectJson(json: json).write(path: ['a', 'c'], value: 2);
            expect(json, {
              'a': {'b': 1, 'c': 2},
            });
          });
        });

        group('throws', () {
          test('- when an existing value is not of type T', () {
            final json = <String, dynamic>{
              'a': {'b': 1},
            };
            expect(
              () => DirectJson(json: json).write(path: ['a', 'b'], value: '2'),
              throwsA(
                isA<Exception>().having(
                  (e) => e.toString(),
                  'message',
                  'Exception: Existing value is not of type String.',
                ),
              ),
            );
          });
        });
      });

      group('writeToString(json, path, value)', () {
        group('writes the value into json', () {
          test('- with an empty json', () {
            const json = '{}';
            final result = DirectJson.writeToString(
              json: json,
              path: 'a/b',
              value: 1,
            );
            expect(result, '{"a":{"b":1}}');
          });

          test('- with an empty string', () {
            const json = '';
            final result = DirectJson.writeToString(
              json: json,
              path: 'a/b',
              value: 1,
            );
            expect(result, '{"a":{"b":1}}');
          });

          test('- with an existing value', () {
            const json = '{"a":{"b":1}}';
            final result = DirectJson.writeToString(
              json: json,
              path: 'a/c',
              value: 2,
            );
            expect(result, '{"a":{"b":1,"c":2}}');
          });

          test('- with prettyPrint', () {
            const json = '{"a":{"b":1}}';
            final result = DirectJson.writeToString(
              json: json,
              path: 'a/c',
              value: 2,
              prettyPrint: true,
            );

            expect(result, prettyPrintResult);
          });
        });

        group('throws', () {
          test('- when an existing value is not of type T', () {
            const json = '{"a":{"b":1}}';
            expect(
              () =>
                  DirectJson.writeToString(json: json, path: 'a/b', value: '2'),
              throwsA(
                isA<Exception>().having(
                  (e) => e.toString(),
                  'message',
                  'Exception: Existing value is not of type String.',
                ),
              ),
            );
          });
        });
      });
    });

    group('read:', () {
      group('read(json, path, content)', () {
        group('returns the value from json', () {
          test('- with an existing value', () {
            final json = <String, dynamic>{
              'a': {'b': 1},
            };
            final directJson = DirectJson(json: json);
            final result = directJson.read<int>(path: ['a', 'b']);
            expect(result, 1);
          });

          test('- with a non-existing value', () {
            final json = <String, dynamic>{
              'a': {'b': 1},
            };
            final directJson = DirectJson(json: json);
            final result = directJson.read<int>(path: ['a', 'c']);
            expect(result, isNull);
          });
        });

        group('throws', () {
          test('- when value is not of type T', () {
            final json = <String, dynamic>{
              'a': {'b': 1},
            };
            final directJson = DirectJson(json: json);
            expect(
              () => directJson.read<String>(path: ['a', 'b']),
              throwsA(
                isA<Exception>().having(
                  (e) => e.toString(),
                  'message',
                  'Exception: Existing value is not of type String.',
                ),
              ),
            );
          });
        });
      });

      group('readString(json, path)', () {
        group('returns the value from json', () {
          test('- with an existing value', () {
            const json = '{"a":{"b":1}}';
            final result = DirectJson.readString<int>(json: json, path: 'a/b');
            expect(result, 1);
          });

          test('- with a non-existing value', () {
            const json = '{"a":{"b":1}}';
            final result = DirectJson.readString<int>(json: json, path: 'a/c');
            expect(result, null);
          });
        });

        group('throws', () {
          test('- when value is not of type T', () {
            const json = '{"a":{"b":1}}';
            expect(
              () => DirectJson.readString<String>(json: json, path: 'a/b'),
              throwsA(
                isA<Exception>().having(
                  (e) => e.toString(),
                  'message',
                  'Exception: Existing value is not of type String.',
                ),
              ),
            );
          });
        });
      });
    });

    group('remove, removeFromString', () {
      group('remove(json, path)', () {
        group('removes the value from json', () {
          test('- with an existing value', () {
            final json = <String, dynamic>{
              'a': {'b': 1},
            };
            final directJson = DirectJson(json: json);
            directJson.remove(path: ['a', 'b']);
            expect(json, {'a': <String, dynamic>{}});

            final jsonStr = directJson.jsonString;
            final jsonStrOut = DirectJson.removeFromString(
              json: jsonStr,
              path: '/a/b',
            );
            expect(jsonStrOut, '{"a":{}}');
          });

          test('- with a non-existing value', () {
            final json = <String, dynamic>{
              'a': {'b': 1},
            };
            final directJson = DirectJson(json: json);
            directJson.remove(path: ['a', 'c']);
            expect(json, {
              'a': {'b': 1},
            });
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
