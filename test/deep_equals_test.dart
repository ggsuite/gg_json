// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  group('deeplEqualsJson(jsonA, jsonB)', () {
    late Json jsonA;
    late Json jsonB;

    setUp(() {
      jsonA = deepCopy(exampleJson);
      jsonB = deepCopy(exampleJson);
    });

    group('result', () {
      test('returns true for JSON with same content', () {
        final result = deeplEquals(jsonA, jsonB);
        expect(result, isTrue);
      });

      group('returns false for different JSON', () {
        test('with root value changed', () {
          jsonB['newKey'] = 'newValue'; // Modify jsonB to be different
          final result = deeplEquals(jsonA, jsonB);
          expect(result, isFalse);
        });

        test('with list value changed', () {
          jsonB['skills'] = ['Dart', 'Flutter', 'JavaScript']; // Modify jsonB
          final result = deeplEquals(jsonA, jsonB);
          expect(result, isFalse);
        });

        test('with deep list value changed', () {
          jsonB['groups'][1] = ['guest', 'friend']; // Modify jsonB
          final result = deeplEquals(jsonA, jsonB);
          expect(result, isFalse);
        });
      });
    });
  });
}
