//
//  RideAnnotationDiffTests.swift
//  Yalla GoTests
//

import Testing
@testable import Sbolt

struct RideAnnotationDiffTests {

    @Test func addsOnlyNewIDs() {
        let diff = RideAnnotationDiff.compute(existingIDs: ["a"], incomingIDs: ["a", "b", "c"])

        #expect(diff.toAdd == ["b", "c"])
        #expect(diff.toRemove.isEmpty)
    }

    @Test func removesOnlyMissingIDs() {
        let diff = RideAnnotationDiff.compute(existingIDs: ["a", "b", "c"], incomingIDs: ["a"])

        #expect(diff.toAdd.isEmpty)
        #expect(diff.toRemove == ["b", "c"])
    }

    @Test func mixedAddAndRemove() {
        let diff = RideAnnotationDiff.compute(existingIDs: ["a", "b"], incomingIDs: ["b", "c"])

        #expect(diff.toAdd == ["c"])
        #expect(diff.toRemove == ["a"])
    }

    @Test func unchangedSetProducesEmptyDiff() {
        let diff = RideAnnotationDiff.compute(existingIDs: ["a", "b"], incomingIDs: ["a", "b"])

        #expect(diff.toAdd.isEmpty)
        #expect(diff.toRemove.isEmpty)
    }

    @Test func emptyToEmptyProducesEmptyDiff() {
        let diff = RideAnnotationDiff.compute(existingIDs: [], incomingIDs: [])

        #expect(diff.toAdd.isEmpty)
        #expect(diff.toRemove.isEmpty)
    }

    @Test func firstPopulationAddsEverything() {
        let diff = RideAnnotationDiff.compute(existingIDs: [], incomingIDs: ["a", "b"])

        #expect(diff.toAdd == ["a", "b"])
        #expect(diff.toRemove.isEmpty)
    }

    @Test func allRemovedProducesFullRemoval() {
        let diff = RideAnnotationDiff.compute(existingIDs: ["a", "b"], incomingIDs: [])

        #expect(diff.toAdd.isEmpty)
        #expect(diff.toRemove == ["a", "b"])
    }
}
