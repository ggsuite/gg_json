// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';

/// Defines the data of a slot tree
extension type JsonTags._(Json data) implements Json {
  // ...........................................................................
  /// Creates a [JsonTags] from a [Slot] and its metadata.
  factory JsonTags({Iterable<String>? tags}) {
    _throwWhenwWrongTag(tags);

    return JsonTags._({
      'tags': ?(tags?.isEmpty == true ? null : tags?.toSet().toList()),
    });
  }

  /// Creates a [JsonTags] JSON.
  factory JsonTags.fromJson(Json data) {
    return JsonTags._(data.deepCopy());
  }

  /// Creates an example [JsonTags].
  factory JsonTags.example({Iterable<String>? tags}) => JsonTags(tags: tags);

  // ...........................................................................
  /// Returns the tags
  List<String> get tags =>
      data.getOrNull<List<dynamic>>('tags')?.cast<String>() ?? [];

  /// Returns true if the [JsonTags] has the given tag.
  bool hasTag(String tag) => tags.contains(tag);

  /// Returns true if the [JsonTags] has all the given tags.
  bool hasTags(Iterable<String> tags) => tags.every(this.tags.contains);

  /// Add tags to the [JsonTags].
  void addTags(Iterable<String> newTags) {
    _throwWhenwWrongTag(newTags);
    if (newTags.isEmpty) return;
    final currentTags = tags;
    currentTags.addAll(newTags);
    this['tags'] = currentTags.toList();
  }

  /// Add a tag to the [JsonTags].
  void addTag(String tag) => addTags({tag});

  /// Remove tags from the [JsonTags].
  void removeTags(Iterable<String> tagsToRemove) {
    if (tagsToRemove.isEmpty) return;
    final currentTags = tags;
    currentTags.removeWhere(tagsToRemove.contains);
    this['tags'] = currentTags.toList();
  }

  /// Remove a tag from the [JsonTags].
  void removeTag(String tag) => removeTags({tag});

  // ...........................................................................
  static final _tagRegExp = RegExp(r'[^a-zA-Z0-9]');

  static void _throwWhenwWrongTag(Iterable<String>? tags) {
    if (tags == null) return;
    for (final tag in tags) {
      if (_tagRegExp.hasMatch(tag)) {
        throw Exception('Tag "$tag" must only contain letters and numbers.');
      }

      if (tag.isEmpty || !tag[0].toLowerCase().contains(tag[0])) {
        throw Exception('Tag "$tag" must start with a lowercase letter.');
      }
    }
  }
}
