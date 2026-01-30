// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  group('isDartIdentifier', () {
    group('returns true', () {
      group('when input is a valid json identifier', () {
        final validIdentifiers = [
          'simpleIdentifier',
          '_privateIdentifier',
          'camelCase123',
          'with_Underscores',
          r'dollar$Sign',
          'A',
          '_',
          r'$',
        ];

        for (final identifier in validIdentifiers) {
          test('valid identifier: "$identifier"', () {
            expect(isValidJsonKey(identifier), isTrue);
          });
        }
      });
    });

    group('returns false', () {
      group('when input is not a valid json identifier', () {
        final invalidIdentifiers = [
          '123startsWithNumber',
          'contains-hyphen',
          'has space',
          'special@char',
          '',
          ' ',
          'with.dot',
        ];

        for (final identifier in invalidIdentifiers) {
          test('invalid identifier: "$identifier"', () {
            expect(isValidJsonKey(identifier), isFalse);
          });
        }
      });
    });

    group('throwIfNotDartIdentifier', () {
      test('does not throw for valid identifiers', () {
        final validIdentifiers = ['validIdentifier', '_alsoValid123'];

        for (final identifier in validIdentifiers) {
          expect(() => throwIfNotValidJsonKey(identifier), returnsNormally);
        }
      });

      test('throws Exception for invalid identifiers', () {
        final invalidIdentifiers = [
          'invalid-identifier',
          '123invalid',
          'has space',
        ];

        for (final identifier in invalidIdentifiers) {
          var message = '';
          try {
            throwIfNotValidJsonKey(identifier);
          } catch (e) {
            message = (e as dynamic).message as String;
          }

          expect(message, '$identifier is not a valid json identifier');
        }
      });
    });
  });
}
