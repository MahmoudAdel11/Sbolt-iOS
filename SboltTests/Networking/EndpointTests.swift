//
//  EndpointTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Sbolt

struct EndpointTests {

    private let base = URL(string: "https://api.yallago.com/v1")!

    // MARK: - URL construction

    @Test func pathWithLeadingSlashBuildsCorrectURL() {
        let sut = Endpoint(path: "/auth/login", method: .post)
        #expect(sut.url(relativeTo: base)?.absoluteString == "https://api.yallago.com/v1/auth/login")
    }

    @Test func pathWithoutLeadingSlashBuildsCorrectURL() {
        let sut = Endpoint(path: "auth/login", method: .post)
        #expect(sut.url(relativeTo: base)?.absoluteString == "https://api.yallago.com/v1/auth/login")
    }

    @Test func nestedPathSegmentsBuildsCorrectly() {
        let sut = Endpoint(path: "/favorites/fav-123", method: .delete)
        #expect(sut.url(relativeTo: base)?.absoluteString == "https://api.yallago.com/v1/favorites/fav-123")
    }

    @Test func appendsQueryItemsToURL() {
        let sut = Endpoint(
            path: "/trips",
            method: .get,
            queryItems: [
                URLQueryItem(name: "limit", value: "20"),
                URLQueryItem(name: "page", value: "1")
            ]
        )
        let url = sut.url(relativeTo: base)!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let items = components.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "limit", value: "20")))
        #expect(items.contains(URLQueryItem(name: "page", value: "1")))
    }

    @Test func omitsQueryStringWhenQueryItemsAreEmpty() {
        let sut = Endpoint(path: "/profile", method: .get)
        let url = sut.url(relativeTo: base)!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        #expect(components.queryItems == nil)
    }

    // MARK: - Default values

    @Test func defaultsToNoHeadersBodyOrQueryItems() {
        let sut = Endpoint(path: "/test", method: .get)
        #expect(sut.headers.isEmpty)
        #expect(sut.queryItems.isEmpty)
        #expect(sut.body == nil)
    }

    @Test func storesCustomHeaders() {
        let sut = Endpoint(path: "/secure", method: .get,
                           headers: ["Authorization": "Bearer token"])
        #expect(sut.headers["Authorization"] == "Bearer token")
    }

    @Test func storesBodyData() throws {
        let payload = try JSONEncoder().encode(["key": "value"])
        let sut = Endpoint(path: "/data", method: .post, body: payload)
        #expect(sut.body == payload)
    }

    // MARK: - HTTP methods

    @Test func getMethodRawValue()    { #expect(HTTPMethod.get.rawValue    == "GET")    }
    @Test func postMethodRawValue()   { #expect(HTTPMethod.post.rawValue   == "POST")   }
    @Test func putMethodRawValue()    { #expect(HTTPMethod.put.rawValue    == "PUT")    }
    @Test func patchMethodRawValue()  { #expect(HTTPMethod.patch.rawValue  == "PATCH")  }
    @Test func deleteMethodRawValue() { #expect(HTTPMethod.delete.rawValue == "DELETE") }
}
