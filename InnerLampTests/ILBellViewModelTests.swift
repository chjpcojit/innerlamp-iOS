//
//  ILBellViewModelTests.swift
//  InnerLampTests
//
//  Created by ChjpCoj on 26/9/26.
//

import XCTest
import Combine
@testable import InnerLamp

final class ILBellViewModelTests: XCTestCase {

    private var mockUseCase: MockILBellUseCase!
    private var mockSoundPlayer: MockILPracticeSoundPlayer!
    private var sut: ILBellViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var presetSelectedSubject: PassthroughSubject<Int, Never>!
    private var modeSelectedSubject: PassthroughSubject<ILBellMode, Never>!
    private var everySelectedSubject: PassthroughSubject<Int, Never>!
    private var rateAdjustTappedSubject: PassthroughSubject<Int, Never>!
    private var padTappedSubject: PassthroughSubject<Void, Never>!
    private var toggleTappedSubject: PassthroughSubject<Void, Never>!
    private var leftButtonTappedSubject: PassthroughSubject<Void, Never>!
    private var ringBellTappedSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILBellUseCase()
        mockSoundPlayer = MockILPracticeSoundPlayer()
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        presetSelectedSubject = PassthroughSubject<Int, Never>()
        modeSelectedSubject = PassthroughSubject<ILBellMode, Never>()
        everySelectedSubject = PassthroughSubject<Int, Never>()
        rateAdjustTappedSubject = PassthroughSubject<Int, Never>()
        padTappedSubject = PassthroughSubject<Void, Never>()
        toggleTappedSubject = PassthroughSubject<Void, Never>()
        leftButtonTappedSubject = PassthroughSubject<Void, Never>()
        ringBellTappedSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockUseCase = nil
        mockSoundPlayer = nil
        viewDidLoadSubject = nil
        presetSelectedSubject = nil
        modeSelectedSubject = nil
        everySelectedSubject = nil
        rateAdjustTappedSubject = nil
        padTappedSubject = nil
        toggleTappedSubject = nil
        leftButtonTappedSubject = nil
        ringBellTappedSubject = nil
        backTappedSubject = nil
        super.tearDown()
    }

    private func makeSut(stubEntity: ILBellEntity = ILBellEntity()) {
        mockUseCase.stubEntity = stubEntity
        sut = ILBellViewModel(useCase: mockUseCase, soundPlayer: mockSoundPlayer)
    }

    private func makeInput() -> ILBellViewModel.Input {
        ILBellViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            presetSelected: presetSelectedSubject.eraseToAnyPublisher(),
            modeSelected: modeSelectedSubject.eraseToAnyPublisher(),
            everySelected: everySelectedSubject.eraseToAnyPublisher(),
            rateAdjustTapped: rateAdjustTappedSubject.eraseToAnyPublisher(),
            padTapped: padTappedSubject.eraseToAnyPublisher(),
            toggleTapped: toggleTappedSubject.eraseToAnyPublisher(),
            leftButtonTapped: leftButtonTappedSubject.eraseToAnyPublisher(),
            ringBellTapped: ringBellTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher()
        )
    }

    private func observeState(_ output: ILBellViewModel.Output) -> StateBox {
        let box = StateBox()
        output.state
            .sink { state in
                if case .success(let model) = state { box.latest = model }
            }
            .store(in: &cancellables)
        return box
    }

    // MARK: - Initial state

    func test_initialState_matchesDefaultConfiguration() {
        makeSut()
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        XCTAssertEqual(box.latest?.headerTitle, "bell.header.title".localized)
        XCTAssertEqual(box.latest?.presetLabels.count, 5)
        XCTAssertEqual(box.latest?.modeLabels, [
            "bell.mode.mo".localized,
            "bell.mode.bell".localized,
            "bell.mode.both".localized,
        ])
        XCTAssertEqual(box.latest?.selectedPresetIndex, 0)
        XCTAssertEqual(box.latest?.selectedMode, .moAndBell)
        XCTAssertEqual(box.latest?.rateValue, String(format: "bell.rate.bpmFormat".localized, 72))
        XCTAssertEqual(box.latest?.padTag, "bell.pad.tag.mo".localized)
        XCTAssertEqual(box.latest?.padNumber, 0)
        XCTAssertTrue(box.latest?.showEveryRow == true)
        XCTAssertEqual(box.latest?.moCountText, String(format: "bell.count.moFormat".localized, 0))
        XCTAssertEqual(box.latest?.bellCountText, String(format: "bell.count.bellFormat".localized, 0))
    }

    // MARK: - Strikes

    func test_padTapped_inMoMode_incrementsMoCount() {
        makeSut()
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        padTappedSubject.send(())

        XCTAssertTrue(mockUseCase.strikeMoCalled)
        XCTAssertTrue(mockSoundPlayer.playMoCalled)
        XCTAssertEqual(box.latest?.moCount, 1)
        XCTAssertEqual(box.latest?.bellCount, 0)
    }

    func test_padTapped_inBellMode_incrementsBellCount() {
        makeSut(stubEntity: ILBellEntity(mode: .bell))
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        padTappedSubject.send(())

        XCTAssertTrue(mockUseCase.strikeBellCalled)
        XCTAssertTrue(mockSoundPlayer.playBellCalled)
        XCTAssertEqual(box.latest?.bellCount, 1)
        XCTAssertEqual(box.latest?.moCount, 0)
        XCTAssertEqual(box.latest?.padNumber, 1)
    }

    func test_ringBellTapped_incrementsBellCount() {
        makeSut()
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        ringBellTappedSubject.send(())

        XCTAssertTrue(mockUseCase.strikeBellCalled)
        XCTAssertTrue(mockSoundPlayer.playBellCalled)
        XCTAssertEqual(box.latest?.bellCount, 1)
    }

    // MARK: - Playback state

    func test_toggleTapped_startsRunning() {
        makeSut()
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        toggleTappedSubject.send(())

        XCTAssertTrue(mockUseCase.setRunningCalled)
        XCTAssertEqual(box.latest?.isRunning, true)
    }

    func test_leftButtonTapped_inBellMode_resetsCounters() {
        makeSut(stubEntity: ILBellEntity(mode: .bell, moCount: 5, bellCount: 7))
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        leftButtonTappedSubject.send(())

        XCTAssertTrue(mockUseCase.resetCountersCalled)
        XCTAssertEqual(box.latest?.moCount, 0)
        XCTAssertEqual(box.latest?.bellCount, 0)
    }

    func test_leftButtonTapped_inMoMode_startsRoll() {
        makeSut()
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        leftButtonTappedSubject.send(())

        XCTAssertTrue(mockUseCase.setRollingCalled)
        XCTAssertEqual(box.latest?.isRolling, true)
    }

    // MARK: - Configuration

    func test_presetSelected_appliesPreset() {
        makeSut()
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        presetSelectedSubject.send(1) // Niệm Phật: mo + bell, bpm 96, every 108

        XCTAssertTrue(mockUseCase.selectPresetCalled)
        XCTAssertEqual(box.latest?.selectedPresetIndex, 1)
        XCTAssertEqual(box.latest?.selectedMode, .moAndBell)
        XCTAssertEqual(box.latest?.rateValue, String(format: "bell.rate.bpmFormat".localized, 96))
        XCTAssertEqual(box.latest?.selectedEveryIndex, 3)
    }

    func test_modeSelected_marksCustomAndHidesEveryRow() {
        makeSut()
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        modeSelectedSubject.send(.mo)

        XCTAssertTrue(mockUseCase.selectModeCalled)
        XCTAssertEqual(box.latest?.selectedMode, .mo)
        XCTAssertEqual(box.latest?.selectedPresetIndex, -1)
        XCTAssertEqual(box.latest?.showEveryRow, false)
    }

    func test_everySelected_updatesMilestone() {
        makeSut()
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        everySelectedSubject.send(0) // value 0 = off

        XCTAssertTrue(mockUseCase.selectEveryCalled)
        XCTAssertEqual(box.latest?.selectedEveryIndex, 0)
    }

    func test_rateAdjust_updatesRateValue() {
        makeSut()
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())
        rateAdjustTappedSubject.send(1) // bpm 72 -> 76

        XCTAssertTrue(mockUseCase.adjustRateCalled)
        XCTAssertEqual(box.latest?.rateValue, String(format: "bell.rate.bpmFormat".localized, 76))
    }

    // MARK: - Navigation

    func test_backTapped_firesGoBackNavigationEvent() {
        makeSut()
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILBellNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goBack)
    }
}

