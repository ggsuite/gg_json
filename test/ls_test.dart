// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  group('Json.ls', () {
    group('returns a list of all paths in the JSON document', () {
      group('with including values', () {
        test('with simple object', () {
          expect({'a': 10}.ls(writeValues: true), ['/', '/a = 10']);
        });

        test('with nested object', () {
          expect(
            {
              'a': {'b': 10},
            }.ls(writeValues: true),
            ['/', '/a', '/a/b = 10'],
          );
        });

        test('with array', () {
          expect(
            {
              'a': [10, 20],
            }.ls(writeValues: true),
            ['/', '/a', '/a[0] = 10', '/a[1] = 20'],
          );
        });

        test('with array containing objects', () {
          expect(
            {
              'a': [
                {'b': 10},
                {'c': 20},
              ],
            }.ls(writeValues: true),
            ['/', '/a', '/a[0]/b = 10', '/a[1]/c = 20'],
          );
        });

        test('with complex exampleJsonNested0', () {
          final paths = exampleJsonNested0.ls(writeValues: true);
          expect(
            paths,
            containsAll(<String>[
              '/arrayValue[1] = 2',
              '/arrayValue[2] = 3',
              '/arrayValue[3]/innerKey = innerValue',
              '/numericVariants',
              '/numericVariants/positive = 100',
              '/numericVariants/negative = -50',
              '/numericVariants/floating = 0.001',
              '/numericVariants/scientific = 1000000.0',
              '/emptyObject',
              '/emptyArray',
            ]),
          );
        });
      });

      group('without including values', () {
        test('with simple object', () {
          expect({'a': 10}.ls(writeValues: false), ['/', '/a']);
        });

        test('with nested object', () {
          expect(
            {
              'a': {'b': 10},
            }.ls(writeValues: false),
            ['/', '/a', '/a/b'],
          );
        });

        test('with array', () {
          expect(
            {
              'a': [10, 20],
            }.ls(writeValues: false),
            ['/', '/a', '/a[0]', '/a[1]'],
          );
        });

        test('with array containing objects', () {
          expect(
            {
              'a': [
                {'b': 10},
                {'c': 20},
              ],
            }.ls(writeValues: false),
            ['/', '/a', '/a[0]/b', '/a[1]/c'],
          );
        });

        test('with complex exampleJsonNested0', () {
          final paths = exampleJsonNested0.ls(writeValues: false);
          expect(
            paths,
            containsAll(<String>[
              '/arrayValue[1]',
              '/arrayValue[2]',
              '/arrayValue[3]/innerKey',
              '/numericVariants',
              '/numericVariants/positive',
              '/numericVariants/negative',
              '/numericVariants/floating',
              '/numericVariants/scientific',
              '/emptyObject',
              '/emptyArray',
            ]),
          );
        });
      });

      group('without . separator', () {
        test('with simple object', () {
          expect({'a': 10}.ls(writeValues: false, separator: '.'), ['.', '.a']);
        });

        test('with nested object', () {
          expect(
            {
              'a': {'b': 10},
            }.ls(writeValues: false, separator: '.'),
            ['.', '.a', '.a.b'],
          );
        });

        test('with array', () {
          expect(
            {
              'a': [10, 20],
            }.ls(writeValues: false, separator: '.'),
            ['.', '.a', '.a[0]', '.a[1]'],
          );
        });

        test('with array containing objects', () {
          expect(
            {
              'a': [
                {'b': 10},
                {'c': 20},
              ],
            }.ls(writeValues: false, separator: '.'),
            ['.', '.a', '.a[0].b', '.a[1].c'],
          );
        });

        test('with complex exampleJsonNested0', () {
          final paths = exampleJsonNested0.ls(
            writeValues: false,
            separator: '.',
          );
          expect(
            paths,
            containsAll(<String>[
              '.arrayValue[1]',
              '.arrayValue[2]',
              '.arrayValue[3].innerKey',
              '.numericVariants',
              '.numericVariants.positive',
              '.numericVariants.negative',
              '.numericVariants.floating',
              '.numericVariants.scientific',
              '.emptyObject',
              '.emptyArray',
            ]),
          );
        });
      });

      test('excludes keys matching the exclude pattern', () {
        final json = {
          'a': 1,
          'b_exclude': 2,
          'c': {'b_exclude': 3},
        };

        final paths = json.ls(writeValues: true, exclude: RegExp('exclude'));

        expect(paths, ['/', '/a = 1', '/c']);
      });
    });
  });
}
