//
//  ILSplashViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILSplashViewModelTests: XCTestCase {

    private var mockUseCase: MockILSplashUseCase!
    private var sut: ILSplashViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILSplashUseCase()
        sut = ILSplashViewModel(useCase: mockUseCase)
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    func test_initialState_matchesUseCaseDefault() {
        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let output = sut.transform(input: .init(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            splashFinished: Empty().eraseToAnyPublisher()
        ))

        var receivedState: ILSplashStateModel?
        output.state
            .sink { state in
                if case .success = state { receivedState = ILSplashStateModel.initial }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        XCTAssertNotNil(receivedState)
        XCTAssertTrue(mockUseCase.getInitialStateCalled)
    }

    func test_splashFinished_firesGoToOnboardingNavigationEvent() {
        let splashFinishedSubject = PassthroughSubject<Void, Never>()
        let output = sut.transform(input: .init(
            viewDidLoad: Empty().eraseToAnyPublisher(),
            splashFinished: splashFinishedSubject.eraseToAnyPublisher()
        ))
        output.state.sink { _ in }.store(in: &cancellables)

        var receivedEvent: ILSplashNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        splashFinishedSubject.send(())

        XCTAssertEqual(receivedEvent, .goToOnboarding)
    }

    func test_splashFinished_withStoredSession_firesGoToMainNavigationEvent() {
        mockUseCase.hasSessionResult = true
        let splashFinishedSubject = PassthroughSubject<Void, Never>()
        let output = sut.transform(input: .init(
            viewDidLoad: Empty().eraseToAnyPublisher(),
            splashFinished: splashFinishedSubject.eraseToAnyPublisher()
        ))
        output.state.sink { _ in }.store(in: &cancellables)

        var receivedEvent: ILSplashNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        splashFinishedSubject.send(())

        XCTAssertEqual(receivedEvent, .goToMain)
    }
}

// MARK: - Mock ILSplashUseCase
final class MockILSplashUseCase: ILSplashUseCase {
    var getInitialStateCalled = false
    func getInitialState() -> ILSplashStateModel {
        getInitialStateCalled = true
        return ILSplashStateModel.initial
    }

    var isOnboardingCompletedCalled = false
    var isOnboardingCompletedResult = false
    func isOnboardingCompleted() -> Bool {
        isOnboardingCompletedCalled = true
        return isOnboardingCompletedResult
    }

    var hasSessionResult = false
    func hasSession() -> Bool {
        hasSessionResult
    }
}
