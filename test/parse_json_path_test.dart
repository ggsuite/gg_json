// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  group('parseJsonPath', () {
    test('splits path into segments', () {
      expect(parseJsonPath('a/b/c'), ['a', 'b', 'c']);
      expect(parseJsonPath('/a/b/c/'), ['a', 'b', 'c']);
      expect(parseJsonPath('/a/b/c/'), ['a', 'b', 'c']);
      expect(parseJsonPath('//a/b/c/'), ['a', 'b', 'c']);
      expect(parseJsonPath('a.b.c'), ['a', 'b', 'c']);
      expect(parseJsonPath('a..b.c'), ['a', 'b', 'c']);
      expect(parseJsonPath('.a.b.c.'), ['a', 'b', 'c']);
      expect(parseJsonPath('a/b.c/d'), ['a', 'b', 'c', 'd']);
    });

    test('throws on invalid characters', () {
      var message = '';
      try {
        parseJsonPath('a/b c/d');
      } catch (e) {
        message = (e as dynamic).message as String;
      }

      expect(message, 'Invalid chars in path segment "b c".');
    });
  });
}
