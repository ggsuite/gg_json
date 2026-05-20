// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  group('Json.visit', () {
    test('visits a simple object', () {
      final json = {'a': 10};
      final calls = <Map<String, dynamic>>[];

      json.visit(({key, value, parent, ancestors}) {
        calls.add({
          'key': key,
          'value': value,
          'parent': parent,
          'ancestors': ancestors,
        });
      });

      expect(calls, [
        {
          'key': 'a',
          'value': 10,
          'parent': json,
          'ancestors': [json],
        },
      ]);
    });

    test('visits a nested object', () {
      final inner = {'b': 10};
      final json = {'a': inner};
      final calls = <Map<String, dynamic>>[];

      json.visit(({key, value, parent, ancestors}) {
        calls.add({
          'key': key,
          'value': value,
          'parent': parent,
          'ancestors': List<dynamic>.from(ancestors!),
        });
      });

      expect(calls, [
        {
          'key': 'a',
          'value': inner,
          'parent': json,
          'ancestors': [json],
        },
        {
          'key': 'b',
          'value': 10,
          'parent': inner,
          'ancestors': [inner, json],
        },
      ]);
    });

    test('visits array entries with integer keys', () {
      final list = [10, 20];
      final json = {'a': list};
      final calls = <Map<String, dynamic>>[];

      json.visit(({key, value, parent, ancestors}) {
        calls.add({
          'key': key,
          'value': value,
          'parent': parent,
          'ancestors': List<dynamic>.from(ancestors!),
        });
      });

      expect(calls, [
        {
          'key': 'a',
          'value': list,
          'parent': json,
          'ancestors': [json],
        },
        {
          'key': 0,
          'value': 10,
          'parent': list,
          'ancestors': [list, json],
        },
        {
          'key': 1,
          'value': 20,
          'parent': list,
          'ancestors': [list, json],
        },
      ]);
    });

    test('visits objects nested inside arrays', () {
      final firstItem = {'b': 10};
      final secondItem = {'c': 20};
      final list = [firstItem, secondItem];
      final json = {'a': list};

      final calls = <Map<String, dynamic>>[];

      json.visit(({key, value, parent, ancestors}) {
        calls.add({
          'key': key,
          'value': value,
          'parent': parent,
          'ancestors': List<dynamic>.from(ancestors!),
        });
      });

      expect(calls, [
        {
          'key': 'a',
          'value': list,
          'parent': json,
          'ancestors': [json],
        },
        {
          'key': 0,
          'value': firstItem,
          'parent': list,
          'ancestors': [list, json],
        },
        {
          'key': 'b',
          'value': 10,
          'parent': firstItem,
          'ancestors': [firstItem, list, json],
        },
        {
          'key': 1,
          'value': secondItem,
          'parent': list,
          'ancestors': [list, json],
        },
        {
          'key': 'c',
          'value': 20,
          'parent': secondItem,
          'ancestors': [secondItem, list, json],
        },
      ]);
    });

    test('visits lists nested inside lists', () {
      final innerList = [1, 2];
      final outerList = [innerList];
      final json = {'a': outerList};
      final calls = <Map<String, dynamic>>[];

      json.visit(({key, value, parent, ancestors}) {
        calls.add({
          'key': key,
          'value': value,
          'parent': parent,
          'ancestors': List<dynamic>.from(ancestors!),
        });
      });

      expect(calls, [
        {
          'key': 'a',
          'value': outerList,
          'parent': json,
          'ancestors': [json],
        },
        {
          'key': 0,
          'value': innerList,
          'parent': outerList,
          'ancestors': [outerList, json],
        },
        {
          'key': 0,
          'value': 1,
          'parent': innerList,
          'ancestors': [innerList, outerList, json],
        },
        {
          'key': 1,
          'value': 2,
          'parent': innerList,
          'ancestors': [innerList, outerList, json],
        },
      ]);
    });

    test('does not invoke the callback for an empty object', () {
      var called = false;
      <String, dynamic>{}.visit(({key, value, parent, ancestors}) {
        called = true;
      });
      expect(called, isFalse);
    });

    group('allows mutation during iteration', () {
      test('renames map keys while visiting', () {
        final json = <String, dynamic>{
          'a': 1,
          'b': {'c': 2, 'd': 3},
        };

        json.visit(({key, value, parent, ancestors}) {
          if (key is String && parent is Map<String, dynamic>) {
            parent.remove(key);
            parent['renamed_$key'] = value;
          }
        });

        expect(json, {
          'renamed_a': 1,
          'renamed_b': {'renamed_c': 2, 'renamed_d': 3},
        });
      });

      test('removes map entries while visiting', () {
        final json = <String, dynamic>{
          'keep': 1,
          'drop': 2,
          'nested': {'keep': 3, 'drop': 4},
        };

        json.visit(({key, value, parent, ancestors}) {
          if (key == 'drop' && parent is Map<String, dynamic>) {
            parent.remove(key);
          }
        });

        expect(json, {
          'keep': 1,
          'nested': {'keep': 3},
        });
      });

      test('adds new entries to a map without revisiting them', () {
        final json = <String, dynamic>{'a': 1, 'b': 2};
        final visitedKeys = <dynamic>[];

        json.visit(({key, value, parent, ancestors}) {
          visitedKeys.add(key);
          if (parent is Map<String, dynamic> && !parent.containsKey('added')) {
            parent['added'] = 'late';
          }
        });

        expect(visitedKeys, ['a', 'b']);
        expect(json, {'a': 1, 'b': 2, 'added': 'late'});
      });

      test('allows removing items from a list while visiting', () {
        final list = [1, 2, 3, 4];
        final json = <String, dynamic>{'items': list};
        final visitedValues = <dynamic>[];

        json.visit(({key, value, parent, ancestors}) {
          if (parent is List) {
            visitedValues.add(value);
            if (value == 2 || value == 3) {
              parent.remove(value);
            }
          }
        });

        expect(visitedValues, [1, 2, 3, 4]);
        expect(list, [1, 4]);
      });

      test('allows replacing items in a list while visiting', () {
        final list = [1, 2, 3];
        final json = <String, dynamic>{'items': list};

        json.visit(({key, value, parent, ancestors}) {
          if (parent is List && value is int) {
            parent[key as int] = value * 10;
          }
        });

        expect(list, [10, 20, 30]);
      });

      test('allows appending items to a list while visiting', () {
        final list = <dynamic>[1, 2];
        final json = <String, dynamic>{'items': list};
        final visitedValues = <dynamic>[];

        json.visit(({key, value, parent, ancestors}) {
          if (parent is List) {
            visitedValues.add(value);
            if (value == 1) {
              parent.add(99);
            }
          }
        });

        expect(visitedValues, [1, 2]);
        expect(list, [1, 2, 99]);
      });
    });

    test('walks the full exampleJsonNested0 document', () {
      final keys = <dynamic>[];
      exampleJsonNested0.visit(({key, value, parent, ancestors}) {
        keys.add(key);
      });

      // Spot check: every leaf of the example document is reached.
      expect(keys, contains('object'));
      expect(keys, contains('string'));
      expect(keys, contains('deepKey'));
      expect(keys, contains('innerKey'));
      expect(keys, contains('scientific'));
      expect(keys, contains(0));
      expect(keys, contains(7));
    });
  });
}
