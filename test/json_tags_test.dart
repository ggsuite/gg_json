// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  group('JsonTags', () {
    group('manage', () {
      test('manages json tags for a given JSON', () {
        final json = Json();
        final jsonTags = JsonTags.manage(json);
        jsonTags.addAll(['tag0', 'tag1']);
        expect(json, {
          'tags': ['tag0', 'tag1'],
        });
      });
    });

    group('creates no JSON tags entry', () {
      test('when null', () {
        final data = JsonTags.example(tags: null);
        expect(data.containsKey('tags'), isFalse);
      });

      test('when empty', () {
        final data = JsonTags.example(tags: {});
        expect(data.containsKey('tags'), isFalse);
      });
    });

    group('tags', () {
      test('returns empty set when no tags are set', () {
        final data = JsonTags.example();
        data.remove('tags');
        expect(data.all, <String>{});
      });

      test('returns the tags that were set', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2']);
        expect(data.all, {'tag1', 'tag2'});
      });
    });

    group('contains', () {
      test('returns true when tag exists', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2']);
        expect(data.contains('tag1'), isTrue);
      });

      test('returns false when tag does not exist', () {
        final data = JsonTags.example(tags: ['tag1']);
        expect(data.contains('tag2'), isFalse);
      });
    });

    group('containsAll', () {
      test('returns true when all tags exist', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2', 'tag3']);
        expect(data.containsAll(['tag1', 'tag2']), isTrue);
      });

      test('returns false when any tag is missing', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2']);
        expect(data.containsAll(['tag1', 'tag3']), isFalse);
      });
    });

    group('add', () {
      test('adds a new tag', () {
        final data = JsonTags.example(tags: ['tag1']);
        data.add('tag2');
        expect(data.all, {'tag1', 'tag2'});
      });

      test('does not duplicate existing tag', () {
        final data = JsonTags.example(tags: ['tag1']);
        data.add('tag1');
        expect(data.all, {'tag1'});
      });

      group('throws, when tags', () {
        test('start with uppercase letter', () {
          var messages = <String>[];
          try {
            JsonTags.example(tags: ['Tag1']);
          } catch (e) {
            messages = ((e as dynamic).message as String).split('\n');
          }

          expect(messages, ['Tag "Tag1" must start with a lowercase letter.']);
        });

        test('when contain non-alphanumeric characters', () {
          var messages = <String>[];
          try {
            JsonTags.example(tags: ['tag-1']);
          } catch (e) {
            messages = ((e as dynamic).message as String).split('\n');
          }

          expect(messages, [
            'Tag "tag-1" must only contain letters and numbers.',
          ]);
        });
      });
    });

    group('addAll', () {
      test('adds multiple new tags', () {
        final data = JsonTags.example(tags: ['tag1']);
        data.addAll(['tag2', 'tag3']);
        expect(data.all, {'tag1', 'tag2', 'tag3'});
      });

      test('handles duplicate tags in input', () {
        final data = JsonTags.example(tags: ['tag1']);
        data.addAll(['tag2', 'tag1', 'tag3']);
        expect(data.all, {'tag1', 'tag2', 'tag3'});
      });
    });

    group('removeTag', () {
      test('removes an existing tag', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2']);
        data.remove('tag1');
        expect(data.all, {'tag2'});
      });

      test('does nothing if tag does not exist', () {
        final data = JsonTags.example(tags: ['tag1']);
        data.remove('tag2');
        expect(data.all, {'tag1'});
      });
    });

    group('removeAll', () {
      test('removes multiple existing tags', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2', 'tag3']);
        data.removeAll(['tag1', 'tag3']);
        expect(data.all, {'tag2'});
      });

      test('handles non-existing tags gracefully', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2']);
        data.removeAll(['tag3', 'tag1']);
        expect(data.all, {'tag2'});
      });
    });

    test('Write tags into existing JSON', () {
      final json = {
        'hello': 'world',
        ...JsonTags(tags: ['a', 'b', 'c']),
      };

      expect(json, {
        'hello': 'world',
        'tags': ['a', 'b', 'c'],
      });

      final tags = JsonTags.fromJson(json);
      expect(tags.all, ['a', 'b', 'c']);
    });
  });
}
