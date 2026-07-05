// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:collection';

import 'package:gg_json/gg_json.dart';

/// Callback invoked by [JsonVisit.visit] for each entry in a JSON document.
///
/// - [key] is the [String] property name when [parent] is a [Map] or the
///   [int] index when [parent] is a [List].
/// - [value] is the entry's value.
/// - [parent] is the immediate container of the entry (a [Map] or [List]).
/// - [ancestors] starts with [parent] and continues up to the root document.
typedef VisitProp =
    void Function(
      dynamic key,
      dynamic value,
      dynamic parent,
      List<dynamic> ancestors,
    );

/// Visits every entry in a JSON document.
extension JsonVisit on Json {
  // ...........................................................................
  /// Calls [callback] for every entry contained in this JSON document.
  ///
  /// The root object itself is not delivered to the callback because it has
  /// no parent. Map properties and list items at every depth are visited in
  /// document order.
  ///
  /// The callback may add, remove or rename entries on the visited node:
  /// map keys and list items are snapshotted per node, and keys removed
  /// during the visit are skipped.
  ///
  /// **Important:** the `ancestors` argument is a live, read-only view onto
  /// the traversal stack. It is only valid during the callback invocation.
  /// Callers who want to retain it beyond the callback must copy it, e.g.
  /// with `List.of(ancestors)`.
  void visit(VisitProp callback) {
    final visitor = _Visitor(callback);
    visitor.push(this);
    visitor.visitMap(this);
  }
}

// .............................................................................
/// A read-only, reversed view onto the traversal stack.
///
/// The stack grows root-first, but callbacks expect ancestors nearest-first
/// (`ancestors[0]` is the parent, the last element is the root). This view
/// performs that reversal lazily without copying.
class _AncestorsView extends ListBase<dynamic> {
  _AncestorsView(this._visitor);

  final _Visitor _visitor;

  @override
  int get length => _visitor.depth;

  @override
  set length(int newLength) =>
      throw UnsupportedError('Cannot modify ancestors');

  @override
  dynamic operator [](int index) {
    final visitor = _visitor;
    return visitor.stack[visitor.depth - 1 - index];
  }

  @override
  void operator []=(int index, dynamic value) =>
      throw UnsupportedError('Cannot modify ancestors');
}

// .............................................................................
/// Holds the traversal state of a single [JsonVisit.visit] call.
///
/// All state lives in one object so the recursive walkers pass a single
/// reference instead of many arguments. The ancestors stack is a manually
/// managed array ([stack] plus [depth]) because pushing and popping plain
/// array slots is cheaper than growing and shrinking a growable list on
/// every container node.
class _Visitor {
  _Visitor(this.callback) {
    ancestors = _AncestorsView(this);
    // Created once per visit() call and reused for every single-entry map,
    // so the traversal performs no per-node closure allocations.
    _collectOne = (String key, dynamic value) {
      _oneKey = key;
      _oneVal = value;
    };
  }

  /// The user callback.
  final VisitProp callback;

  /// The ancestors stack, root at index 0. Slots above [depth] are stale.
  List<Object?> stack = List<Object?>.filled(32, null);

  /// The number of live entries in [stack].
  int depth = 0;

  /// The reversed read-only view handed to the callback.
  late final _AncestorsView ancestors;

  /// Receives the single entry of a one-entry map via Map.forEach.
  late final void Function(String, dynamic) _collectOne;
  String _oneKey = '';
  dynamic _oneVal;

  // ...........................................................................
  /// Pushes [node] onto the ancestors stack.
  void push(Object node) {
    var s = stack;
    final d = depth;
    if (d == s.length) {
      s = List<Object?>.filled(d * 2, null)..setRange(0, d, s);
      stack = s;
    }
    s[d] = node;
    depth = d + 1;
  }

  // ...........................................................................
  /// Visits all entries of [node].
  void visitMap(Map<String, dynamic> node) {
    if (node.length == 1) {
      // Fast path for single-entry maps (e.g. deep chains): Map.forEach
      // hands out the one key and value without allocating a key snapshot,
      // and the value is guaranteed fresh because no callback can run
      // between entering the node and delivering its first entry.
      node.forEach(_collectOne);
      final key = _oneKey;
      final value = _oneVal;
      _oneVal = null;
      callback(key, value, node, ancestors);
      if (value is Map<String, dynamic>) {
        push(value);
        visitMap(value);
        depth--;
      } else if (value is List) {
        push(value);
        visitList(value);
        depth--;
      }
      return;
    }

    // Snapshot keys so the callback may add, remove or rename entries on
    // [node] without triggering ConcurrentModificationError.
    final keys = node.keys.toList(growable: false);
    final length = keys.length;
    final cb = callback;
    final anc = ancestors;
    for (var i = 0; i < length; i++) {
      final key = keys[i];
      final value = node[key];
      // Skip keys removed by the callback. Only fall back to containsKey
      // when the value is null, avoiding a double lookup in the common case.
      if (value == null && !node.containsKey(key)) continue;
      cb(key, value, node, anc);
      // Recurse into the value the callback was given, even if the parent's
      // key has since been renamed or removed. This keeps traversal
      // predictable: every value the callback saw is also walked.
      if (value is Map<String, dynamic>) {
        push(value);
        visitMap(value);
        depth--;
      } else if (value is List) {
        push(value);
        visitList(value);
        depth--;
      }
    }
  }

  // ...........................................................................
  /// Visits all items of [node].
  void visitList(List<dynamic> node) {
    // Snapshot items so the callback may mutate [node] during iteration.
    final items = List<dynamic>.of(node, growable: false);
    final length = items.length;
    final cb = callback;
    final anc = ancestors;
    for (var i = 0; i < length; i++) {
      final value = items[i];
      cb(i, value, node, anc);
      if (value is Map<String, dynamic>) {
        push(value);
        visitMap(value);
        depth--;
      } else if (value is List) {
        push(value);
        visitList(value);
        depth--;
      }
    }
  }
}
