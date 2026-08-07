//
//  TripHistoryPage.swift
//  Yalla Go
//

import Foundation

/// One page of trip history, plus whether a further page exists. Mirrors the
/// backend's `{items, has_more}` shape — no total count is available.
struct TripHistoryPage: Equatable {
    let trips: [Trip]
    let hasMore: Bool
}
