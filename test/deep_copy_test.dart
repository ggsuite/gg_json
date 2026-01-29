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
    test('example JSON deep copy', () {
      final result = deepCopy(exampleJson);

      // Verify that the result is equal to the original example JSON
      expect(result, exampleJson);
    });
  });
}
