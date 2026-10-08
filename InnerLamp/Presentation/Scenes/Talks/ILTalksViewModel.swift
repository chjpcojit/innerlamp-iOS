//
//  ILTalksViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILTalksNavEvent: Equatable {
    /// Nút ‹ ở header — đóng màn danh sách.
    case back
    /// Chạm 1 thẻ — mở màn Pháp thoại theo `id`.
    case openTalk(id: String)
}

protocol ILTalksViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILTalksCoordinator` subscribe trực tiếp trong `start()`.
    var navigationEventPublisher: AnyPublisher<ILTalksNavEvent, Never> { get }
}

final class ILTalksViewModel: ILTalksViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let filterSelected: AnyPublisher<ILTalkFilter, Never>
        let talkTapped: AnyPublisher<String, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILTalksStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILTalksNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILTalksNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILTalksStateModel>, Never>(.idle)
    private var talks: [ILTalkListItemEntity] = []
    /// Chip đang chọn — UI state, giữ ở ViewModel (không đưa lên Entity).
    private var filter: ILTalkFilter = .all
    private let useCase: ILTalksUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILTalksUseCase) {
        self.useCase = useCase
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in
                guard let self else { return }
                self.talks = self.useCase.getTalks()
                self.publishState()
            }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.filterSelected
            .sink { [weak self] filter in
                self?.filter = filter
                self?.publishState()
            }
            .store(in: &cancellables)

        input.talkTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openTalk(id: id)) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Entity -> StateModel
    private func publishState() {
        let matches = useCase.filter(talks, by: filter)

        var state = ILTalksStateModel()
        state.headerTitle = "talks.header.title".localized
        state.subtitle = String(format: "talks.header.subtitleFormat".localized, talks.count)
        state.filters = ILTalkFilter.allCases.map { value in
            ILTalksFilterModel(
                id: Self.filterKey(value),
                label: String(format: Self.filterKey(value).localized, useCase.filter(talks, by: value).count),
                value: value,
                isSelected: value == filter
            )
        }
        state.items = matches.map { Self.makeItem(from: $0) }
        if matches.isEmpty {
            state.emptyTitle = "talks.empty.title".localized
            state.emptyMessage = "talks.empty.message".localized
        }
        stateSubject.send(.success(state))
    }

    private static func filterKey(_ filter: ILTalkFilter) -> String {
        switch filter {
        case .all: return "talks.filter.all"
        case .media(.audio): return "talks.filter.audio"
        case .media(.video): return "talks.filter.video"
        case .media(.text): return "talks.filter.text"
        }
    }

    private static func makeItem(from talk: ILTalkListItemEntity) -> ILTalksItemModel {
        let eyebrow: String
        let detail: String
        switch talk.mediaType {
        case .audio:
            eyebrow = "talks.eyebrow.audio".localized
            detail = talk.durationMinutes.map { String(format: "talks.meta.minutes".localized, $0) } ?? ""
        case .video:
            eyebrow = "talks.eyebrow.video".localized
            detail = "talks.meta.video".localized
        case .text:
            eyebrow = "talks.eyebrow.text".localized
            detail = talk.readMinutes.map { String(format: "talks.meta.readMinutes".localized, $0) } ?? ""
        }
        // Dòng meta bỏ trường rỗng để không thừa dấu "·".
        let meta = detail.isEmpty
            ? talk.speaker
            : String(format: "talks.meta.format".localized, talk.speaker, detail)
        return ILTalksItemModel(
            id: talk.id,
            mediaType: talk.mediaType,
            eyebrow: talk.season?.uppercased() ?? eyebrow,
            title: talk.title,
            metaText: meta,
            progress: talk.listenProgress,
            progressText: String(format: "talks.progress.format".localized, Int((talk.listenProgress * 100).rounded()))
        )
    }
}
