//
//  AutoZoomTriggerTests.swift
//  Yalla GoTests
//

import Testing
@testable import Yalla_Go

struct AutoZoomTriggerTests {

    @Test func firesWhenFirstRidesAppear() {
        let shouldZoom = AutoZoomTrigger.shouldZoom(zoomedRideIDs: [], incomingIDs: ["a"])
        #expect(shouldZoom == true)
    }

    @Test func doesNotFireWhenStillEmpty() {
        let shouldZoom = AutoZoomTrigger.shouldZoom(zoomedRideIDs: [], incomingIDs: [])
        #expect(shouldZoom == false)
    }

    @Test func doesNotFireWhenOnlyPreviouslyZoomedIDsArePresent() {
        // Background poll re-fetching the exact same rides already accounted
        // for in a prior zoom must not re-trigger.
        let shouldZoom = AutoZoomTrigger.shouldZoom(zoomedRideIDs: ["a", "b"], incomingIDs: ["a"])
        #expect(shouldZoom == false)
    }

    @Test func doesNotFireWhenIncomingIsExactlyThePreviouslyZoomedSet() {
        let shouldZoom = AutoZoomTrigger.shouldZoom(zoomedRideIDs: ["a", "b"], incomingIDs: ["a", "b"])
        #expect(shouldZoom == false)
    }

    @Test func firesWhenANewRideIDAppearsAlongsideAlreadyZoomedOnes() {
        // The "two rides close together" bug: ride "a" was already zoomed
        // for, then ride "b" shows up on the next poll.
        let shouldZoom = AutoZoomTrigger.shouldZoom(zoomedRideIDs: ["a"], incomingIDs: ["a", "b"])
        #expect(shouldZoom == true)
    }

    @Test func firesWhenAllPreviousRidesGoneAndACompletelyNewOneArrives() {
        // The "cancel then new ride" bug: everything zoomed for is gone
        // (incoming happens to be empty for a poll or two), then a fresh,
        // never-seen ride ID shows up later.
        let shouldZoom = AutoZoomTrigger.shouldZoom(zoomedRideIDs: ["a"], incomingIDs: ["c"])
        #expect(shouldZoom == true)
    }

    @Test func doesNotFireOnTransientEmptyBatchBetweenZoomedRides() {
        let shouldZoom = AutoZoomTrigger.shouldZoom(zoomedRideIDs: ["a"], incomingIDs: [])
        #expect(shouldZoom == false)
    }

    @Test func firesOnlyOnceForTheSameNewRideAcrossRepeatedPolls() {
        // Simulates: fire for "b", then a later poll still contains "b" (and
        // "a") unchanged — must not re-fire since both are now zoomed.
        var zoomed: Set<String> = ["a"]
        let firstPoll = AutoZoomTrigger.shouldZoom(zoomedRideIDs: zoomed, incomingIDs: ["a", "b"])
        #expect(firstPoll == true)
        zoomed.formUnion(["a", "b"])

        let secondPoll = AutoZoomTrigger.shouldZoom(zoomedRideIDs: zoomed, incomingIDs: ["a", "b"])
        #expect(secondPoll == false)
    }
}
