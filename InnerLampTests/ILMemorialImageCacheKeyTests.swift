//
//  ILMemorialImageCacheKeyTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

/// G1 item 4: the portrait cache follows the entry, not the 15-minute signed URL.
final class ILMemorialImageCacheKeyTests: XCTestCase {

    func test_signedQueryChange_reusesTheSameCacheKey() {
        let first = ILMemorialAvatarView.cacheKey(
            entryID: "42",
            photoURLString: "https://cdn.example.com/memorial/42/a.jpg?X-Amz-Signature=one"
        )
        let refreshed = ILMemorialAvatarView.cacheKey(
            entryID: "42",
            photoURLString: "https://cdn.example.com/memorial/42/a.jpg?X-Amz-Signature=two"
        )

        XCTAssertEqual(first, refreshed)
        XCTAssertTrue(first.contains("42"))
        XCTAssertFalse(first.contains("Signature"))
    }

    func test_replacedPhoto_changesTheCacheKey() {
        let old = ILMemorialAvatarView.cacheKey(
            entryID: "42",
            photoURLString: "https://cdn.example.com/memorial/42/old.jpg?sig=1"
        )
        let new = ILMemorialAvatarView.cacheKey(
            entryID: "42",
            photoURLString: "https://cdn.example.com/memorial/42/new.jpg?sig=1"
        )

        XCTAssertNotEqual(old, new, "A replaced photo must not serve the old bitmap")
    }
}
