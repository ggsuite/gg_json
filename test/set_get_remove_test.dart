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
      test('creates missing path elements', () {
        final json = <String, dynamic>{};

        json.add('/a/b/c', 1);
        expect(json, {
          'a': {
            'b': {'c': 1},
          },
        });

        json.add('a/b/d', 2);
        expect(json, {
          'a': {
            'b': {'c': 1, 'd': 2},
          },
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

        expect(message, 'Existing value 1 is not of type String.');
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

        expect(message, 'Path "a/c" does not exist.');
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
