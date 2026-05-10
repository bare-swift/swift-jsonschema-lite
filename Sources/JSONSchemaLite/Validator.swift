// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import JSON
import JSONPointer

/// JSON Schema lite validator. Walks an instance against a schema,
/// collecting failures for each unsatisfied keyword. Out-of-scope
/// keywords (numeric bounds, string format, `$ref`, etc.) are ignored —
/// their presence in a schema document is not an error.
enum Validator {
    static func validate(
        schema: JSONValue,
        instance: JSONValue,
        path: JSONPointer,
        failures: inout [ValidationFailure]
    ) {
        // A `true` schema would conventionally accept any instance, and
        // `false` would reject — RFC-0011 keeps v0.1 narrow and only
        // recognises schema *objects*. Non-object schemas are accepted
        // (no keywords to enforce).
        guard case .object(let keywords) = schema else { return }

        // type
        if let typeValue = keywords.first(where: { $0.key == "type" })?.value {
            if !checkType(typeValue, instance: instance) {
                failures.append(ValidationFailure(
                    path: path,
                    message: "type mismatch: expected \(formatTypeKeyword(typeValue)), got \(typeName(instance))"
                ))
            }
        }

        // const
        if let constValue = keywords.first(where: { $0.key == "const" })?.value {
            if !valuesEqual(instance, constValue) {
                failures.append(ValidationFailure(
                    path: path,
                    message: "const violation: expected exact match"
                ))
            }
        }

        // enum
        if let enumValue = keywords.first(where: { $0.key == "enum" })?.value,
           case .array(let allowed) = enumValue {
            if !allowed.contains(where: { valuesEqual($0, instance) }) {
                failures.append(ValidationFailure(
                    path: path,
                    message: "enum violation: value not in allowed list"
                ))
            }
        }

        // required
        if let required = keywords.first(where: { $0.key == "required" })?.value,
           case .array(let names) = required,
           case .object(let members) = instance {
            for name in names {
                guard case .string(let key) = name else { continue }
                if !members.contains(where: { $0.key == key }) {
                    failures.append(ValidationFailure(
                        path: path,
                        message: "missing required property: \(key)"
                    ))
                }
            }
        }

        // properties
        if let properties = keywords.first(where: { $0.key == "properties" })?.value,
           case .object(let propSchemas) = properties,
           case .object(let members) = instance {
            for prop in propSchemas {
                guard let instanceMember = members.first(where: { $0.key == prop.key }) else {
                    continue
                }
                let childPath = JSONPointer(tokens: path.tokens + [JSONPointer.Token(prop.key)])
                validate(schema: prop.value, instance: instanceMember.value, path: childPath, failures: &failures)
            }
        }

        // items
        if let items = keywords.first(where: { $0.key == "items" })?.value,
           case .array(let elements) = instance {
            for (index, element) in elements.enumerated() {
                let childPath = JSONPointer(tokens: path.tokens + [JSONPointer.Token(integerLiteral: index)])
                validate(schema: items, instance: element, path: childPath, failures: &failures)
            }
        }
    }

    // MARK: - type

    /// Check `instance` against a `type` keyword. Per draft 2020-12, the
    /// keyword's value may be a string OR an array of strings (any-match).
    static func checkType(_ typeValue: JSONValue, instance: JSONValue) -> Bool {
        switch typeValue {
        case .string(let name):
            return matchesType(instance, name: name)
        case .array(let names):
            for n in names {
                if case .string(let name) = n, matchesType(instance, name: name) {
                    return true
                }
            }
            return false
        default:
            // Schema is malformed; v0.1 treats it as "no constraint".
            return true
        }
    }

    static func matchesType(_ instance: JSONValue, name: String) -> Bool {
        switch (instance, name) {
        case (.null, "null"): return true
        case (.bool, "boolean"): return true
        case (.string, "string"): return true
        case (.array, "array"): return true
        case (.object, "object"): return true
        case (.integer, "integer"): return true
        case (.integer, "number"): return true
        // JSON Schema 2020-12: a double with no fractional part counts as
        // integer (the wire form differs but the value is integral).
        case (.double(let d), "integer"): return d.truncatingRemainder(dividingBy: 1) == 0 && d.isFinite
        case (.double, "number"): return true
        default: return false
        }
    }

    static func typeName(_ value: JSONValue) -> String {
        switch value {
        case .null: return "null"
        case .bool: return "boolean"
        case .integer: return "integer"
        case .double: return "number"
        case .string: return "string"
        case .array: return "array"
        case .object: return "object"
        }
    }

    static func formatTypeKeyword(_ keyword: JSONValue) -> String {
        switch keyword {
        case .string(let s): return s
        case .array(let xs):
            return "[" + xs.map { (v) -> String in
                if case .string(let s) = v { return s }
                return "?"
            }.joined(separator: ", ") + "]"
        default: return "?"
        }
    }

    // MARK: - equality

    /// JSON Schema equality: structural, with numeric integers and doubles
    /// equal when they hold the same number. (Matches `JSONValue`'s
    /// equality except that `.integer(1)` and `.double(1.0)` compare
    /// equal here even though the wire forms differ.)
    static func valuesEqual(_ a: JSONValue, _ b: JSONValue) -> Bool {
        switch (a, b) {
        case (.integer(let x), .double(let y)): return Double(x) == y
        case (.double(let x), .integer(let y)): return x == Double(y)
        default: return a == b
        }
    }
}
