import Foundation
/// `ExtendedJSONDecoder` facilitates the decoding of ExtendedJSON into `Decodable` values.
public class ExtendedJSONDecoder {
    internal static var extJSONDateFormatterSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    internal static var extJSONDateFormatterMilliseconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Initialize an `ExtendedJSONDecoder`.
    public init() {}

    /// Decodes an instance of the requested type `T` from the provided extended JSON data.
    /// - SeeAlso: https://docs.mongodb.com/manual/reference/mongodb-extended-json/
    ///
    /// - Parameters:
    ///   - type: Codable type to decode the input into.
    ///   - data: `Data` which represents the JSON that will be decoded.
    /// - Returns: Decoded representation of the JSON input as an instance of `T`.
    /// - Throws: `DecodingError` if the JSON data is corrupt or if any value throws an error during decoding.
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        // Data --> JSON --> BSON --> T
        // Takes in JSON as `Data` encoded with `.utf8` and runs it through a `JSONDecoder` to get an
        // instance of the `JSON` enum.
        let wrappedData = "[".utf8 + data + "]".utf8
        let json = try JSONDecoder().decode([JSON].self, from: wrappedData)[0]
        // Then a `BSON` enum instance is created via the `JSON`.
        let bson = try BSON(fromExtJSON: json, keyPath: [])
        // The `BSON` is then passed through a `BSONDecoder` where it is outputted as a `T`
        return try BSONDecoder().decode(T.self, fromBSON: bson)
    }
}
