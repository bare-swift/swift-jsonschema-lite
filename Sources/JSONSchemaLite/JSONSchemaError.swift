// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Errors thrown by `JSONSchema.init(_ source: String)`.
public enum JSONSchemaError: Error, Equatable, Sendable {
    /// Schema source could not be parsed as JSON.
    case malformedSchema(String)
}
