# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-05-10

### Added
- `JSONSchema` value type wrapping a raw `JSONValue` schema document.
- `JSONSchema(_ source: String) throws(JSONSchemaError)` — build from JSON text.
- `JSONSchema.validate(_ instance: JSONValue) -> ValidationResult` — check an instance against the schema, collecting one `ValidationFailure` per violation.
- `ValidationResult` enum (`.valid` / `.invalid([ValidationFailure])`) plus `.isValid` / `.failures` convenience accessors.
- `ValidationFailure` struct carrying an RFC 6901 `JSONPointer` (path inside the *instance*) and a human-readable message.
- Six supported keywords per RFC-0011's "lite" surface:
  - `type` — single string or array; recognises `null`, `boolean`, `integer`, `number`, `string`, `array`, `object`. Whole-number doubles satisfy `type=integer`.
  - `required` — required-property names on object instances.
  - `properties` — per-property sub-schemas applied to matching members.
  - `items` — sub-schema applied to every element of an array instance.
  - `enum` — array of allowed values; numeric integer/double equivalence honoured.
  - `const` — single allowed value; numeric integer/double equivalence honoured.
- Out-of-scope keywords (`minimum`, `maximum`, `pattern`, `format`, `$ref`, `additionalProperties`, etc.) parse fine — they are simply not enforced.
- 25 tests across 7 suites covering each keyword, mixed-type enums, nested `items` + `properties`, multiple-failure collection, OTLP-shaped end-to-end, and `enum`+`const` composition.

### Dependencies
- `swift-json` 0.1.0 — `JSONValue` for both schema and instance.
- `swift-jsonpointer` 0.1.0 — RFC 6901 paths in `ValidationFailure`.

### Limitations (out of scope for v0.1)
- Full JSON Schema 2020-12 (numeric bounds, string bounds / format, `$ref` resolution, `additionalProperties`, `patternProperties`, `if`/`then`/`else`, custom keyword extensions, etc.). Pair with a full validator if needed.
- Schema *meta*-validation. v0.1 trusts the schema document; malformed schemas may produce surprising results rather than throwing.
- `Codable` bridging — same Foundation-free / non-Codable differentiator as the rest of the format tier.
