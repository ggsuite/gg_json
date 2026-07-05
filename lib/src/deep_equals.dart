// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json/gg_json.dart';

/// Returns true if JSON documents [a] and [b] are deeply equal.
bool deeplEquals(Json a, Json b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;

  // Fast path: walk both maps in parallel. The Map contract guarantees that
  // keys and values iterate in the same order, so as long as both maps agree
  // on key order no hashed lookups are needed at all. Deep copies and decoded
  // JSON documents preserve insertion order, so this is the common case.
  final aKeys = a.keys.iterator;
  final bKeys = b.keys.iterator;
  final aValues = a.values.iterator;
  final bValues = b.values.iterator;

  while (aKeys.moveNext()) {
    bKeys.moveNext();
    aValues.moveNext();
    bValues.moveNext();

    // Copies share key string instances, so identical() usually hits.
    final ka = aKeys.current;
    final kb = bKeys.current;
    if (!identical(ka, kb) && ka != kb) {
      // Key order differs: fall back to lookup-based comparison.
      return _deepEqualsByLookup(a, b);
    }

    final va = aValues.current;
    final vb = bValues.current;

    // Common case first: equal primitives. Also short-circuits identical
    // Map/List instances, since their == is identity. The key exists in both
    // maps here, so a null value needs no containsKey disambiguation.
    if (va == vb) continue;

    if (va is Map<String, dynamic>) {
      if (vb is! Map<String, dynamic> || !deeplEquals(va, vb)) return false;
    } else if (va is List) {
      if (vb is! List || !deepEqualsList(va, vb)) return false;
    } else {
      return false;
    }
  }

  return true;
}

// ...........................................................................
// Slow path for maps whose key order differs: look every key of [a] up in
// [b]. Lengths are already known to be equal.
bool _deepEqualsByLookup(Json a, Json b) {
  for (final key in a.keys) {
    final va = a[key];
    final vb = b[key];

    // Common case first: equal primitives. Also short-circuits identical
    // Map/List instances, since their == is identity.
    if (va == vb) {
      // A null lookup is ambiguous: the key may be missing in b.
      if (va == null && !b.containsKey(key)) return false;
      continue;
    }

    if (va is Map<String, dynamic>) {
      if (vb is! Map<String, dynamic> || !deeplEquals(va, vb)) return false;
    } else if (va is List) {
      if (vb is! List || !deepEqualsList(va, vb)) return false;
    } else {
      return false;
    }
  }

  return true;
}

// ...........................................................................
/// Returns true if JSON Lists are deeply equal
bool deepEqualsList(List<dynamic> la, List<dynamic> lb) {
  if (identical(la, lb)) return true;
  final length = la.length;
  if (length != lb.length) return false;
  for (var i = 0; i < length; i++) {
    final va = la[i];
    final vb = lb[i];

    // Common case first: equal primitives. Also short-circuits identical
    // Map/List instances, since their == is identity.
    if (va == vb) continue;

    if (va is Map<String, dynamic>) {
      if (vb is! Map<String, dynamic> || !deeplEquals(va, vb)) return false;
    } else if (va is List) {
      if (vb is! List || !deepEqualsList(va, vb)) return false;
    } else {
      return false;
    }
  }
  return true;
}
