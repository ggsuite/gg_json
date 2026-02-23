// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// ignore_for_file: deprecated_member_use_from_same_package

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  group('DeepCopy', () {
    test('example JSON', () {
      // Verify that the result is equal to the original example JSON
      expect(deepCopy(exampleJson), exampleJson);
      expect(exampleJson.deepCopy(), exampleJson);
      expect(deepCopy(exampleJsonNested0), exampleJsonNested0);
      expect(deepCopy(exampleJsonNested1), exampleJsonNested1);
      expect(deepCopy(exampleJsonPrimitive), exampleJsonPrimitive);
    });

    group('with throwOnNonJsonObjects', () {
      final dateTime = DateTime.now();

      test('throws on non-JSON values', () {
        var message = <String>[];

        try {
          final json = {'valid': 'string', 'invalid': dateTime};
          deepCopy(json, throwOnNonJsonObjects: true);
        } catch (e) {
          message = (e as dynamic).message.toString().trim().split('\n');
        }
        expect(message, ['Value $dateTime is not a valid JSON value.']);
      });

      test('does not throw on non-JSON values', () {
        final json = {'valid': 'string', 'invalid': dateTime};
        expect(
          () => deepCopy(json, throwOnNonJsonObjects: false),
          returnsNormally,
        );
      });
    });

    group('with where', () {
      test('skips values where where returns false', () {
        final json = {
          'keep': 'this',
          'skip': 'that',
          'nested': {'keep': 'this too', 'skip': 'that too'},
        };

        final result = deepCopy(
          json,
          where: (value) => value.value != 'that' && value.value != 'that too',
        );

        expect(result, {
          'keep': 'this',
          'nested': {'keep': 'this too'},
        });
      });
    });
  });
}
