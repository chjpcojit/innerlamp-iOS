//
//  ILSutraDetailViewModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation
import Combine

enum ILSutraDetailNavEvent: Equatable {
    /// Nút ‹ ở hero — đóng màn Chi tiết bài kinh.
    case back
    /// Nút "Tụng theo" hoặc chạm 1 phẩm trong Mục lục — mở màn Tụng kinh (`reader`).
    case openReader
    /// Nút "Tải về máy" ở hero — mở màn nghe không cần mạng (màn `downloads` chưa build).
    case download
    /// Nút phát tròn ở thanh CTA đáy — mở trình phát toàn màn (màn `player` chưa build).
    case openPlayer
}

protocol ILSutraDetailViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILSutraDetailCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILSutraDetailNavEvent, Never> { get }
}

final class ILSutraDetailViewModel: ILSutraDetailViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let downloadTapped: AnyPublisher<Void, Never>
        let chantTapped: AnyPublisher<Void, Never>
        let playTapped: AnyPublisher<Void, Never>
        /// Chạm 1 phẩm trong Mục lục — cùng đích với "Tụng theo" (màn `reader`).
        let chapterTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILSutraDetailStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILSutraDetailNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILSutraDetailNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILSutraDetailStateModel>, Never>
    private var currentEntity: ILSutraDetailEntity
    private var currentState: ILSutraDetailStateModel
    private let useCase: ILSutraDetailUseCase
    private let initialSutraID: String
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILSutraDetailUseCase, sutraID: String) {
        self.useCase = useCase
        self.initialSutraID = sutraID
        let initialEntity = useCase.getInitialState(sutraID: sutraID)
        self.currentEntity = initialEntity
        self.currentState = Self.makeStateModel(from: initialEntity, useCase: useCase)
        self.stateSubject = CurrentValueSubject(.success(currentState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.downloadTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.download) }
            .store(in: &cancellables)

        input.chantTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openReader) }
            .store(in: &cancellables)

        input.playTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openPlayer) }
            .store(in: &cancellables)

        input.chapterTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openReader) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState(sutraID: initialSutraID))
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` là việc riêng của presentation (format "26 phẩm · 423 kệ · ...",
    /// "Kệ 1 – 20 · đang tụng", "9 phút", "34%", nhãn chip) nên nằm ở đây, không phải trong Mapper
    /// dùng chung (xem `references/data_layer_boundaries.md`).
    private func applyEntity(_ entity: ILSutraDetailEntity) {
        currentEntity = entity
        currentState = Self.makeStateModel(from: entity, useCase: useCase)
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(
        from entity: ILSutraDetailEntity,
        useCase: ILSutraDetailUseCase
    ) -> ILSutraDetailStateModel {
        var state = ILSutraDetailStateModel()

        if let sutra = useCase.currentSutra(in: entity) {
            state.kicker = sutra.kicker
            state.title = sutra.title
            state.metaText = String(
                format: "sutraDetail.metaFormat".localized,
                sutra.numberOfChapters,
                sutra.numberOfVerses,
                sutra.narrator,
                formatDuration(minutes: sutra.durationMinutes)
            )
            state.descriptionText = sutra.description
            state.tags = sutra.tags.map { tagModel(for: $0) }
            state.tocCountText = String(format: "sutraDetail.tocCount".localized, sutra.numberOfChapters)
            state.chapters = sutra.chapters.map { chapter in
                chapterModel(from: chapter, isCurrent: chapter.id == entity.currentChapterID)
            }

            if let current = sutra.chapters.first(where: { $0.id == entity.currentChapterID }) {
                state.progressTitle = String(
                    format: "sutraDetail.progress.title".localized,
                    current.title,
                    current.verseStart
                )
            }
        }

        let percent = Int((entity.readingProgress * 100).rounded())
        state.progressPercentText = String(format: "sutraDetail.progress.percent".localized, percent)
        state.progressValue = entity.readingProgress

        state.tocTitle = "sutraDetail.tocTitle".localized
        state.downloadButtonTitle = "sutraDetail.download".localized
        state.chantButtonTitle = "sutraDetail.chant".localized

        return state
    }

    private static func tagModel(for tag: ILSutraDetailTag) -> ILSutraDetailTagModel {
        switch tag {
        case .daily:
            return ILSutraDetailTagModel(title: "sutraDetail.tag.daily".localized, isFilled: true)
        case .phonetic:
            return ILSutraDetailTagModel(title: "sutraDetail.tag.phonetic".localized, isFilled: false)
        }
    }

    private static func chapterModel(
        from chapter: ILSutraDetailChapterEntity,
        isCurrent: Bool
    ) -> ILSutraDetailChapterModel {
        var subtitle = String(
            format: "sutraDetail.chapter.verseRange".localized,
            chapter.verseStart,
            chapter.verseEnd
        )
        if isCurrent {
            subtitle += "sutraDetail.chapter.currentSuffix".localized
        }
        return ILSutraDetailChapterModel(
            id: chapter.id,
            number: chapter.number,
            title: chapter.title,
            subtitle: subtitle,
            durationText: String(format: "sutraDetail.chapter.duration".localized, chapter.durationMinutes),
            isCurrent: isCurrent
        )
    }

    /// 130 → "2 giờ 10 phút" (bỏ phần phút nếu tròn giờ, bỏ giờ nếu dưới 1 giờ).
    static func formatDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 {
            return String(format: "sutraDetail.duration.minutes".localized, remainder)
        }
        if remainder == 0 {
            return String(format: "sutraDetail.duration.hours".localized, hours)
        }
        return String(format: "sutraDetail.duration.hoursMinutes".localized, hours, remainder)
    }
}
