//
//  ILPhotosViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILPhotosViewModelTests: XCTestCase {

    private var mockUseCase: MockILPhotosUseCase!
    private var sut: ILPhotosViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var categorySelectedSubject: PassthroughSubject<ILPhotosCategory?, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILPhotosUseCase()
        sut = ILPhotosViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        categorySelectedSubject = PassthroughSubject<ILPhotosCategory?, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        categorySelectedSubject = nil
        backTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILPhotosViewModel.Input {
        ILPhotosViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            categorySelected: categorySelectedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher()
        )
    }

    private func observeLatestState() -> () -> ILPhotosStateModel? {
        let output = sut.transform(input: makeInput())
        var latest: ILPhotosStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { latest = model }
            }
            .store(in: &cancellables)
        return { latest }
    }

    func test_viewDidLoad_showsAllPhotosWithAllCategorySelected() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        let state = latest()
        XCTAssertEqual(state?.photos.count, 5)
        // Chip lọc: "Tất cả" + 4 danh mục.
        XCTAssertEqual(state?.categories.count, 5)
        XCTAssertEqual(state?.categories.first?.isSelected, true)
        XCTAssertEqual(state?.categories.first?.category, nil)
        XCTAssertEqual(
            state?.subtitle,
            String(format: "photos.subtitle.count".localized, 5)
        )
    }

    func test_categorySelected_temple_filtersPhotosAndMovesSelection() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        categorySelectedSubject.send(.temple)

        XCTAssertEqual(mockUseCase.selectedCategories, [.temple])
        let state = latest()
        XCTAssertEqual(state?.photos.count, 2)
        XCTAssertEqual(state?.photos.map(\.categoryLabel), ["photos.category.temple".localized, "photos.category.temple".localized])

        let selectedChip = state?.categories.first { $0.isSelected }
        XCTAssertEqual(selectedChip?.category, .temple)

        XCTAssertEqual(
            state?.subtitle,
            String(format: "photos.subtitle.countCategory".localized, 2, "photos.category.temple".localized)
        )
    }

    func test_categorySelected_nil_resetsToAllPhotos() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())
        categorySelectedSubject.send(.festival)

        categorySelectedSubject.send(nil)

        XCTAssertEqual(mockUseCase.selectedCategories, [.festival, nil])
        let state = latest()
        XCTAssertEqual(state?.photos.count, 5)
        XCTAssertEqual(state?.categories.first?.isSelected, true)
    }

    func test_backTapped_firesBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILPhotosNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }
}

// MARK: - Mock ILPhotosUseCase
/// Catalog cố định 5 ảnh: 2 chùa, 1 tượng Phật, 1 cảnh thiền, 1 lễ hội — đủ để test lọc theo
/// danh mục mà không cần dựng cả 12 ảnh.
final class MockILPhotosUseCase: ILPhotosUseCase {
    var getInitialStateCalled = false
    var selectedCategories: [ILPhotosCategory?] = []

    private static func makePhoto(
        _ id: String,
        category: ILPhotosCategory,
        height: Double = 180
    ) -> ILPhotosPhotoEntity {
        ILPhotosPhotoEntity(id: id, category: category, title: id, place: "place", imageHeight: height)
    }

    private static var catalog: [ILPhotosPhotoEntity] {
        [
            makePhoto("pg-1", category: .temple),
            makePhoto("pg-2", category: .buddhaStatue),
            makePhoto("pg-3", category: .meditation),
            makePhoto("pg-4", category: .temple),
            makePhoto("pg-8", category: .festival)
        ]
    }

    func getInitialState() -> ILPhotosEntity {
        getInitialStateCalled = true
        return ILPhotosEntity(photos: Self.catalog, selectedCategory: nil)
    }

    func selectCategory(_ category: ILPhotosCategory?, in entity: ILPhotosEntity) -> ILPhotosEntity {
        selectedCategories.append(category)
        var updated = entity
        updated.selectedCategory = category
        return updated
    }

    func filteredPhotos(in entity: ILPhotosEntity) -> [ILPhotosPhotoEntity] {
        guard let category = entity.selectedCategory else { return entity.photos }
        return entity.photos.filter { $0.category == category }
    }
}
