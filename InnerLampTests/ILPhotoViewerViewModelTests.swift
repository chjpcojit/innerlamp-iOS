//
//  ILPhotoViewerViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILPhotoViewerViewModelTests: XCTestCase {

    private var sut: ILPhotoViewerViewModel!
    private var output: ILPhotoViewerViewModel.Output!
    private var cancellables: Set<AnyCancellable>!
    private var latest: ILPhotoViewerStateModel?

    private var closeSubject: PassthroughSubject<Void, Never>!
    private var previousSubject: PassthroughSubject<Void, Never>!
    private var nextSubject: PassthroughSubject<Void, Never>!
    private var favoriteSubject: PassthroughSubject<Void, Never>!
    private var actionSubject: PassthroughSubject<ILPhotoViewerAction, Never>!

    private static func item(_ id: String) -> ILPhotoViewerItemModel {
        ILPhotoViewerItemModel(id: id, title: "Title \(id)", place: "Place", categoryLabel: "Chùa", imageURL: nil)
    }

    override func setUp() {
        super.setUp()
        cancellables = []
        closeSubject = PassthroughSubject()
        previousSubject = PassthroughSubject()
        nextSubject = PassthroughSubject()
        favoriteSubject = PassthroughSubject()
        actionSubject = PassthroughSubject()
        makeSUT(startID: "b", toastDuration: 5)
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        output = nil
        latest = nil
        super.tearDown()
    }

    private func makeSUT(startID: String, toastDuration: TimeInterval) {
        sut = ILPhotoViewerViewModel(
            items: [Self.item("a"), Self.item("b"), Self.item("c")],
            startID: startID,
            toastDuration: toastDuration
        )
        // `transform` binds the inputs, so it must run exactly once per ViewModel.
        output = sut.transform(input: ILPhotoViewerViewModel.Input(
            closeTapped: closeSubject.eraseToAnyPublisher(),
            previousTapped: previousSubject.eraseToAnyPublisher(),
            nextTapped: nextSubject.eraseToAnyPublisher(),
            favoriteTapped: favoriteSubject.eraseToAnyPublisher(),
            actionTapped: actionSubject.eraseToAnyPublisher()
        ))
        output.state
            .sink { [weak self] state in
                if case .success(let model) = state { self?.latest = model }
            }
            .store(in: &cancellables)
    }

    func test_init_unknownStartID_returnsNil() {
        XCTAssertNil(ILPhotoViewerViewModel(items: [Self.item("a")], startID: "zzz"))
    }

    func test_initialState_showsStartPhotoWithNeighbours() {
        XCTAssertEqual(latest?.item.id, "b")
        XCTAssertEqual(latest?.hasPrevious, true)
        XCTAssertEqual(latest?.hasNext, true)
        XCTAssertEqual(latest?.isFavorite, false)
        XCTAssertEqual(latest?.toast, "")
    }

    func test_nextAndPrevious_stepAndStopAtEnds() {
        nextSubject.send(())
        XCTAssertEqual(latest?.item.id, "c")
        XCTAssertEqual(latest?.hasNext, false)

        nextSubject.send(())
        XCTAssertEqual(latest?.item.id, "c")

        previousSubject.send(())
        previousSubject.send(())
        XCTAssertEqual(latest?.item.id, "a")
        XCTAssertEqual(latest?.hasPrevious, false)

        previousSubject.send(())
        XCTAssertEqual(latest?.item.id, "a")
    }

    func test_favoriteTapped_togglesPerPhotoAndShowsToast() {
        favoriteSubject.send(())
        XCTAssertEqual(latest?.isFavorite, true)
        XCTAssertEqual(latest?.toast, "photoViewer.toast.favoriteOn".localized)

        nextSubject.send(())
        XCTAssertEqual(latest?.isFavorite, false)

        previousSubject.send(())
        XCTAssertEqual(latest?.isFavorite, true)

        favoriteSubject.send(())
        XCTAssertEqual(latest?.isFavorite, false)
        XCTAssertEqual(latest?.toast, "photoViewer.toast.favoriteOff".localized)
    }

    func test_actionTapped_showsMatchingToast() {
        actionSubject.send(.save)
        XCTAssertEqual(latest?.toast, "photoViewer.toast.saved".localized)
        actionSubject.send(.setWallpaper)
        XCTAssertEqual(latest?.toast, "photoViewer.toast.wallpaperSet".localized)
        actionSubject.send(.share)
        XCTAssertEqual(latest?.toast, "photoViewer.toast.shared".localized)
    }

    func test_toast_clearsAfterDuration() async throws {
        cancellables = []
        makeSUT(startID: "b", toastDuration: 0.05)

        actionSubject.send(.save)
        XCTAssertEqual(latest?.toast, "photoViewer.toast.saved".localized)

        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(latest?.toast, "")
    }

    func test_stepping_clearsToast() {
        actionSubject.send(.save)
        nextSubject.send(())
        XCTAssertEqual(latest?.toast, "")
    }

    func test_closeTapped_firesCloseEvent() {
        var received: ILPhotoViewerNavEvent?
        sut.navigationEventPublisher
            .sink { received = $0 }
            .store(in: &cancellables)

        closeSubject.send(())

        XCTAssertEqual(received, .close)
    }
}
