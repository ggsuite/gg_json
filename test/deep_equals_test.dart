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
      jsonA = deepCopy(exampleJsonNested1);
      jsonB = deepCopy(exampleJsonNested1);
    });

    group('result', () {
      test('returns true for JSON with same content', () {
        final result = deeplEquals(jsonA, jsonB);

        expect(result, isTrue);

        expect(deeplEquals(deepCopy(exampleJson), exampleJson), isTrue);

        expect(
          deeplEquals(deepCopy(exampleJsonNested0), exampleJsonNested0),
          isTrue,
        );

        expect(
          deeplEquals(deepCopy(exampleJsonNested1), exampleJsonNested1),
          isTrue,
        );

        expect(
          deeplEquals(deepCopy(exampleJsonPrimitive), exampleJsonPrimitive),
          isTrue,
        );
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

    group('with differing key order', () {
      test('still returns true for the same content', () {
        final a = {'x': 1, 'y': 2, 'z': 3};
        final b = {'z': 3, 'x': 1, 'y': 2};
        expect(deeplEquals(a, b), isTrue);
      });

      test('returns false when the content actually differs', () {
        final a = {'x': 1, 'y': 2, 'z': 3};
        final b = {'z': 3, 'x': 1, 'y': 99};
        expect(deeplEquals(a, b), isFalse);
      });

      test('returns false when a null value in a is missing as a key in b', () {
        // Same length and key order differs (forcing the lookup-based
        // fallback path); 'y' is explicitly null in a but the key is
        // entirely absent in b (b has 'w' instead), so the containsKey
        // disambiguation for the null lookup must kick in.
        final a = {'x': 1, 'y': null, 'z': 3};
        final b = {'x': 1, 'w': null, 'z': 3};
        expect(deeplEquals(a, b), isFalse);
      });

      test(
        'returns true when a null value in a matches an explicit null in b',
        () {
          // Same keys, reordered, so the lookup-based fallback path runs;
          // 'y' is null in both, and the key genuinely exists in b.
          final a = {'x': 1, 'y': null, 'z': 3};
          final b = {'z': 3, 'x': 1, 'y': null};
          expect(deeplEquals(a, b), isTrue);
        },
      );

      test(
        'compares nested map values within the lookup-based fallback path',
        () {
          // Reordered top-level keys force the fallback path; the nested
          // map value must still be compared deeply, both when equal and
          // when it differs.
          final aEqual = {
            'x': 1,
            'nested': {'a': 1, 'b': 2},
          };
          final bEqual = {
            'nested': {'a': 1, 'b': 2},
            'x': 1,
          };
          expect(deeplEquals(aEqual, bEqual), isTrue);

          final bDifferent = {
            'nested': {'a': 1, 'b': 99},
            'x': 1,
          };
          expect(deeplEquals(aEqual, bDifferent), isFalse);
        },
      );

      test(
        'compares nested list values within the lookup-based fallback path',
        () {
          // Reordered top-level keys force the fallback path; the nested
          // list value must still be compared deeply, both when equal and
          // when it differs.
          final aEqual = {
            'x': 1,
            'nested': [1, 2, 3],
          };
          final bEqual = {
            'nested': [1, 2, 3],
            'x': 1,
          };
          expect(deeplEquals(aEqual, bEqual), isTrue);

          final bDifferent = {
            'nested': [1, 2, 99],
            'x': 1,
          };
          expect(deeplEquals(aEqual, bDifferent), isFalse);
        },
      );
    });
  });
}
