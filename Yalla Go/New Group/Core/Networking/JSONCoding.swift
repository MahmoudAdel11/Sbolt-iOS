//
//  JSONCoding.swift
//  Yalla Go
//

import Foundation

extension JSONDecoder {
    /// Pre-configured decoder for all Yalla Go backend responses.
    /// - Key strategy: `convertFromSnakeCase` — `user_name` → `userName`
    /// - Date strategy: ISO 8601 with fractional seconds support
    static let backend: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            if let date = ISO8601DateFormatter.backend.date(from: string) { return date }
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Expected ISO 8601 date, got: \(string)")
            )
        }
        return decoder
    }()
}

extension JSONEncoder {
    /// Pre-configured encoder for all Yalla Go backend request bodies.
    /// - Key strategy: `convertToSnakeCase` — `userName` → `user_name`
    /// - Date strategy: ISO 8601 with fractional seconds
    static let backend: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(ISO8601DateFormatter.backend.string(from: date))
        }
        return encoder
    }()
}

// MARK: - Shared ISO 8601 formatter

private extension ISO8601DateFormatter {
    /// Handles both `2024-01-15T10:30:00Z` and `2024-01-15T10:30:00.000Z`.
    static let backend: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
