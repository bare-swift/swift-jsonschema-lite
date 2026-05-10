// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import JSONPointer

/// Outcome of ``JSONSchema/validate(_:)``.
public enum ValidationResult: Sendable, Equatable {
    case valid
    case invalid([ValidationFailure])

    /// `true` if the instance satisfied every supported schema keyword.
    public var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    /// All violations, or an empty array if the instance was valid.
    public var failures: [ValidationFailure] {
        if case .invalid(let f) = self { return f }
        return []
    }
}

/// One detected schema-keyword violation. `path` is an RFC 6901 pointer
/// into the *instance* (not the schema) where the violation was found.
public struct ValidationFailure: Sendable, Equatable {
    /// Path inside the instance that violated the schema (root is `""`).
    public let path: JSONPointer

    /// Human-readable explanation. Stable enough for logging; not parsed
    /// programmatically.
    public let message: String

    public init(path: JSONPointer, message: String) {
        self.path = path
        self.message = message
    }
}
