// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  group('jsonMergePatch', () {
    test('deep-merges objects by default', () {
      final r = jsonMergePatch(
        {
          'a': {'x': 1, 'y': 2},
          'b': 1,
        },
        {
          'a': {'y': 3, 'z': 4},
        },
        context: 't',
      );
      expect(r.value, {
        'a': {'x': 1, 'y': 3, 'z': 4},
        'b': 1,
      });
      expect(r.warnings, isEmpty);
    });

    test('replaces scalars and arrays without suffix', () {
      final r = jsonMergePatch(
        {
          'a': [1, 2],
          'b': 'old',
        },
        {
          'a': [3],
          'b': 'new',
        },
        context: 't',
      );
      expect(r.value, {
        'a': [3],
        'b': 'new',
      });
    });

    test('null deletes the key', () {
      final r = jsonMergePatch({'a': 1, 'b': 2}, {'a': null}, context: 't');
      expect(r.value, {'b': 2});
    });

    test('"key!" replaces the value outright instead of merging', () {
      final r = jsonMergePatch(
        {
          'a': {'x': 1, 'y': 2},
        },
        {
          'a!': {'z': 3},
        },
        context: 't',
      );
      expect(r.value, {
        'a': {'z': 3},
      });
    });

    test('"key!" with null sets a literal null', () {
      final r = jsonMergePatch({'a': 1}, {'a!': null}, context: 't');
      expect((r.value! as Map).containsKey('a'), isTrue);
      expect((r.value! as Map)['a'], isNull);
    });

    test('"key+" joins arrays with dedup', () {
      final r = jsonMergePatch(
        {
          'recommendations': ['a', 'b'],
        },
        {
          'recommendations+': ['b', 'c'],
        },
        context: 'extensions.json',
      );
      expect(r.value, {
        'recommendations': ['a', 'b', 'c'],
      });
      expect(r.warnings, isEmpty);
    });

    test('"key+" on non-array target warns and replaces', () {
      final r = jsonMergePatch(
        {'a': 'scalar'},
        {
          'a+': [1],
        },
        context: 't',
      );
      expect(r.value, {
        'a': [1],
      });
      expect(r.warnings.single, contains('non-array'));
    });

    test('"key+" with non-array patch value warns and replaces', () {
      final r = jsonMergePatch(
        {
          'a': [1],
        },
        {'a+': 'x'},
        context: 't',
      );
      expect(r.value, {'a': 'x'});
      expect(r.warnings.single, contains('expects an array'));
    });

    test('a map patch on a non-map target starts from an empty object', () {
      final r = jsonMergePatch('scalar', {'a': 1}, context: 't');
      expect(r.value, {'a': 1});
      final fromNull = jsonMergePatch(null, {'a': 1}, context: 't');
      expect(fromNull.value, {'a': 1});
    });

    test('non-map patch replaces the whole target', () {
      final r = jsonMergePatch({'a': 1}, [1, 2], context: 't');
      expect(r.value, [1, 2]);
    });

    test('creates missing keys and keeps base key order', () {
      final r = jsonMergePatch(
        {'b': 1, 'a': 2},
        {'c': 3, 'a': 4},
        context: 't',
      );
      expect((r.value! as Map<String, dynamic>).keys.toList(), ['b', 'a', 'c']);
    });

    test('is idempotent', () {
      final patch = {
        'a': {'x': 1},
        'r+': ['n'],
      };
      final once = jsonMergePatch(
        {
          'r': ['m'],
        },
        patch,
        context: 't',
      );
      final twice = jsonMergePatch(once.value, patch, context: 't');
      expect(twice.value, once.value);
    });

    test('warning context includes nested path', () {
      final r = jsonMergePatch(
        {
          'outer': {'inner': 1},
        },
        {
          'outer': {
            'inner+': [1],
          },
        },
        context: 'file.json',
      );
      expect(r.warnings.single, contains('file.json/outer'));
    });
  });

  group('joinArrays', () {
    test('appends only new entries, deep equality', () {
      final joined = joinArrays(
        [
          {'a': 1},
          'x',
        ],
        [
          {'a': 1},
          'y',
        ],
      );
      expect(joined, [
        {'a': 1},
        'x',
        'y',
      ]);
    });
  });

  group('encodeJsonPretty', () {
    test('two-space indent and trailing newline', () {
      expect(encodeJsonPretty({'a': 1}), '{\n  "a": 1\n}\n');
    });
  });
}
