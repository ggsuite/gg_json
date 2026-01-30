// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/src/json_string.dart';
import 'package:test/test.dart';

void main() {
  group('JsonString', () {
    group('setJsonValue', () {
      group('writes the value into json', () {
        test('- with an empty json', () {
          const json = '{}';
          final result = json.setJsonValue('a/b', 1);
          expect(result, '{"a":{"b":1}}');

          final result2 = json.setJsonValue('a/b', 1, prettyPrint: true);
          expect(result2.split('\n'), [
            '{',
            '  "a": {',
            '    "b": 1',
            '  }',
            '}',
          ]);
        });

        test('- with an empty string', () {
          const json = '';
          final result = json.setJsonValue('a/b', 1);
          expect(result, '{"a":{"b":1}}');
        });

        test('- with an existing value', () {
          const json = '{"a":{"b":1}}';
          final result = json.setJsonValue('a/c', 2);
          expect(result, '{"a":{"b":1,"c":2}}');
        });

        test('- with prettyPrint', () {
          const json = '{"a":{"b":1}}';
          final result = json.setJsonValue('a/c', 2, prettyPrint: false);
          expect(result, '{"a":{"b":1,"c":2}}');
        });
      });

      group('throws', () {
        test('- when an existing value is not of type T', () {
          const json = '{"a":{"b":1}}';

          var message = '';
          try {
            json.setJsonValue('a/b', '2');
          } catch (e) {
            message = (e as dynamic).message as String;
          }

          expect(message, 'Existing value 1 is not of type String.');
        });
      });
    });

    group('getJsonValue', () {
      group('returns the value from json', () {
        test('- with an existing value', () {
          const json = '{"a":{"b":1}}';
          final result = json.getJsonValue<int>('a/b');
          expect(result, 1);
        });

        test('- with a non-existing value', () {
          const json = '{"a":{"b":1}}';
          final result = json.getJsonValue<int>('a/c');
          expect(result, null);
        });
      });

      group('throws', () {
        test('- when value is not of type T', () {
          const json = '{"a":{"b":1}}';
          var message = '';
          try {
            json.getJsonValue<String>('a/b');
          } catch (e) {
            message = (e as dynamic).message as String;
          }

          expect(message, 'Existing value 1 is not of type String.');
        });
      });
    });

    group('removeJsonValue', () {
      test('removes the value from json', () {
        const json = '{"a":{"b":1,"c":2}}';
        final result = json.removeJsonValue('a/b');
        expect(result, '{"a":{"c":2}}');

        final result2 = json.removeJsonValue('a/b', prettyPrint: true);
        expect(result2.split('\n'), [
          '{',
          '  "a": {',
          '    "c": 2',
          '  }',
          '}',
        ]);
      });
    });
  });
}
