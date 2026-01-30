// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// Returns true if the given [input] string is a valid Dart identifier.
bool isValidJsonKey(String input) {
  final identifierRegExp = RegExp(r'^(?:[A-Za-z_$][A-Za-z0-9_$]*)$');
  return identifierRegExp.hasMatch(input);
}

/// Throws an [ArgumentError] if the given [key] is not a valid Dart identifier.
void throwIfNotValidJsonKey(String key) {
  if (!isValidJsonKey(key)) {
    throw Exception('$key is not a valid json identifier');
  }
}
