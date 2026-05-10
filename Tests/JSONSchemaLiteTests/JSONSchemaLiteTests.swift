// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import JSONSchemaLite
import JSON

private func schema(_ s: String) throws -> JSONSchema { try JSONSchema(s) }
private func parse(_ s: String) throws -> JSONValue { try JSON.parse(s) }
private func validate(_ schemaText: String, _ instanceText: String) throws -> ValidationResult {
    try schema(schemaText).validate(parse(instanceText))
}

@Suite("type keyword")
struct TypeTests {
    @Test("string matches string")
    func stringOK() throws {
        let r = try validate(#"{"type":"string"}"#, #""hello""#)
        #expect(r.isValid)
    }

    @Test("string vs integer fails")
    func stringVsInt() throws {
        let r = try validate(#"{"type":"string"}"#, "42")
        if case .invalid(let f) = r {
            #expect(f.count == 1)
            #expect(f[0].message.contains("type mismatch"))
        } else { Issue.record() }
    }

    @Test("integer matches integer (Int64-shaped)")
    func integerOK() throws {
        #expect(try validate(#"{"type":"integer"}"#, "42").isValid)
    }

    @Test("integer matches a whole-number double")
    func integerFromWholeDouble() throws {
        // JSON Schema 2020-12: 1.0 satisfies type=integer.
        #expect(try validate(#"{"type":"integer"}"#, "1.0").isValid)
    }

    @Test("integer rejects fractional double")
    func integerRejectsFractional() throws {
        let r = try validate(#"{"type":"integer"}"#, "1.5")
        #expect(!r.isValid)
    }

    @Test("number accepts both forms")
    func numberAcceptsBoth() throws {
        #expect(try validate(#"{"type":"number"}"#, "42").isValid)
        #expect(try validate(#"{"type":"number"}"#, "1.5").isValid)
    }

    @Test("type as array — any-match")
    func typeAsArray() throws {
        let s = #"{"type":["string","null"]}"#
        #expect(try validate(s, #""x""#).isValid)
        #expect(try validate(s, "null").isValid)
        #expect(!(try validate(s, "42").isValid))
    }

    @Test("null / boolean / array / object recognised")
    func remainingTypes() throws {
        #expect(try validate(#"{"type":"null"}"#, "null").isValid)
        #expect(try validate(#"{"type":"boolean"}"#, "true").isValid)
        #expect(try validate(#"{"type":"array"}"#, "[]").isValid)
        #expect(try validate(#"{"type":"object"}"#, "{}").isValid)
    }
}

@Suite("const keyword")
struct ConstTests {
    @Test("const matches exactly")
    func match() throws {
        #expect(try validate(#"{"const":42}"#, "42").isValid)
        #expect(try validate(#"{"const":"alice"}"#, #""alice""#).isValid)
    }

    @Test("const fails for differing value")
    func mismatch() throws {
        #expect(!(try validate(#"{"const":42}"#, "43").isValid))
    }

    @Test("const treats integer 1 and double 1.0 as equal")
    func constNumericEquality() throws {
        #expect(try validate(#"{"const":1}"#, "1.0").isValid)
        #expect(try validate(#"{"const":1.0}"#, "1").isValid)
    }
}

@Suite("enum keyword")
struct EnumTests {
    @Test("enum membership")
    func membership() throws {
        let s = #"{"enum":["red","green","blue"]}"#
        #expect(try validate(s, #""red""#).isValid)
        #expect(try validate(s, #""green""#).isValid)
        #expect(!(try validate(s, #""purple""#).isValid))
    }

    @Test("enum with mixed types")
    func mixedTypes() throws {
        let s = #"{"enum":[1,"two",null,true]}"#
        #expect(try validate(s, "1").isValid)
        #expect(try validate(s, #""two""#).isValid)
        #expect(try validate(s, "null").isValid)
        #expect(try validate(s, "true").isValid)
        #expect(!(try validate(s, "false").isValid))
    }
}

@Suite("required + properties")
struct ObjectTests {
    static let userSchema = #"""
    {
      "type": "object",
      "required": ["name", "age"],
      "properties": {
        "name": {"type": "string"},
        "age":  {"type": "integer"},
        "email":{"type": "string"}
      }
    }
    """#

    @Test("valid user")
    func validUser() throws {
        let r = try validate(Self.userSchema, #"{"name":"alice","age":30,"email":"a@b"}"#)
        #expect(r.isValid)
    }

    @Test("missing required property reported")
    func missingRequired() throws {
        let r = try validate(Self.userSchema, #"{"name":"alice"}"#)
        if case .invalid(let f) = r {
            #expect(f.contains { $0.message.contains("missing required property: age") })
        } else { Issue.record() }
    }

    @Test("type-violating property reported with path")
    func wrongPropertyType() throws {
        let r = try validate(Self.userSchema, #"{"name":"alice","age":"thirty"}"#)
        if case .invalid(let f) = r {
            #expect(f.contains { $0.path.description == "/age" && $0.message.contains("type mismatch") })
        } else { Issue.record() }
    }

    @Test("extra properties allowed (no additionalProperties keyword in v0.1)")
    func extraPropertiesAllowed() throws {
        let r = try validate(Self.userSchema, #"{"name":"alice","age":30,"extra":"ok"}"#)
        #expect(r.isValid)
    }

    @Test("multiple required failures collected")
    func multipleFailures() throws {
        let r = try validate(Self.userSchema, "{}")
        if case .invalid(let f) = r {
            #expect(f.count == 2)  // both name and age missing
        } else { Issue.record() }
    }
}

@Suite("items keyword")
struct ItemsTests {
    @Test("items applies to every element")
    func appliesToAll() throws {
        let s = #"{"type":"array","items":{"type":"integer"}}"#
        #expect(try validate(s, "[1, 2, 3]").isValid)
        let r = try validate(s, #"[1, "two", 3]"#)
        if case .invalid(let f) = r {
            #expect(f[0].path.description == "/1")
        } else { Issue.record() }
    }

    @Test("nested items + properties")
    func nested() throws {
        let s = #"""
        {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["id"],
            "properties": {"id": {"type": "integer"}}
          }
        }
        """#
        #expect(try validate(s, #"[{"id":1},{"id":2}]"#).isValid)
        let r = try validate(s, #"[{"id":1},{}]"#)
        if case .invalid(let f) = r {
            #expect(f[0].path.description == "/1")
        } else { Issue.record() }
    }
}

@Suite("Schema parsing edge cases")
struct ParseTests {
    @Test("non-object schemas accepted (no constraint)")
    func nonObjectSchema() throws {
        // RFC-0011 narrows v0.1 to schema-objects; non-object schemas
        // accept any instance (no keywords to enforce).
        let s = "true"
        #expect(try validate(s, "42").isValid)
    }

    @Test("unknown keywords ignored")
    func unknownKeywords() throws {
        // `minimum` is out of scope for v0.1; no error, no enforcement.
        let s = #"{"type":"integer","minimum":10}"#
        #expect(try validate(s, "5").isValid)  // would fail under full spec
    }

    @Test("malformed JSON throws .malformedSchema")
    func malformedJSON() {
        #expect(throws: (any Error).self) {
            try schema(#"{"type":"#)
        }
    }
}

@Suite("End-to-end — realistic shapes")
struct EndToEndTests {
    @Test("OTLP-ish log envelope")
    func otlpLike() throws {
        let s = #"""
        {
          "type": "object",
          "required": ["resourceLogs"],
          "properties": {
            "resourceLogs": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["resource", "scopeLogs"],
                "properties": {
                  "resource": {"type": "object"},
                  "scopeLogs": {"type": "array"}
                }
              }
            }
          }
        }
        """#

        let valid = #"""
        {"resourceLogs":[{"resource":{},"scopeLogs":[]}]}
        """#
        #expect(try validate(s, valid).isValid)

        let invalid = #"""
        {"resourceLogs":[{"resource":[]}]}
        """#
        let r = try validate(s, invalid)
        if case .invalid(let f) = r {
            #expect(f.contains { $0.path.description == "/resourceLogs/0/resource" })
            #expect(f.contains { $0.message.contains("missing required property: scopeLogs") })
        } else { Issue.record() }
    }

    @Test("enum + const compose")
    func enumPlusConst() throws {
        let s = #"""
        {
          "type": "object",
          "properties": {
            "kind": {"const": "user"},
            "role": {"enum": ["admin","editor","viewer"]}
          }
        }
        """#
        #expect(try validate(s, #"{"kind":"user","role":"admin"}"#).isValid)
        #expect(!(try validate(s, #"{"kind":"bot","role":"admin"}"#).isValid))
        #expect(!(try validate(s, #"{"kind":"user","role":"hacker"}"#).isValid))
    }
}
