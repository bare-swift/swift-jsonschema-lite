# ``JSONSchemaLite``

JSON Schema 2020-12 subset (type / required / properties / items / enum / const) — Sendable, Foundation-free.

## Overview

`JSONSchemaLite` is a deliberately-narrowed validator for the six
keywords most consumers reach for first when validating JSON shapes:
`type`, `required`, `properties`, `items`, `enum`, `const`. Schema
documents are themselves `JSONValue`; validation walks the instance
in parallel with the schema, collecting one ``ValidationFailure`` per
violation.

```swift
import JSON
import JSONSchemaLite

let schema = try JSONSchema(#"""
{
  "type": "object",
  "required": ["name", "age"],
  "properties": {
    "name": {"type": "string"},
    "age":  {"type": "integer"}
  }
}
"""#)

let doc = try JSON.parse(#"{"name":"alice","age":30}"#)
switch schema.validate(doc) {
case .valid: print("ok")
case .invalid(let failures):
    for f in failures { print("\(f.path): \(f.message)") }
}
```

Out-of-scope keywords (numeric bounds, string format, `$ref`, custom
extensions) parse fine — they're simply not enforced. Schemas
relying on them validate as if those keywords were absent.

## Topics

### Essentials

- ``JSONSchema``
- ``ValidationResult``
- ``ValidationFailure``
- ``JSONSchemaError``
