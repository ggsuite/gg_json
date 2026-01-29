// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:gg_test_matchers/gg_test_matchers.dart';
import 'package:test/test.dart';

void main() {
  group('Json', () {
    group('exampleJson', () {
      test('should work', () {
        const json = exampleJsonNested1;
        expect(
          json,
          deepJsonContains({
            'name': 'John Doe',
            'age': 30,
            'isEmployed': true,
            'address': {
              'street': '123 Main St',
              'city': 'Anytown',
              'postalCode': '12345',
            },
            'phoneNumbers': [
              {'type': 'home', 'number': '555-1234'},
              {'type': 'work', 'number': '555-5678'},
            ],
            'skills': ['Dart', 'Flutter', 'JSON'],
            'projects': [
              {
                'name': 'Project A',
                'durationMonths': 6,
                'technologies': ['Dart', 'Firebase'],
              },
              {
                'name': 'Project B',
                'durationMonths': 12,
                'technologies': ['Flutter', 'GraphQL'],
              },
            ],
          }),
        );
      });
    });
  });
}
