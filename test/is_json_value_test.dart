// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  group('isJsonValue', () {
    test('valid JSON values', () {
      expect(isJsonValue('string'), isTrue);
      expect(isJsonValue(42), isTrue);
      expect(isJsonValue(3.14), isTrue);
      expect(isJsonValue(true), isTrue);
      expect(isJsonValue(false), isTrue);
      expect(isJsonValue(null), isTrue);
      expect(isJsonValue({'key': 'value'}), isTrue);
      expect(isJsonValue([1, 2, 3]), isTrue);
      expect(
        isJsonValue({
          'name': 'Alice',
          'age': 25,
          'isStudent': false,
          'courses': ['Math', 'Science'],
          'address': {
            'street': '456 Elm St',
            'city': 'Othertown',
            'postalCode': '67890',
          },
        }),
        isTrue,
      );
    });

    test('invalid JSON values', () {
      expect(isJsonValue(DateTime.now()), isFalse);
      expect(isJsonValue(RegExp(r'\d+')), isFalse);
      expect(isJsonValue(Object()), isFalse);
      expect(isJsonValue({'key': Object()}), isFalse);
      expect(isJsonValue([1, 2, Object()]), isFalse);

      final example = deepCopy(exampleJson);
      example['groups'][0] = Object();
      expect(isJsonValue(example), isFalse);
    });
  });
}
