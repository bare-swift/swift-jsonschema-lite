// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import JSON
import JSONPointer

/// Sendable, Foundation-free **subset** of JSON Schema 2020-12 validation.
///
/// Per [RFC-0011](https://github.com/bare-swift/bare-swift/blob/main/rfcs/0011-phase-6-anchor-json-tier.md)
/// the "lite" surface intentionally narrows the spec to the six keywords
/// most consumers reach for first:
///
/// - `type` — single string or array of strings (`"string"`, `"number"`,
///   `"integer"`, `"boolean"`, `"null"`, `"array"`, `"object"`)
/// - `required` — array of property names that must be present
/// - `properties` — per-property sub-schemas
/// - `items` — sub-schema applied to every array element
/// - `enum` — array of allowed values (instance must match one)
/// - `const` — single allowed value (instance must equal it)
///
/// Out of scope: full validator, `$ref` resolution, the `format` keyword,
/// numeric bounds (`minimum`/`maximum`), string bounds, custom keyword
/// extensions. Schemas using out-of-scope keywords parse fine — those
/// keywords are simply not enforced.
///
/// ```swift
/// import JSON
/// import JSONSchemaLite
///
/// let schema = try JSONSchema(#"""
/// {
///   "type": "object",
///   "required": ["name", "age"],
///   "properties": {
///     "name": {"type": "string"},
///     "age":  {"type": "integer"}
///   }
/// }
/// """#)
///
/// let doc = try JSON.parse(#"{"name":"alice","age":30}"#)
/// switch schema.validate(doc) {
/// case .valid: print("ok")
/// case .invalid(let failures): print("invalid: \(failures)")
/// }
/// ```
public struct JSONSchema: Sendable, Equatable {
    /// The raw schema document. Held verbatim so consumers can introspect
    /// keywords v0.1 doesn't enforce.
    public let document: JSONValue

    public init(_ document: JSONValue) {
        self.document = document
    }

    /// Build a schema from a JSON-text document.
    public init(_ source: String) throws(JSONSchemaError) {
        do {
            self.document = try JSON.parse(source)
        } catch {
            throw .malformedSchema("\(error)")
        }
    }

    /// Validate a JSON instance against this schema. Returns `.valid` if
    /// every supported keyword is satisfied, otherwise `.invalid([...])`
    /// with one ``ValidationFailure`` per detected violation (in document
    /// order).
    public func validate(_ instance: JSONValue) -> ValidationResult {
        var failures: [ValidationFailure] = []
        Validator.validate(schema: document, instance: instance,
                           path: JSONPointer(tokens: []),
                           failures: &failures)
        return failures.isEmpty ? .valid : .invalid(failures)
    }
}
