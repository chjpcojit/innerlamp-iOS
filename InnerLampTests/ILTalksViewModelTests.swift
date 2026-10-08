//
//  ILTalksViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILTalksViewModelTests: XCTestCase {

    private var sut: ILTalksViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var filterSelectedSubject: PassthroughSubject<ILTalkFilter, Never>!
    private var talkTappedSubject: PassthroughSubject<String, Never>!

    override func setUp() {
        super.setUp()
        sut = ILTalksViewModel(useCase: ILTalksUseCaseImpl())
        cancellables = []
        viewDidLoadSubject = PassthroughSubject()
        backTappedSubject = PassthroughSubject()
        filterSelectedSubject = PassthroughSubject()
        talkTappedSubject = PassthroughSubject()
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        super.tearDown()
    }

    private func bind() -> () -> ILTalksStateModel? {
        let output = sut.transform(input: ILTalksViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            filterSelected: filterSelectedSubject.eraseToAnyPublisher(),
            talkTapped: talkTappedSubject.eraseToAnyPublisher()
        ))
        var latest: ILTalksStateModel?
        output.state
            .sink { if case .success(let model) = $0 { latest = model } }
            .store(in: &cancellables)
        return { latest }
    }

    func test_viewDidLoad_showsAllTalksWithCountsOnChips() {
        let latest = bind()
        viewDidLoadSubject.send(())

        let state = latest()
        XCTAssertEqual(state?.items.count, 8)
        XCTAssertEqual(state?.subtitle, String(format: "talks.header.subtitleFormat".localized, 8))
        XCTAssertEqual(state?.filters.map(\.label), [
            String(format: "talks.filter.all".localized, 8),
            String(format: "talks.filter.audio".localized, 5),
            String(format: "talks.filter.video".localized, 1),
            String(format: "talks.filter.text".localized, 2)
        ])
        XCTAssertEqual(state?.filters.filter(\.isSelected).map(\.value), [.all])
    }

    func test_filterSelected_filtersByMediaType() {
        let latest = bind()
        viewDidLoadSubject.send(())
        filterSelectedSubject.send(.media(.text))

        XCTAssertEqual(latest()?.items.map(\.id), ["talk.mock.hieuhanh", "talk.mock.rambaythang"])
        XCTAssertEqual(latest()?.subtitle, String(format: "talks.header.subtitleFormat".localized, 8))
    }

    func test_items_formatEyebrowMetaAndProgress() {
        let latest = bind()
        viewDidLoadSubject.send(())

        let items = latest()?.items ?? []
        XCTAssertEqual(items.first?.eyebrow, "MÙA VU LAN")
        XCTAssertEqual(items.first?.metaText, "Thầy Minh Đạo · 46 phút")
        XCTAssertEqual(items.first?.progressText, "Đang nghe dở · 28%")
        XCTAssertEqual(items[1].eyebrow, "BÀI GIẢNG")
        XCTAssertEqual(items[1].progress, 0)
        XCTAssertEqual(items[2].eyebrow, "VIDEO")
        XCTAssertEqual(items[2].metaText, "Thiền sư Thích Nhất Hạnh · Video")
        XCTAssertEqual(items[3].metaText, "Thầy Minh Đạo · 8 phút đọc")
    }

    func test_talkTapped_emitsOpenTalk() {
        _ = bind()
        var events: [ILTalksNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)

        talkTappedSubject.send("talk.vulan.hieu")

        XCTAssertEqual(events, [.openTalk(id: "talk.vulan.hieu")])
    }

    func test_backTapped_emitsBack() {
        _ = bind()
        var events: [ILTalksNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(events, [.back])
    }
}
