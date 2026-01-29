// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// Shortcut for a JSON object
typedef Json = Map<String, dynamic>;

/// The example JSON document.
const exampleJson = exampleJsonNested0;

// .............................................................................
/// A complex JSON document combining various structures and types.
const exampleJsonNested0 = <String, dynamic>{
  'objectValue': <String, dynamic>{
    'nestedString': 'nested',
    'nestedNull': null,
    'nestedBoolean': true,
  },
  'arrayValue': [
    'text',
    123,
    45.6,
    true,
    false,
    null,
    <String, dynamic>{'deepKey': 'deepValue'},
    [
      1,
      2,
      3,
      {'innerKey': 'innerValue'},
    ],
  ],
  'numericVariants': <String, num>{
    'positive': 100,
    'negative': -50,
    'floating': 0.001,
    'scientific': 1.0e6,
  },
  'emptyObject': <String, dynamic>{},
  'emptyArray': <dynamic>[],
};

// .............................................................................
/// A JSON document demonstrating various primitive types.
const exampleJsonPrimitive = <String, dynamic>{
  'stringValue': 'Hello, World',
  'integerValue': 42,
  'doubleValue': 3.14159,
  'booleanTrue': true,
  'booleanFalse': false,
  'nullValue': null,
};

// .............................................................................
/// An example JSON document.
const exampleJsonNested1 = <String, dynamic>{
  'name': 'John Doe',
  'age': 30,
  'isEmployed': true,
  'address': {
    'street': '123 Main St',
    'city': 'Anytown',
    'postalCode': '12345',
  },
  'phoneNumbers': [
    {'type': 'home', 'number': '555-1234'},
    {'type': 'work', 'number': '555-5678'},
  ],
  'skills': ['Dart', 'Flutter', 'JSON'],
  'groups': [
    ['admin', 'user'],
    ['guest'],
  ],
  'projects': [
    {
      'name': 'Project A',
      'durationMonths': 6,
      'technologies': ['Dart', 'Firebase'],
    },
    {
      'name': 'Project B',
      'durationMonths': 12,
      'technologies': ['Flutter', 'GraphQL'],
    },
  ],
};
