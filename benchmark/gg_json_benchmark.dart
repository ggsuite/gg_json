// @license
// Copyright (c) 2026 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Benchmark suite for gg_json.
//
// Run with:
//   dart run benchmark/gg_json_benchmark.dart
//
// Prints one line per operation with the measured time per operation in
// nanoseconds. Lower is better.

import 'dart:convert';

import 'package:gg_json/gg_json.dart';
// ignore: implementation_imports
import 'package:gg_json/src/json_string.dart';

// .............................................................................
// Harness

final Map<String, double> results = <String, double>{};

/// Guards against dead-code elimination.
Object? sink;

void bench(String name, void Function() body) {
  // Warm up.
  for (var i = 0; i < 200; i++) {
    body();
  }

  // Calibrate the batch size so one batch takes >= 10ms.
  var batch = 1;
  final sw = Stopwatch();
  for (;;) {
    sw
      ..reset()
      ..start();
    for (var i = 0; i < batch; i++) {
      body();
    }
    sw.stop();
    if (sw.elapsedMicroseconds >= 10 * 1000) {
      break;
    }
    batch *= 2;
  }

  // Run for ~200ms and compute ns per operation.
  const targetMicros = 200 * 1000;
  final iterations = (batch * targetMicros / sw.elapsedMicroseconds).ceil();
  sw
    ..reset()
    ..start();
  for (var i = 0; i < iterations; i++) {
    body();
  }
  sw.stop();

  final nsPerOp = sw.elapsedMicroseconds * 1000 / iterations;
  results[name] = nsPerOp;
  print('${name.padRight(42)} ${nsPerOp.toStringAsFixed(1).padLeft(14)} ns/op');
}

// .............................................................................
// Test data

/// A nested map chain: a0/a1/.../a[depth-1] = 42.
Json deepChain(int depth) {
  final root = <String, dynamic>{};
  var node = root;
  for (var i = 0; i < depth - 1; i++) {
    final child = <String, dynamic>{};
    node['a$i'] = child;
    node = child;
  }
  node['a${depth - 1}'] = 42;
  return root;
}

/// The path into [deepChain].
String deepChainPath(int depth) => List.generate(depth, (i) => 'a$i').join('/');

/// A tree with the given [depth] and [fanOut]; leaves are ints.
Json tree(int depth, int fanOut) {
  if (depth == 0) {
    return <String, dynamic>{
      for (var i = 0; i < fanOut; i++) 'leaf$i': i,
      'list': List<dynamic>.generate(fanOut, (i) => i),
    };
  }
  return <String, dynamic>{
    for (var i = 0; i < fanOut; i++) 'child$i': tree(depth - 1, fanOut),
  };
}

// .............................................................................
void main() {
  final wide = <String, dynamic>{for (var i = 0; i < 100; i++) 'k$i': i};
  final deep10 = deepChain(10);
  final deep10Path = deepChainPath(10);
  final deep100 = deepChain(100);
  final deep1000 = deepChain(1000);
  final deep5000 = deepChain(5000);
  final bigTree = tree(5, 4); // 4^5 = 1024 internal maps
  final bigTreeCopy = deepCopy(bigTree);
  final arrayDoc = <String, dynamic>{
    'matrix': List<dynamic>.generate(
      10,
      (i) => List<dynamic>.generate(10, (j) => i * 10 + j),
    ),
    'items': List<dynamic>.generate(10, (i) => <String, dynamic>{'x': i}),
  };
  final smallJsonString = jsonEncode(exampleJsonNested1);

  // Path parsing
  bench('parseJsonPath (10 segments)', () {
    sink = parseJsonPath(deep10Path);
  });
  bench('parseArrayIndex ("a[3][4]")', () {
    sink = parseArrayIndex('a[3][4]');
  });

  // get
  bench('get shallow ("k50")', () {
    sink = wide.get<int>('k50');
  });
  bench('get deep (10 segments)', () {
    sink = deep10.get<int>(deep10Path);
  });
  bench('get array ("matrix[3][4]")', () {
    sink = arrayDoc.get<int>('matrix[3][4]');
  });
  bench('get map in array ("items[5]/x")', () {
    sink = arrayDoc.get<int>('items[5]/x');
  });
  bench('getOrNull missing ("nope/nope")', () {
    sink = wide.getOrNull<int>('nope/nope');
  });

  // set
  bench('set shallow ("k50")', () {
    wide.set<int>('k50', 1);
  });
  bench('set deep (10 segments)', () {
    deep10.set<int>(deep10Path, 1);
  });
  bench('set array ("matrix[3][4]")', () {
    arrayDoc.set<int>('matrix[3][4]', 1);
  });
  bench('set deep extend (10 segments)', () {
    deep10.set<int>(deep10Path, 1, extend: true);
  });

  // remove + re-add cycle
  bench('remove+set cycle ("k50")', () {
    wide.removeValue('k50');
    wide.set<int>('k50', 50, extend: true);
  });

  // ls
  bench('ls big tree (1k maps)', () {
    sink = bigTree.ls();
  });
  bench('ls big tree writeValues', () {
    sink = bigTree.ls(writeValues: true);
  });

  // visit
  bench('visit deep chain (depth 100)', () {
    deep100.visit((key, value, parent, ancestors) {});
  });
  bench('visit big tree (1k maps)', () {
    bigTree.visit((key, value, parent, ancestors) {});
  });
  bench('visit deep chain (depth 1000)', () {
    deep1000.visit((key, value, parent, ancestors) {});
  });
  bench('visit deep chain (depth 5000)', () {
    deep5000.visit((key, value, parent, ancestors) {});
  });

  // deepCopy / deepEquals
  bench('deepCopy big tree (1k maps)', () {
    sink = deepCopy(bigTree);
  });
  bench('deepEquals big tree (1k maps)', () {
    sink = deeplEquals(bigTree, bigTreeCopy);
  });

  // JSON string API
  bench('jsonStringGetOrNull small doc', () {
    sink = jsonStringGetOrNull<String>(smallJsonString, path: 'address/city');
  });
  bench('jsonStringSet small doc', () {
    sink = jsonStringSet<String>(
      smallJsonString,
      path: 'address/city',
      value: 'Berlin',
    );
  });

  // Machine-readable summary for before/after comparison.
  print('');
  print('JSON_RESULTS:${jsonEncode(results)}');
}
