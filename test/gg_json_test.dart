// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:io';

import 'package:gg_json/src/gg_json.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  const ggJson = GgJson();
  final messages = <String>[];
  late File file;

  setUp(() {
    messages.clear();
    final filePath = join(Directory.systemTemp.path, 'gg_json_test.json');
    file = File(filePath);
  });

  group('GgJson()', () {
    group('write:', () {
      group('write(json, path, value)', () {
        group('writes the value into json', () {
          test('- with an empty json', () {
            final json = <String, dynamic>{};
            ggJson.write(json: json, path: ['a', 'b'], value: 1);
            expect(json, {
              'a': {'b': 1},
            });
          });

          test('- with an existing value', () {
            final json = <String, dynamic>{
              'a': {'b': 1},
            };
            ggJson.write(json: json, path: ['a', 'c'], value: 2);
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
              () => ggJson.write(json: json, path: ['a', 'b'], value: '2'),
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

      group('writeString(json, path, value)', () {
        group('writes the value into json', () {
          test('- with an empty json', () {
            const json = '{}';
            final result = ggJson.writeString(
              json: json,
              path: 'a/b',
              value: 1,
            );
            expect(result, '{"a":{"b":1}}');
          });

          test('- with an empty string', () {
            const json = '';
            final result = ggJson.writeString(
              json: json,
              path: 'a/b',
              value: 1,
            );
            expect(result, '{"a":{"b":1}}');
          });

          test('- with an existing value', () {
            const json = '{"a":{"b":1}}';
            final result = ggJson.writeString(
              json: json,
              path: 'a/c',
              value: 2,
            );
            expect(result, '{"a":{"b":1,"c":2}}');
          });

          test('- with prettyPrint', () {
            const json = '{"a":{"b":1}}';
            const ggJson = GgJson(prettyPrint: true);
            final result = ggJson.writeString(
              json: json,
              path: 'a/c',
              value: 2,
            );

            expect(result, prettyPrintResult);
          });
        });

        group('throws', () {
          test('- when an existing value is not of type T', () {
            const json = '{"a":{"b":1}}';
            expect(
              () => ggJson.writeString(json: json, path: 'a/b', value: '2'),
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

      group('writeFile(file, path, value)', () {
        group('writes the value into the file', () {
          test('- with an empty file', () async {
            await file.writeAsString('');
            final result0 = await ggJson.writeFile(
              file: file,
              path: 'a/b',
              value: 1,
            );
            final result1 = await file.readAsString();
            expect(result0, result1);
            expect(result1, '{"a":{"b":1}}');
          });

          test('- with an existing value', () async {
            await file.writeAsString('{"a":{"b":1}}');
            await ggJson.writeFile(file: file, path: 'a/b', value: 2);
            final result = file.readAsStringSync();
            expect(result, '{"a":{"b":2}}');
          });
        });

        group('throws', () {
          test('- when the file is not existing', () async {
            final file = File('not_existing_file.json');
            final result = await ggJson.writeFile(
              file: file,
              path: 'a/b',
              value: 1,
            );
            expect(result, '{"a":{"b":1}}');
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
            final result = ggJson.read<int>(json: json, path: ['a', 'b']);
            expect(result, 1);
          });

          test('- with a non-existing value', () {
            final json = <String, dynamic>{
              'a': {'b': 1},
            };
            final result = ggJson.read<int>(json: json, path: ['a', 'c']);
            expect(result, isNull);
          });
        });

        group('throws', () {
          test('- when value is not of type T', () {
            final json = <String, dynamic>{
              'a': {'b': 1},
            };
            expect(
              () => ggJson.read<String>(json: json, path: ['a', 'b']),
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
            final result = ggJson.readString<int>(json: json, path: 'a/b');
            expect(result, 1);
          });

          test('- with a non-existing value', () {
            const json = '{"a":{"b":1}}';
            final result = ggJson.readString<int>(json: json, path: 'a/c');
            expect(result, null);
          });
        });

        group('throws', () {
          test('- when value is not of type T', () {
            const json = '{"a":{"b":1}}';
            expect(
              () => ggJson.readString<String>(json: json, path: 'a/b'),
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

      group('readFile(file, path)', () {
        group('returns the value from the file', () {
          test('- with an existing value', () async {
            await file.writeAsString('{"a":{"b":1}}');
            final result = await ggJson.readFile<int>(file: file, path: 'a/b');
            expect(result, 1);
          });

          test('- with a non-existing value', () async {
            await file.writeAsString('{"a":{"b":1}}');
            final result = await ggJson.readFile<int>(file: file, path: 'a/c');
            expect(result, null);
          });

          test('- with an empty file', () async {
            await file.writeAsString('');
            final result = await ggJson.readFile<int>(file: file, path: 'a/c');
            expect(result, null);
          });
        });

        group('throws', () {
          test('- when the file is not existing', () {
            final file = File('not_existing_file_2.json');
            expect(
              () async => await ggJson.readFile<int>(file: file, path: 'a/b'),
              throwsA(isA<FileSystemException>()),
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
            ggJson.remove(json: json, path: ['a', 'b']);
            expect(json, {'a': <String, dynamic>{}});
          });

          test('- with a non-existing value', () {
            final json = <String, dynamic>{
              'a': {'b': 1},
            };
            ggJson.remove(json: json, path: ['a', 'c']);
            expect(json, {
              'a': {'b': 1},
            });
          });
        });
      });

      group('removeFile(file, path)', () {
        group('removes the value from the file', () {
          test('- with an existing value', () async {
            await file.writeAsString('{"a":{"b":1}}');
            await ggJson.removeFromFile(file: file, path: 'a/b');
            final result = file.readAsStringSync();
            expect(result, '{"a":{}}');
          });

          test('- with a non-existing value', () async {
            await file.writeAsString('{"a":{"b":1}}');
            await ggJson.removeFromFile(file: file, path: 'a/c');
            final result = file.readAsStringSync();
            expect(result, '{"a":{"b":1}}');
          });
        });

        group('throws', () {
          test('- when the file is not existing', () {
            final file = File('not_existing_file_3.json');
            expect(
              () async => await ggJson.removeFromFile(file: file, path: 'a/b'),
              throwsA(isA<FileSystemException>()),
            );
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
