//
//  APIClientTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Sbolt

// Serialized to prevent parallel tests from racing over the shared static handler.
@Suite(.serialized)
struct APIClientTests {

    private let baseURL = URL(string: "https://api.test.com")!

    private func makeSUT() -> URLSessionAPIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSessionAPIClient(baseURL: baseURL, session: URLSession(configuration: config))
    }

    // MARK: - Successful decoding

    @Test func decodesValidJSONResponse() async throws {
        defer { MockURLProtocol.requestHandler = nil }
        let payload = #"{"value":42}"#.data(using: .utf8)!
        let url = baseURL
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, payload)
        }

        struct Box: Decodable { let value: Int }
        let result: Box = try await makeSUT().send(Endpoint(path: "/test", method: .get))
        #expect(result.value == 42)
    }

    // MARK: - Status-code mapping

    @Test func throws401AsUnauthorized() async {
        defer { MockURLProtocol.requestHandler = nil }
        let url = baseURL
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)!, Data())
        }
        await #expect(throws: NetworkError.unauthorized) {
            let _: Stub = try await makeSUT().send(Endpoint(path: "/secure", method: .get))
        }
    }

    @Test func throws404AsNotFound() async {
        defer { MockURLProtocol.requestHandler = nil }
        let url = baseURL
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!, Data())
        }
        await #expect(throws: NetworkError.notFound) {
            let _: Stub = try await makeSUT().send(Endpoint(path: "/missing", method: .get))
        }
    }

    @Test func throws409WithDecodedErrorCode() async {
        defer { MockURLProtocol.requestHandler = nil }
        let body = #"{"error_code":"ride_cancelled","message":"This ride was cancelled by the rider."}"#
            .data(using: .utf8)!
        let url = baseURL
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: url, statusCode: 409, httpVersion: nil, headerFields: nil)!, body)
        }
        await #expect(throws: NetworkError.conflict(errorCode: "ride_cancelled")) {
            let _: Stub = try await makeSUT().send(Endpoint(path: "/rides/1/accept", method: .post))
        }
    }

    @Test func throws409WithUndecodableBodyAsNilErrorCode() async {
        defer { MockURLProtocol.requestHandler = nil }
        let url = baseURL
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: url, statusCode: 409, httpVersion: nil, headerFields: nil)!, Data())
        }
        await #expect(throws: NetworkError.conflict(errorCode: nil)) {
            let _: Stub = try await makeSUT().send(Endpoint(path: "/rides/1/accept", method: .post))
        }
    }

    @Test func throws500AsServerError() async {
        defer { MockURLProtocol.requestHandler = nil }
        let body = "Internal Server Error".data(using: .utf8)!
        let url = baseURL
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!, body)
        }
        await #expect(throws: NetworkError.serverError(statusCode: 500, message: "Internal Server Error")) {
            let _: Stub = try await makeSUT().send(Endpoint(path: "/boom", method: .get))
        }
    }

    // MARK: - Request construction

    @Test func setsCorrectHTTPMethod() async throws {
        defer { MockURLProtocol.requestHandler = nil }
        let payload = #"{"ok":true}"#.data(using: .utf8)!
        let url = baseURL
        var capturedMethod: String?
        MockURLProtocol.requestHandler = { req in
            capturedMethod = req.httpMethod
            return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, payload)
        }

        struct Box: Decodable { let ok: Bool }
        let _: Box = try await makeSUT().send(Endpoint(path: "/echo", method: .post))
        #expect(capturedMethod == "POST")
    }

    @Test func setsContentTypeAndAcceptHeaders() async throws {
        defer { MockURLProtocol.requestHandler = nil }
        let payload = #"{"ok":true}"#.data(using: .utf8)!
        let url = baseURL
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { req in
            capturedRequest = req
            return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, payload)
        }

        struct Box: Decodable { let ok: Bool }
        let _: Box = try await makeSUT().send(Endpoint(path: "/headers", method: .get))
        #expect(capturedRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(capturedRequest?.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func forwardsCustomHeaders() async throws {
        defer { MockURLProtocol.requestHandler = nil }
        let payload = #"{"ok":true}"#.data(using: .utf8)!
        let url = baseURL
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { req in
            capturedRequest = req
            return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, payload)
        }

        let endpoint = Endpoint(path: "/auth", method: .get,
                                headers: ["Authorization": "Bearer abc123"])
        struct Box: Decodable { let ok: Bool }
        let _: Box = try await makeSUT().send(endpoint)
        #expect(capturedRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")
    }

    // MARK: - Edge cases

    @Test func throwsNoDataOnEmptySuccessBody() async {
        defer { MockURLProtocol.requestHandler = nil }
        let url = baseURL
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data())
        }
        await #expect(throws: NetworkError.noData) {
            let _: Stub = try await makeSUT().send(Endpoint(path: "/empty", method: .get))
        }
    }

    @Test func throwsDecodingFailedForMalformedJSON() async {
        defer { MockURLProtocol.requestHandler = nil }
        let garbage = "not json at all".data(using: .utf8)!
        let url = baseURL
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, garbage)
        }

        do {
            let _: Stub = try await makeSUT().send(Endpoint(path: "/bad", method: .get))
            Issue.record("Expected decodingFailed to be thrown")
        } catch NetworkError.decodingFailed {
            // ✓ expected
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

/// Minimal decodable stand-in for tests that exercise status-code handling
/// rather than response-body decoding.
private struct Stub: Decodable {}
