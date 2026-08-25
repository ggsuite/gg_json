// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

// .............................................................................
/// Applies [patch] to [target] RFC-7386-style with per-field control:
///
/// - objects deep-merge (default), scalars replace
/// - `null` deletes the key
/// - `"key!"` replaces the value outright (no merge, `null` stays `null`)
/// - `"key+"` joins arrays (append, deduplicated)
/// - arrays without suffix replace
///
/// A non-map [patch] replaces [target] entirely. Returns the merged value
/// plus warnings (each prefixed with [context]).
({Object? value, List<String> warnings}) jsonMergePatch(
  Object? target,
  Object? patch, {
  required String context,
}) {
  final warnings = <String>[];
  final value = _merge(target, patch, context, warnings);
  return (value: value, warnings: warnings);
}

// .............................................................................
Object? _merge(
  Object? target,
  Object? patch,
  String context,
  List<String> warnings,
) {
  if (patch is! Map<String, dynamic>) return patch;

  final result = target is Map<String, dynamic>
      ? Map<String, dynamic>.of(target)
      : <String, dynamic>{};

  for (final entry in patch.entries) {
    final key = entry.key;
    final patchValue = entry.value;

    if (key.endsWith('+')) {
      final realKey = key.substring(0, key.length - 1);
      if (patchValue is! List) {
        warnings.add(
          '$context: "$key" expects an array to append — replaced instead.',
        );
        result[realKey] = patchValue;
        continue;
      }
      final existing = result[realKey];
      if (existing is! List) {
        warnings.add(
          '$context: "$key" targets a non-array — replaced instead.',
        );
        result[realKey] = patchValue;
        continue;
      }
      result[realKey] = joinArrays(existing, patchValue);
      continue;
    }

    if (key.endsWith('!')) {
      final realKey = key.substring(0, key.length - 1);
      result[realKey] = patchValue;
      continue;
    }

    if (patchValue == null) {
      result.remove(key);
      continue;
    }

    final existing = result[key];
    if (patchValue is Map<String, dynamic> &&
        existing is Map<String, dynamic>) {
      result[key] = _merge(existing, patchValue, '$context/$key', warnings);
      continue;
    }

    result[key] = patchValue;
  }
  return result;
}

// .............................................................................
/// Joins [base] and [addition]: entries of [addition] not already contained
/// in [base] (deep equality) are appended in order.
List<dynamic> joinArrays(List<dynamic> base, List<dynamic> addition) {
  final result = List<dynamic>.of(base);
  final seen = result.map(_deepKey).toSet();
  for (final item in addition) {
    final key = _deepKey(item);
    if (seen.contains(key)) continue;
    seen.add(key);
    result.add(item);
  }
  return result;
}

String _deepKey(Object? value) => jsonEncode(value);

// .............................................................................
/// Encodes [value] with two-space indent and a trailing newline. Map key
/// order is kept as-is (base keys first, patch-only keys appended by
/// [jsonMergePatch]).
String encodeJsonPretty(Object? value) =>
    '${const JsonEncoder.withIndent('  ').convert(value)}\n';
