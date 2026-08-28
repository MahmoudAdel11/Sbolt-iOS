//
//  NetworkErrorTests.swift
//  Yalla GoTests
//

import Testing
@testable import Sbolt

struct NetworkErrorTests {

    // MARK: - Equatability

    @Test func invalidURLEquality()        { #expect(NetworkError.invalidURL       == .invalidURL)       }
    @Test func noDataEquality()            { #expect(NetworkError.noData           == .noData)           }
    @Test func unauthorizedEquality()      { #expect(NetworkError.unauthorized     == .unauthorized)     }
    @Test func notFoundEquality()          { #expect(NetworkError.notFound         == .notFound)         }
    @Test func requestCancelledEquality()  { #expect(NetworkError.requestCancelled == .requestCancelled) }

    @Test func decodingFailedCarriesMessage() {
        let sut = NetworkError.decodingFailed("missing key 'id'")
        guard case .decodingFailed(let msg) = sut else {
            Issue.record("Expected .decodingFailed"); return
        }
        #expect(msg == "missing key 'id'")
    }

    @Test func serverErrorCarriesStatusCodeAndMessage() {
        let sut = NetworkError.serverError(statusCode: 503, message: "Service Unavailable")
        guard case .serverError(let code, let msg) = sut else {
            Issue.record("Expected .serverError"); return
        }
        #expect(code == 503)
        #expect(msg == "Service Unavailable")
    }

    @Test func serverErrorWithNilMessageIsEquatable() {
        #expect(NetworkError.serverError(statusCode: 500, message: nil)
             == NetworkError.serverError(statusCode: 500, message: nil))
    }

    @Test func serverErrorsWithDifferentCodesAreNotEqual() {
        #expect(NetworkError.serverError(statusCode: 400, message: nil)
             != NetworkError.serverError(statusCode: 500, message: nil))
    }

    @Test func unknownCarriesDescription() {
        let sut = NetworkError.unknown("connection reset")
        guard case .unknown(let desc) = sut else {
            Issue.record("Expected .unknown"); return
        }
        #expect(desc == "connection reset")
    }

    @Test func differentVariantsAreNotEqual() {
        #expect(NetworkError.unauthorized     != .notFound)
        #expect(NetworkError.noData          != .requestCancelled)
        #expect(NetworkError.invalidURL      != .noData)
    }
}
