// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';
import 'package:test/test.dart';

void main() {
  group('JsonTags', () {
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
        expect(data.tags, <String>{});
      });

      test('returns the tags that were set', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2']);
        expect(data.tags, {'tag1', 'tag2'});
      });
    });

    group('hasTag', () {
      test('returns true when tag exists', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2']);
        expect(data.hasTag('tag1'), isTrue);
      });

      test('returns false when tag does not exist', () {
        final data = JsonTags.example(tags: ['tag1']);
        expect(data.hasTag('tag2'), isFalse);
      });
    });

    group('hasTags', () {
      test('returns true when all tags exist', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2', 'tag3']);
        expect(data.hasTags(['tag1', 'tag2']), isTrue);
      });

      test('returns false when any tag is missing', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2']);
        expect(data.hasTags(['tag1', 'tag3']), isFalse);
      });
    });

    group('addTag', () {
      test('adds a new tag', () {
        final data = JsonTags.example(tags: ['tag1']);
        data.addTag('tag2');
        expect(data.tags, {'tag1', 'tag2'});
      });

      test('does not duplicate existing tag', () {
        final data = JsonTags.example(tags: ['tag1']);
        data.addTag('tag1');
        expect(data.tags, {'tag1'});
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

    group('addTags', () {
      test('adds multiple new tags', () {
        final data = JsonTags.example(tags: ['tag1']);
        data.addTags(['tag2', 'tag3']);
        expect(data.tags, {'tag1', 'tag2', 'tag3'});
      });

      test('handles duplicate tags in input', () {
        final data = JsonTags.example(tags: ['tag1']);
        data.addTags(['tag2', 'tag1', 'tag3']);
        expect(data.tags, {'tag1', 'tag2', 'tag3'});
      });
    });

    group('removeTag', () {
      test('removes an existing tag', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2']);
        data.removeTag('tag1');
        expect(data.tags, {'tag2'});
      });

      test('does nothing if tag does not exist', () {
        final data = JsonTags.example(tags: ['tag1']);
        data.removeTag('tag2');
        expect(data.tags, {'tag1'});
      });
    });

    group('removeTags', () {
      test('removes multiple existing tags', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2', 'tag3']);
        data.removeTags(['tag1', 'tag3']);
        expect(data.tags, {'tag2'});
      });

      test('handles non-existing tags gracefully', () {
        final data = JsonTags.example(tags: ['tag1', 'tag2']);
        data.removeTags(['tag3', 'tag1']);
        expect(data.tags, {'tag2'});
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
      expect(tags.tags, ['a', 'b', 'c']);
    });
  });
}