// MARK: - ILBellUseCaseImpl (real domain rules)
final class ILBellUseCaseTests: XCTestCase {

    private let sut = ILBellUseCaseImpl()

    func test_selectPreset_appliesAllDefinedFields() {
        let result = sut.selectPreset(1, on: ILBellEntity(mode: .mo, bpm: 60, gapSeconds: 20, everyCount: 0, presetIndex: 0))

        XCTAssertEqual(result.mode, .moAndBell)
        XCTAssertEqual(result.bpm, 96)
        XCTAssertEqual(result.everyCount, 108)
        XCTAssertEqual(result.presetIndex, 1)
        XCTAssertFalse(result.isRunning)
        XCTAssertFalse(result.isRolling)
    }

    func test_selectPreset_outOfRange_returnsSameEntity() {
        let entity = ILBellEntity()
        let result = sut.selectPreset(99, on: entity)
        XCTAssertEqual(result, entity)
    }

    func test_selectMode_marksCustomAndStops() {
        let result = sut.selectMode(.mo, on: ILBellEntity(mode: .bell, presetIndex: 2, isRunning: true))

        XCTAssertEqual(result.mode, .mo)
        XCTAssertEqual(result.presetIndex, -1)
        XCTAssertFalse(result.isRunning)
    }

    func test_adjustRate_inBellMode_clampsGap() {
        let tooLow = sut.adjustRate(by: -1, on: ILBellEntity(mode: .bell, gapSeconds: 5))
        XCTAssertEqual(tooLow.gapSeconds, 5)

        let tooHigh = sut.adjustRate(by: 1, on: ILBellEntity(mode: .bell, gapSeconds: 120))
        XCTAssertEqual(tooHigh.gapSeconds, 120)

        let normal = sut.adjustRate(by: 1, on: ILBellEntity(mode: .bell, gapSeconds: 20))
        XCTAssertEqual(normal.gapSeconds, 25)
    }

