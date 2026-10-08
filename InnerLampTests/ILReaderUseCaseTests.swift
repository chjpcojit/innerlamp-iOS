//
//  ILReaderUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILReaderUseCaseTests: XCTestCase {

    private var sut: ILReaderUseCaseImpl!

    override func setUp() {
        super.setUp()
        sut = ILReaderUseCaseImpl()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_getInitialState_audioSutraStartsPlayingAtLineZero() {
        let entity = sut.getInitialState(sutraID: "sutra.phapcu")

        XCTAssertEqual(entity.currentSutraID, "sutra.phapcu")
        XCTAssertEqual(entity.currentLineIndex, 0)
        XCTAssertTrue(entity.isPlaying)
        // Opening ritual (5) + Pháp Cú verses (6 + 6 + 4).
        XCTAssertEqual(sut.currentSutra(in: entity)?.lineCount, 21)
    }

    func test_getInitialState_textOnlySutraStartsPaused() {
        let entity = sut.getInitialState(sutraID: "sutra.duocsu")

        XCTAssertFalse(entity.isPlaying)
        XCTAssertEqual(sut.currentSutra(in: entity)?.hasAudio, false)
    }

    func test_getInitialState_unknownIdFallsBackToFirstSutra() {
        let entity = sut.getInitialState(sutraID: "sutra.unknown")

        XCTAssertEqual(entity.currentSutraID, "sutra.phapcu")
    }

    func test_advance_belowThreshold_accumulatesWithoutMoving() {
        let entity = sut.getInitialState(sutraID: "sutra.phapcu")

        let updated = sut.advance(entity, byMilliseconds: 2000)

        XCTAssertEqual(updated.currentLineIndex, 0)
        XCTAssertEqual(updated.accumulatedMilliseconds, 2000, accuracy: 0.001)
    }

    func test_advance_reachingThreshold_movesToNextLine() {
        let entity = sut.getInitialState(sutraID: "sutra.phapcu")

        let updated = sut.advance(entity, byMilliseconds: 2600)

        XCTAssertEqual(updated.currentLineIndex, 1)
        XCTAssertEqual(updated.accumulatedMilliseconds, 0, accuracy: 0.001)
    }

    func test_advance_speedScalesElapsedTime() {
        var entity = sut.getInitialState(sutraID: "sutra.phapcu")
        entity = sut.setSpeed(entity, to: 1.5)

        let updated = sut.advance(entity, byMilliseconds: 1800) // 1800 × 1.5 = 2700 ≥ 2600

        XCTAssertEqual(updated.currentLineIndex, 1)
    }

    func test_advance_onLastLine_pauses() {
        var entity = sut.getInitialState(sutraID: "sutra.phapcu")
        entity = sut.seek(entity, byLines: 1000)

        let updated = sut.advance(entity, byMilliseconds: 2600)

        XCTAssertFalse(updated.isPlaying)
        XCTAssertEqual(updated.currentLineIndex, 20)
    }

    func test_advance_whilePaused_isNoOp() {
        var entity = sut.getInitialState(sutraID: "sutra.phapcu")
        entity = sut.togglePlayPause(entity)

        XCTAssertEqual(sut.advance(entity, byMilliseconds: 5000), entity)
    }

    func test_seek_clampsToFirstAndLastLine() {
        let entity = sut.getInitialState(sutraID: "sutra.phapcu")

        XCTAssertEqual(sut.seek(entity, byLines: -2).currentLineIndex, 0)
        XCTAssertEqual(sut.seek(entity, byLines: 2).currentLineIndex, 2)
        XCTAssertEqual(sut.seek(entity, byLines: 1000).currentLineIndex, 20)
    }

    func test_progressAndElapsed_followCurrentLine() {
        var entity = sut.getInitialState(sutraID: "sutra.phapcu")
        XCTAssertEqual(sut.progress(in: entity), 0, accuracy: 0.0001)
        XCTAssertEqual(sut.elapsedSeconds(in: entity), 0)

        entity = sut.seek(entity, byLines: 10) // 10 / 20
        XCTAssertEqual(sut.progress(in: entity), 0.5, accuracy: 0.0001)
        XCTAssertEqual(sut.elapsedSeconds(in: entity), 130 * 60 / 2)
    }
}
