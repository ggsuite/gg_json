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

  group('json.set, json.get, json.remove', () {
    test('writes and reads values', () {
      final json = {
        'a': 1,
        'b': {'c': 3},
      };

      json.set('/b/c', 4);
      expect(json.get<int>('a'), 1);
      expect(json.get<int>('b/c'), 4);

      expect(json, {
        'a': 1,
        'b': {'c': 4},
      });
      expect(json.get<int>('b/c'), 4);

      json.set('b.c', 5);
      expect(json, {
        'a': 1,
        'b': {'c': 5},
      });
      expect(json.get<int>('b/c'), 5);

      json.set('.b.c', 6);
      expect(json, {
        'a': 1,
        'b': {'c': 6},
      });
      expect(json.get<int>('b/c'), 6);
      expect(json.get<Json>('/b'), {'c': 6});

      final val3 = <String, dynamic>{}.set('/a/b', 1);
      expect(val3, {
        'a': {'b': 1},
      });

      expect(val3.set('/a/c', 2), {
        'a': {'b': 1, 'c': 2},
      });
    });

    group('throws', () {
      test('- when an existing value is not of type T', () {
        final json = <String, dynamic>{
          'a': {'b': 1},
        };

        var message = '';
        try {
          json.set('a/b', '2');
        } catch (e) {
          message = (e as dynamic).message.toString();
        }

        expect(message, 'Existing value 1 is not of type String.');
      });
    });
  });

  group('removeAtPath(json, path)', () {
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
}

const prettyPrintResult = '''
{
  "a": {
    "b": 1,
    "c": 2
  }
}''';