    func test_adjustRate_inMoMode_clampsBpm() {
        let tooLow = sut.adjustRate(by: -1, on: ILBellEntity(mode: .mo, bpm: 40))
        XCTAssertEqual(tooLow.bpm, 40)

        let tooHigh = sut.adjustRate(by: 1, on: ILBellEntity(mode: .moAndBell, bpm: 160))
        XCTAssertEqual(tooHigh.bpm, 160)

        let normal = sut.adjustRate(by: 1, on: ILBellEntity(mode: .mo, bpm: 72))
        XCTAssertEqual(normal.bpm, 76)
    }

    func test_strikeMo_incrementsCount() {
        let result = sut.strikeMo(ILBellEntity(moCount: 3))
        XCTAssertEqual(result.moCount, 4)
        XCTAssertEqual(result.bellCount, 0)
    }

    func test_strikeBell_incrementsCount() {
        let result = sut.strikeBell(ILBellEntity(bellCount: 2))
        XCTAssertEqual(result.bellCount, 3)
        XCTAssertEqual(result.moCount, 0)
    }

    func test_shouldRingBellAfterMo_onlyInMoAndBellModeAndAtMilestone() {
        XCTAssertTrue(sut.shouldRingBellAfterMo(ILBellEntity(mode: .moAndBell, everyCount: 10, moCount: 10)))
        XCTAssertTrue(sut.shouldRingBellAfterMo(ILBellEntity(mode: .moAndBell, everyCount: 108, moCount: 108)))

        XCTAssertFalse(sut.shouldRingBellAfterMo(ILBellEntity(mode: .moAndBell, everyCount: 10, moCount: 9)))
        XCTAssertFalse(sut.shouldRingBellAfterMo(ILBellEntity(mode: .moAndBell, everyCount: 0, moCount: 10)))
        XCTAssertFalse(sut.shouldRingBellAfterMo(ILBellEntity(mode: .mo, everyCount: 10, moCount: 10)))
        XCTAssertFalse(sut.shouldRingBellAfterMo(ILBellEntity(mode: .moAndBell, everyCount: 10, moCount: 0)))
    }

