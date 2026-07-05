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

  for (final entry in a.entries) {
    final key = entry.key;
    final va = entry.value;
    final vb = b[key];

    // Only pay for containsKey when the lookup was ambiguous (null value).
    if (vb == null && !b.containsKey(key)) return false;

    if (va is Map<String, dynamic> && vb is Map<String, dynamic>) {
      if (!deeplEquals(va, vb)) return false;
    } else if (va is List && vb is List) {
      if (!deepEqualsList(va, vb)) return false;
    } else {
      if (va != vb) return false;
    }
  }

  return true;
}

// ...........................................................................
/// Returns true if JSON Lists are deeply equal
bool deepEqualsList(List<dynamic> la, List<dynamic> lb) {
  if (identical(la, lb)) return true;
  if (la.length != lb.length) return false;
  for (var i = 0; i < la.length; i++) {
    final va = la[i];
    final vb = lb[i];
    if (va is Map<String, dynamic> && vb is Map<String, dynamic>) {
      if (!deeplEquals(va, vb)) return false;
    } else if (va is List && vb is List) {
      if (!deepEqualsList(va, vb)) return false;
    } else {
      if (va != vb) return false;
    }
  }
  return true;
}
