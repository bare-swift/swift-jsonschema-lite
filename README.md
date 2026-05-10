# swift-jsonschema-lite

JSON Schema 2020-12 subset (`type` / `required` / `properties` / `items` / `enum` / `const`) — Sendable, Foundation-free.

Part of the [bare-swift](https://github.com/bare-swift) ecosystem.

## Install

Add to your `Package.swift`:

```swift
.package(url: "https://github.com/bare-swift/swift-jsonschema-lite.git", from: "0.1.0")
```

Then depend on the `JSONSchemaLite` product:

```swift
.product(name: "JSONSchemaLite", package: "swift-jsonschema-lite")
```

## Usage

```swift
import JSON
import JSONSchemaLite

let schema = try JSONSchema(#"""
{
  "type": "object",
  "required": ["name", "age"],
  "properties": {
    "name": {"type": "string"},
    "age":  {"type": "integer"},
    "role": {"enum": ["admin", "editor", "viewer"]}
  }
}
"""#)

let doc = try JSON.parse(#"{"name":"alice","age":30,"role":"admin"}"#)
switch schema.validate(doc) {
case .valid:
    print("ok")
case .invalid(let failures):
    for f in failures {
        print("\(f.path): \(f.message)")
    }
}
```

## Scope

`swift-jsonschema-lite` v0.1 implements the six keywords RFC-0011 calls out:

- **`type`** — single string or array of strings (`string`, `number`, `integer`, `boolean`, `null`, `array`, `object`). Whole-number doubles satisfy `type=integer` per JSON Schema 2020-12.
- **`required`** — array of property names that must be present on object instances.
- **`properties`** — per-property sub-schemas applied to matching object members.
- **`items`** — sub-schema applied to every element of an array instance.
- **`enum`** — array of allowed values; instance must structurally match one. Numeric integer/double equivalence is honoured.
- **`const`** — single allowed value; instance must structurally match. Numeric integer/double equivalence is honoured.

Out-of-scope keywords (numeric bounds, string bounds, `$ref`, `format`, custom extensions) parse fine — they are simply not enforced.

Public API:

- `JSONSchema(_ document: JSONValue)` and `JSONSchema(_ source: String) throws(JSONSchemaError)` — build from a parsed value or from JSON text.
- `JSONSchema.validate(_ instance: JSONValue) -> ValidationResult` — check an instance against the schema.
- `ValidationResult` — `.valid` or `.invalid([ValidationFailure])`.
- `ValidationFailure` — carries the JSON Pointer path inside the *instance* (not the schema) where the violation was found, plus a human-readable message.

Out of scope for v0.1:

- Full JSON Schema 2020-12 (numeric bounds, string format, `$ref` resolution, custom keyword extensions, `additionalProperties` / `patternProperties` / `dependencies` / `if`-`then`-`else`, etc.). Pair with a full validator if you need them.
- Schema *meta*-validation. v0.1 trusts the schema document; malformed schemas may produce surprising results rather than throwing.
- `Codable` bridging — same Foundation-free / non-Codable differentiator.

## Dependencies

- `swift-json` 0.1.0 — `JSONValue` representation for both schema and instance.
- `swift-jsonpointer` 0.1.0 — RFC 6901 paths in `ValidationFailure`.

## Documentation

Full DocC documentation: <https://bare-swift.github.io/swift-jsonschema-lite/>

## Source

No upstream Rust crate; this is a native bare-swift package implementing a deliberately narrow subset of JSON Schema 2020-12.

## License

Apache 2.0 with LLVM exception. See [LICENSE](./LICENSE) and [NOTICE](./NOTICE).
