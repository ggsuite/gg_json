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
      group('with includeValues = true', () {
        test('returns all paths in a flat JSON', () {
          final dj = DirectJson(json: {'a': 1, 'b': 2});
          final paths = dj.ls();
          expect(paths, ['/', '/a = 1', '/b = 2']);
        });

        test('returns all paths in a nested JSON', () {
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
          expect(paths, [
            '/',
            '/a',
            '/a/b = 1',
            '/a/c',
            '/a/c/d = 2',
            '/e = 3',
          ]);
        });

        test('handles lists inside JSON', () {
          final dj = DirectJson(
            json: {
              'a': [
                {'b': 1},
                {'c': 2},
              ],
            },
          );
          final paths = dj.ls();
          expect(paths, ['/', '/a', '/a[0]/b = 1', '/a[1]/c = 2']);
        });

        test('returns paths including values when writeValues is true', () {
          final dj = DirectJson(
            json: {
              'a': 1,
              'b': {'c': 2},
            },
          );
          final paths = dj.ls(writeValues: true);
          expect(paths, ['/', '/a = 1', '/b', '/b/c = 2']);
        });

        test('does include values when writeValues is false', () {
          final dj = DirectJson(
            json: {
              'a': 1,
              'b': {'c': 2},
            },
          );

          final paths = dj.ls(writeValues: false);
          expect(paths, ['/', '/a', '/b', '/b/c']);
        });

        test('excludes keys matching the exclude pattern', () {
          final dj = DirectJson(
            json: {
              'a': 1,
              'b_exclude': 2,
              'c': {'b_exclude': 3},
            },
          );

          final paths = dj.ls(writeValues: true, exclude: RegExp('exclude'));

          expect(paths, ['/', '/a = 1', '/c']);
        });

        test('handles lists in lists', () {
          final dj = DirectJson(
            json: {
              'a': [
                {'b': 1},
                ['c', 'd'],
              ],
            },
          );
          final paths = dj.ls();
          expect(paths, ['/', '/a', '/a[0]/b = 1', '/a[0] = c', '/a[1] = d']);
        });
      });

      group('with includeValues = false', () {
        test('returns all paths in a flat JSON', () {
          final dj = DirectJson(json: {'a': 1, 'b': 2});
          final paths = dj.ls(writeValues: false);
          expect(paths, ['/', '/a', '/b']);
        });

        test('returns all paths in a nested JSON', () {
          final dj = DirectJson(
            json: {
              'a': {
                'b': 1,
                'c': {'d': 2},
              },
              'e': 3,
            },
          );
          final paths = dj.ls(writeValues: false);
          expect(paths, ['/', '/a', '/a/b', '/a/c', '/a/c/d', '/e']);
        });

        test('handles lists inside JSON', () {
          final dj = DirectJson(
            json: {
              'a': [
                {'b': 1},
                {'c': 2},
              ],
            },
          );
          final paths = dj.ls(writeValues: false);
          expect(paths, ['/', '/a', '/a[0]/b', '/a[1]/c']);
        });

        test('returns paths including values when writeValues is true', () {
          final dj = DirectJson(
            json: {
              'a': 1,
              'b': {'c': 2},
            },
          );
          final paths = dj.ls(writeValues: false);
          expect(paths, ['/', '/a', '/b', '/b/c']);
        });

        test('does include values when writeValues is false', () {
          final dj = DirectJson(
            json: {
              'a': 1,
              'b': {'c': 2},
            },
          );

          final paths = dj.ls(writeValues: false);
          expect(paths, ['/', '/a', '/b', '/b/c']);
        });

        test('excludes keys matching the exclude pattern', () {
          final dj = DirectJson(
            json: {
              'a': 1,
              'b_exclude': 2,
              'c': {'b_exclude': 3},
            },
          );

          final paths = dj.ls(writeValues: false, exclude: RegExp('exclude'));

          expect(paths, ['/', '/a', '/c']);
        });

        test('handles lists in lists', () {
          final dj = DirectJson(
            json: {
              'a': [
                {'b': 1},
                ['c', 'd'],
              ],
            },
          );
          final paths = dj.ls(writeValues: false);
          expect(paths, ['/', '/a', '/a[0]/b', '/a[0]', '/a[1]']);
        });
      });
    });

    test('set, get', () {
      final df = DirectJson(
        json: {
          'a': 1,
          'b': {'c': 3},
        },
        prettyPrint: false,
      );

      df.set('/b/c', 4);
      expect(df.jsonString, '{"a":1,"b":{"c":4}}');

      df.set('b.c', 5);
      expect(df.jsonString, '{"a":1,"b":{"c":5}}');

      final val = df.get<int>('b/c');
      expect(val, 5);

      final val2 = df.get<Map<String, dynamic>>('b');
      expect(val2, {'c': 5});
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

    group('remove', () {
      group('remove(json, path)', () {
        group('removes the value from json', () {
          test('- with an existing value', () {
            final json = <String, dynamic>{
              'a': {'b': 1},
            };
            final directJson = DirectJson(json: json);
            directJson.remove(path: ['a', 'b']);
            expect(json, {'a': <String, dynamic>{}});
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