    func test_resetCounters_zeroesAndStops() {
        let result = sut.resetCounters(ILBellEntity(moCount: 8, bellCount: 4, isRunning: true, isRolling: true))

        XCTAssertEqual(result.moCount, 0)
        XCTAssertEqual(result.bellCount, 0)
        XCTAssertFalse(result.isRunning)
        XCTAssertFalse(result.isRolling)
    }

    func test_intervalSeconds_bellMode_usesGap() {
        XCTAssertEqual(sut.intervalSeconds(for: ILBellEntity(mode: .bell, gapSeconds: 30)), 30)
    }

    func test_intervalSeconds_moMode_usesBpm() {
        XCTAssertEqual(sut.intervalSeconds(for: ILBellEntity(mode: .mo, bpm: 120)), 0.5, accuracy: 0.0001)
    }
}

// MARK: - Helpers
private final class StateBox {
    var latest: ILBellStateModel?
}

// MARK: - Mock ILBellUseCase
final class MockILBellUseCase: ILBellUseCase {

    private let impl = ILBellUseCaseImpl()
    var stubEntity = ILBellEntity()

    var presets: [ILBellPreset] { impl.presets }
    var everyOptions: [Int] { impl.everyOptions }

    var getInitialStateCalled = false
    func getInitialState() -> ILBellEntity {
        getInitialStateCalled = true
        return stubEntity
    }

    var selectPresetCalled = false
    func selectPreset(_ index: Int, on entity: ILBellEntity) -> ILBellEntity {
        selectPresetCalled = true
        return impl.selectPreset(index, on: entity)
    }

    var selectModeCalled = false
    func selectMode(_ mode: ILBellMode, on entity: ILBellEntity) -> ILBellEntity {
        selectModeCalled = true
        return impl.selectMode(mode, on: entity)
    }

    var selectEveryCalled = false
    func selectEvery(_ value: Int, on entity: ILBellEntity) -> ILBellEntity {
        selectEveryCalled = true
        return impl.selectEvery(value, on: entity)
    }

    var adjustRateCalled = false
    func adjustRate(by delta: Int, on entity: ILBellEntity) -> ILBellEntity {
        adjustRateCalled = true
        return impl.adjustRate(by: delta, on: entity)
    }

    var strikeMoCalled = false
    func strikeMo(_ entity: ILBellEntity) -> ILBellEntity {
        strikeMoCalled = true
        return impl.strikeMo(entity)
    }

    var strikeBellCalled = false
    func strikeBell(_ entity: ILBellEntity) -> ILBellEntity {
        strikeBellCalled = true
        return impl.strikeBell(entity)
    }

    func shouldRingBellAfterMo(_ entity: ILBellEntity) -> Bool {
        impl.shouldRingBellAfterMo(entity)
    }

    var resetCountersCalled = false
    func resetCounters(_ entity: ILBellEntity) -> ILBellEntity {
        resetCountersCalled = true
        return impl.resetCounters(entity)
    }

    var setRunningCalled = false
    func setRunning(_ running: Bool, on entity: ILBellEntity) -> ILBellEntity {
        setRunningCalled = true
        return impl.setRunning(running, on: entity)
    }

    var setRollingCalled = false
    func setRolling(_ rolling: Bool, on entity: ILBellEntity) -> ILBellEntity {
        setRollingCalled = true
        return impl.setRolling(rolling, on: entity)
    }

    func intervalSeconds(for entity: ILBellEntity) -> TimeInterval {
        impl.intervalSeconds(for: entity)
    }
}

// MARK: - Mock ILPracticeSoundPlaying
final class MockILPracticeSoundPlayer: ILPracticeSoundPlaying {

    var playMoCalled = false
    var playBellCalled = false
    var playBeadCalled = false

    func playMo() {
        playMoCalled = true
    }

    func playBell() {
        playBellCalled = true
    }

    func playBead() {
        playBeadCalled = true
    }
}
