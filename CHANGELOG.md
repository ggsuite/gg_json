# Changelog

## Unreleased

### Fixed

- Cleanup copy right headers. Update to dart 3.13. Auto fixes.
- Cleanup copy right headers. Update to dart 3.13. Auto fixes. Setup quick-check pipeline.

## 4.0.1 - 2026-07-06

## 4.0.0 - 2026-07-06

### Breaking changes

- `VisitProp` uses positional parameters now: migrate
`json.visit(({key, value, parent, ancestors}) {...})` to
`json.visit((key, value, parent, ancestors) {...})`
- `visit`'s `ancestors` argument is a live, read-only view that is only valid
during the callback; copy it with `List.of(ancestors)` if you retain it
- Path strings are validated eagerly when first compiled: an invalid segment
anywhere in a path throws `Invalid path segment ...` even if the walk would
previously have failed earlier with a missing-path error or returned null

### Changed

- Major performance rewrite across the whole package
- `set`/`get`/`getOrNull`/`removeValue`: paths are compiled once and cached
per isolate; traversal is a tight, allocation-free loop
(2.6–4.5x faster)
- `visit`: the quadratic per-node ancestors allocation is gone; one reused
ancestor stack per traversal (26x faster at depth 1000, ~400x at
depth 5000)
- `ls`: shared path buffer instead of per-node string interpolation
(~3x faster)
- `deepCopy`: bulk map cloning with nested patching (~2x faster)
- `deeplEquals`: lockstep iteration without per-entry allocation
(~20% faster)
- Added `JsonPathSegment` and `compileJsonPath` for pre-compiled paths
- Added a benchmark suite under `benchmark/`
- BREAKING CHANGE: Performance optimization by claude

## 3.2.0 - 2026-07-05

### Changed

- Optimize performance using claude

## 3.1.2 - 2026-07-05

### Changed

- Improve performance: path parsing without regular expressions,
allocation-free path traversal in set/get, faster ls and deepEquals

## 3.1.1 - 2026-05-20

### Changed

- Allow JSON modification while visiting

## 3.1.0 - 2026-05-20

### Added

- Add visit method

## 3.0.20 - 2026-03-07

### Changed

- Don't throw on non letters oder numbers in JSON key

## 3.0.19 - 2026-03-06

### Changed

- Allow to print also complex values

## 3.0.18 - 2026-03-06

### Fixed

- Fix: Tags were added multiple times

## 3.0.17 - 2026-03-06

### Added

- Add JsonTags.manage to specify tags for a given JSON structure

## 3.0.16 - 2026-03-06

### Changed

- Rename JsonTags.tags methods

## 3.0.15 - 2026-03-06

### Added

- Add JsonTags

## 3.0.14 - 2026-03-03

### Added

- Add whereProp to filter for properties

## 3.0.13 - 2026-03-03

### Changed

- Make int - double type checks more robust

## 3.0.12 - 2026-02-23

### Changed

- DeepCopy: Add ignoreNonJsonObjects option

## 3.0.11 - 2026-02-23

### Added

- Add deepCopy(where)

## 3.0.10 - 2026-02-19

### Changed

- DeepCopy: Set throwOnNonJsonObjects to false

## 3.0.9 - 2026-02-19

### Added

- Add throwOnNonJsonObjects

## 3.0.8 - 2026-02-19

### Added

- Add json.deepCopy() extension method

## 3.0.7 - 2026-02-04

### Changed

- kidney: changed references to git

### Removed

- Remove possibility to use . as separator. Add leading ./ to paths

## 3.0.6 - 2026-02-02

### Changed

- Simplify examples

## 3.0.5 - 2026-01-30

### Changed

- Print paths when wrong path is given
- Print all paths when a path is not found

## 3.0.4 - 2026-01-30

### Added

- Add isValidJsonKey
- Add ls() methods, add DirectJson()
- Add array manipulation methods

### Changed

- Split DirectJson into various other methods

## 3.0.3 - 2026-01-29

### Added

- Add more examples

## 3.0.2 - 2026-01-29

### Removed

- Remove dependencies

## 3.0.1 - 2026-01-29

### Changed

- Update README.md

## 3.0.0 - 2026-01-29

### Added

- Start new implementation of the package
- Add `DeepCopy(json)`
- Add deepCopy, deepEquals and isJson and json
