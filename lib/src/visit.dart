// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';

/// Callback invoked by [JsonVisit.visit] for each entry in a JSON document.
///
/// - [key] is the [String] property name when [parent] is a [Map] or the
///   [int] index when [parent] is a [List].
/// - [value] is the entry's value.
/// - [parent] is the immediate container of the entry (a [Map] or [List]).
/// - [ancestors] starts with [parent] and continues up to the root document.
typedef VisitProp =
    void Function({
      dynamic key,
      dynamic value,
      dynamic parent,
      List<dynamic>? ancestors,
    });

/// Visits every entry in a JSON document.
extension JsonVisit on Json {
  // ...........................................................................
  /// Calls [callback] for every entry contained in this JSON document.
  ///
  /// The root object itself is not delivered to the callback because it has
  /// no parent. Map properties and list items at every depth are visited in
  /// document order.
  void visit(VisitProp callback) {
    _visit(this, [this], callback);
  }
}

// .............................................................................
void _visit(dynamic node, List<dynamic> ancestors, VisitProp callback) {
  if (node is Map<String, dynamic>) {
    // Snapshot keys so the callback may add, remove or rename entries on
    // [node] without triggering ConcurrentModificationError.
    for (final key in node.keys.toList(growable: false)) {
      if (!node.containsKey(key)) continue;
      final value = node[key];
      callback(key: key, value: value, parent: node, ancestors: ancestors);
      // Recurse into the value the callback was given, even if the parent's
      // key has since been renamed or removed. This keeps traversal
      // predictable: every value the callback saw is also walked.
      if (value is Map<String, dynamic> || value is List) {
        _visit(value, [value, ...ancestors], callback);
      }
    }
  } else if (node is List) {
    // Snapshot items so the callback may mutate [node] during iteration.
    final items = List<dynamic>.of(node);
    for (var i = 0; i < items.length; i++) {
      final value = items[i];
      callback(key: i, value: value, parent: node, ancestors: ancestors);
      if (value is Map<String, dynamic> || value is List) {
        _visit(value, [value, ...ancestors], callback);
      }
    }
  }
}
