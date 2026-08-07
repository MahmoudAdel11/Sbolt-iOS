//
//  FavoritePlaceIconTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

struct FavoritePlaceIconTests {

    private func makePlace(title: String) -> FavoritePlace {
        FavoritePlace(id: "id", title: title, address: "address",
                     coordinate: Coordinate(latitude: 0, longitude: 0),
                     createdAt: Date())
    }

    @Test func homeMapsToHouseIcon() {
        #expect(makePlace(title: "Home").icon == "house.fill")
        #expect(makePlace(title: "My home base").icon == "house.fill")
    }

    @Test func workOrOfficeMapsToBriefcaseIcon() {
        #expect(makePlace(title: "Work").icon == "briefcase.fill")
        #expect(makePlace(title: "Office").icon == "briefcase.fill")
    }

    @Test func gymOrFitnessMapsToDumbbellIcon() {
        #expect(makePlace(title: "Gym").icon == "dumbbell.fill")
        #expect(makePlace(title: "Fitness Club").icon == "dumbbell.fill")
    }

    @Test func matchingIsCaseInsensitive() {
        #expect(makePlace(title: "HOME").icon == "house.fill")
        #expect(makePlace(title: "wOrK").icon == "briefcase.fill")
    }

    @Test func unmatchedTitleMapsToGenericPin() {
        #expect(makePlace(title: "University").icon == "mappin.and.ellipse")
        #expect(makePlace(title: "Grandma's House").icon == "mappin.and.ellipse")
    }
}
