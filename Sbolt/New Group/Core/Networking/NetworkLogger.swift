//
//  NetworkLogger.swift
//  Yalla Go
//

#if DEBUG
import Foundation

/// Logs HTTP traffic to the console in DEBUG builds only.
/// The entire type is compiled out in Release — zero runtime overhead.
enum NetworkLogger {

    static func logRequest(_ request: URLRequest) {
        var lines = ["\n▶ REQUEST"]
        lines.append("\(request.httpMethod ?? "?")  \(request.url?.absoluteString ?? "nil")")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            lines.append("Headers: \(headers)")
        }
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8),
           !bodyString.isEmpty {
            lines.append("Body: \(bodyString)")
        }
        print(lines.joined(separator: "\n"))
    }

    static func logResponse(
        _ response: HTTPURLResponse,
        data: Data,
        duration: TimeInterval
    ) {
        let ms = String(format: "%.0f", duration * 1_000)
        var lines = ["\n◀ RESPONSE"]
        lines.append("\(response.statusCode)  \(response.url?.absoluteString ?? "nil")  [\(ms)ms]")
        if let body = String(data: data, encoding: .utf8), !body.isEmpty {
            let preview = body.count > 500 ? String(body.prefix(500)) + "…" : body
            lines.append("Body: \(preview)")
        }
        print(lines.joined(separator: "\n"))
    }
}
#endif
