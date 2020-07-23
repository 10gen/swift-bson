import Foundation

/// Enum representing a JSON value, used internally for modeling JSON
/// during extendedJSON parsing/generation.
internal enum JSON: Codable {
    case number(Double)
    case string(String)
    case bool(Bool)
    indirect case array([JSON])
    indirect case object([String: JSON])
    case null

    /// Initialize a `JSON` from a decoder.
    /// Tries to decode into each of the JSON types one by one until one succeeds or
    /// throws an error indicating that the input is not a valid `JSON` type.
    internal init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let d = try? container.decode(Double.self) {
            self = .number(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let a = try? container.decode([JSON].self) {
            self = .array(a)
        } else if let d = try? container.decode([String: JSON].self) {
            self = .object(d)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Not a valid JSON type"
                ))
        }
    }

    /// Encode a `JSON` to a container by encoding the type of this `JSON` instance.
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .number(n):
            try container.encode(n)
        case let .string(s):
            try container.encode(s)
        case let .bool(b):
            try container.encode(b)
        case let .array(a):
            try container.encode(a)
        case let .object(o):
            try container.encode(o)
        case .null:
            try container.encodeNil()
        }
    }
}

extension JSON: ExpressibleByFloatLiteral {
    internal init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension JSON: ExpressibleByIntegerLiteral {
    internal init(integerLiteral value: Int) {
        // The number `JSON` type is a Double, so we cast any integers to doubles.
        self = .number(Double(value))
    }
}

extension JSON: ExpressibleByStringLiteral {
    internal init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JSON: ExpressibleByBooleanLiteral {
    internal init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension JSON: ExpressibleByArrayLiteral {
    internal init(arrayLiteral elements: JSON...) {
        self = .array(elements)
    }
}

extension JSON: ExpressibleByDictionaryLiteral {
    internal init(dictionaryLiteral elements: (String, JSON)...) {
        self = .object([String: JSON](uniqueKeysWithValues: elements))
    }
}

/// Value Getters
extension JSON {
    /// If this `JSON` is a `.double`, return it as a `Double`. Otherwise, return nil.
    internal var doubleValue: Double? {
        guard case let .number(n) = self else {
            return nil
        }
        return n
    }

    /// If this `JSON` is a `.string`, return it as a `String`. Otherwise, return nil.
    internal var stringValue: String? {
        guard case let .string(s) = self else {
            return nil
        }
        return s
    }

    /// If this `JSON` is a `.bool`, return it as a `Bool`. Otherwise, return nil.
    internal var boolValue: Bool? {
        guard case let .bool(b) = self else {
            return nil
        }
        return b
    }

    /// If this `JSON` is a `.array`, return it as a `[JSON]`. Otherwise, return nil.
    internal var arrayValue: [JSON]? {
        guard case let .array(a) = self else {
            return nil
        }
        return a
    }

    /// If this `JSON` is a `.object`, return it as a `[String: JSON]`. Otherwise, return nil.
    internal var objectValue: [String: JSON]? {
        guard case let .object(o) = self else {
            return nil
        }
        return o
    }
}

/// Helpers
extension JSON {
    /// Helper function used in `BSONValue` initializers that take in extended JSON and need to
    /// check that an object has only 1 specified key.
    ///
    /// - Parameters:
    ///   - key: a String representing the one key that the initializer is looking for
    ///   - `keyPath`: an array of `String`s containing the enclosing JSON keys of the current json being passed in.
    ///                This is used for error messages.
    /// - Returns:
    ///    - a tuple containing:
    ///        - a JSON which is the value at the given `key` in `self`
    ///        - the object itself (with the expected key and its value)
    ///    - or `nil` if `self` is not an `object` or does not contain the given `key`
    ///
    /// - Throws: `DecodingError` if `self` has too many keys
    internal func isObjectWithSingleKey(key: String, keyPath: [String]) throws -> (value: JSON, obj: [String: JSON])? {
        guard case let .object(obj) = self else {
            return nil
        }
        guard let value = obj[key] else {
            return nil
        }
        guard obj.count == 1 else {
            throw DecodingError._extendedJSONError(
                keyPath: keyPath,
                debugDescription: "Expected only \"\(key)\", found too many keys: \(obj.keys)"
            )
        }
        return (value, obj)
    }
}

extension JSON: Equatable {}
