//
//  ILSutraDetailViewModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation
import Combine

enum ILSutraDetailNavEvent: Equatable {
    /// Nút ‹ ở header ghim — đóng màn Chi tiết bài kinh.
    case back
    /// Nút "Tụng theo" hoặc chạm 1 phẩm trong Mục lục — mở màn Tụng kinh (`reader`).
    case openReader
    /// Nút "Tải về máy" ở header ghim — mở màn nghe không cần mạng (màn `downloads` chưa build).
    case download
    /// Nút phát tròn ở thanh CTA đáy — mở trình phát toàn màn (màn `player` chưa build).
    case openPlayer
    /// Chạm 1 hàng liên kết (nguồn / giấy phép) — mở trình duyệt.
    case openLink(URL)
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
        /// Chạm 1 hàng có liên kết trong các khối thông tin.
        let linkTapped: AnyPublisher<URL, Never>
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
    private let useCase: ILSutraDetailUseCase
    private let sutraID: String
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILSutraDetailUseCase, sutraID: String) {
        self.useCase = useCase
        self.sutraID = sutraID
        self.stateSubject = CurrentValueSubject(.idle)
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

        input.linkTapped
            .sink { [weak self] url in self?.navigationEventSubject.send(.openLink(url)) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    /// Loads `GET /v1/sutras/{id}`. On failure the error is surfaced (`.notFound` for an unknown id).
    private func handleViewDidLoad() {
        stateSubject.send(.loading)
        Task { [weak self] in
            guard let self else { return }
            do {
                let entity = try await self.useCase.loadSutra(id: self.sutraID)
                self.stateSubject.send(.success(Self.makeStateModel(from: entity)))
            } catch {
                self.stateSubject.send(.failure(error))
            }
        }
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` là việc riêng của presentation (format "73 dòng · 5 phút", dòng kicker,
    /// nhãn chip, dòng nguồn / giấy phép) nên nằm ở đây, không phải trong Mapper dùng chung.
    private static func makeStateModel(from entity: ILSutraDetailEntity) -> ILSutraDetailStateModel {
        var state = ILSutraDetailStateModel()

        if let sutra = entity.sutra {
            state.kicker = kicker(for: sutra)
            state.title = sutra.title
            state.originalName = sutra.originalTitle
            state.metaText = metaText(for: sutra)
            // @ai: assumption — see Docs/Assumptions/SutraDetail/AS-SutraDetail-001-metadata-lines-and-license.md
            state.descriptionText = [sutra.collection, sutra.reference]
                .filter { !$0.isEmpty }
                .joined(separator: "sutraDetail.descriptionSeparator".localized)
            state.infoSections = infoSections(for: sutra)
            state.tags = tagModels(for: sutra)
            state.tocCountText = sutra.chapters.isEmpty
                ? ""
                : String(format: "sutraDetail.tocCount.chapters".localized, sutra.chapters.count)
            state.chapters = sutra.chapters.map { chapterModel(from: $0) }
            // @ai: the API has no audio / reading-progress data — see
            // Docs/Tech-Debt/SutraDetail/TD-SutraDetail-001-*.md
            state.hasAudio = false
            state.chantButtonTitle = "sutraDetail.read".localized
        }

        state.tocTitle = "sutraDetail.tocTitle".localized
        state.downloadButtonTitle = "sutraDetail.download".localized

        return state
    }

    /// "THẦN CHÚ · BẮC TÔNG" / "KINH VĂN · NAM TÔNG" (design `su.kicker`); either part is dropped
    /// when the server value is unknown.
    private static func kicker(for sutra: ILSutraDetailSutraEntity) -> String {
        let kind: String? = switch sutra.kind {
        case .sutra: "sutraDetail.kicker.sutra".localized
        case .verse: "sutraDetail.kicker.verse".localized
        case .dharani: "sutraDetail.kicker.mantra".localized
        case nil: nil
        }
        let tradition = sutra.tradition.map { ILSutrasViewModel.categoryLabel(.tradition($0)) }
        return [kind, tradition].compactMap { $0 }
            .joined(separator: "sutraDetail.kickerSeparator".localized)
            .uppercased()
    }

    /// "73 dòng · ~5 phút" (design `su.metaLine`); the duration is dropped when the server has no
    /// estimate.
    private static func metaText(for sutra: ILSutraDetailSutraEntity) -> String {
        var parts = [String(format: "sutraDetail.lineCountFormat".localized, sutra.lineCount)]
        if let minutes = sutra.durationMinutes {
            parts.append(formatDuration(minutes: minutes))
        }
        return parts.joined(separator: "sutraDetail.metaSeparator".localized)
    }

    /// Summary → information → translation & license → unreviewed notice. Empty values are dropped and
    /// a section without rows is omitted (the backend asks the client to always show the translator
    /// and license when present).
    /// @ai: assumption — see Docs/Assumptions/SutraDetail/AS-SutraDetail-002-extra-api-fields-default-labels.md
    private static func infoSections(for sutra: ILSutraDetailSutraEntity) -> [ILSutraDetailInfoSectionModel] {
        func row(_ labelKey: String, _ value: String) -> ILSutraDetailInfoRowModel? {
            value.isEmpty ? nil : ILSutraDetailInfoRowModel(label: labelKey.localized, value: value, url: nil)
        }
        func linkRow(_ labelKey: String, _ link: String?) -> ILSutraDetailInfoRowModel? {
            guard let link, let url = URL(string: link) else { return nil }
            return ILSutraDetailInfoRowModel(label: labelKey.localized, value: link, url: url)
        }

        var infoRows: [ILSutraDetailInfoRowModel?] = sutra.alternateTitles.map {
            ILSutraDetailInfoRowModel(
                label: String(format: "sutraDetail.info.altTitle".localized, languageName($0.language)),
                value: $0.text,
                url: nil
            )
        }
        infoRows.append(row("sutraDetail.info.author", sutra.author))
        infoRows.append(row("sutraDetail.info.hanTranslator", hanTranslatorText(for: sutra)))
        infoRows.append(row("sutraDetail.info.referenceNote", sutra.referenceNote))
        infoRows += sutra.deities.map {
            ILSutraDetailInfoRowModel(label: deityRoleLabel($0.role), value: $0.name, url: nil)
        }

        let translationRows: [ILSutraDetailInfoRowModel?] = [
            row("sutraDetail.translation.variant", variantLabel(sutra.variant)),
            row("sutraDetail.translation.translator", sutra.translator),
            row("sutraDetail.translation.source", sutra.sourceName),
            linkRow("sutraDetail.translation.sourceLink", sutra.sourceURL),
            row("sutraDetail.translation.license", sutra.license),
            row("sutraDetail.translation.licenseNote", sutra.licenseNote),
            linkRow("sutraDetail.translation.licenseLink", sutra.licenseURL),
            row("sutraDetail.translation.note", sutra.note)
        ]

        let paragraph: (String) -> [ILSutraDetailInfoRowModel] = {
            $0.isEmpty ? [] : [ILSutraDetailInfoRowModel(label: "", value: $0, url: nil)]
        }
        let sections: [(titleKey: String, rows: [ILSutraDetailInfoRowModel])] = [
            ("sutraDetail.section.summary", paragraph(sutra.summary)),
            ("sutraDetail.section.info", infoRows.compactMap { $0 }),
            ("sutraDetail.section.translation", translationRows.compactMap { $0 }),
            ("sutraDetail.section.notice", paragraph(sutra.isUnreviewed ? "sutraDetail.notice.unreviewed".localized : ""))
        ]
        return sections
            .filter { !$0.rows.isEmpty }
            .map { ILSutraDetailInfoSectionModel(title: $0.titleKey.localized, rows: $0.rows) }
    }

    /// "Nghĩa Tịnh · 703" — the translator, plus the year when the server has one.
    private static func hanTranslatorText(for sutra: ILSutraDetailSutraEntity) -> String {
        guard !sutra.hanTranslator.isEmpty else { return "" }
        guard let year = sutra.hanTranslationYear else { return sutra.hanTranslator }
        return String(format: "sutraDetail.info.hanTranslatorYear".localized, sutra.hanTranslator, year)
    }

    private static func deityRoleLabel(_ role: ILSutraDeityRole?) -> String {
        switch role {
        case .speaker: "sutraDetail.deityRole.speaker".localized
        case .subject: "sutraDetail.deityRole.subject".localized
        case .mentioned: "sutraDetail.deityRole.mentioned".localized
        case nil: "sutraDetail.deityRole.other".localized
        }
    }

    private static func variantLabel(_ variant: ILSutraTranslationVariant?) -> String {
        switch variant {
        case .translation: "sutraDetail.variant.translation".localized
        case .chant: "sutraDetail.variant.chant".localized
        case .meaning: "sutraDetail.variant.meaning".localized
        case .poem: "sutraDetail.variant.poem".localized
        case nil: ""
        }
    }

    /// `pli` → "Pāli"; a language the app does not know shows its upper-cased code.
    private static func languageName(_ code: String) -> String {
        let key = "sutraDetail.language.\(code)"
        let name = key.localized
        return name == key ? code.uppercased() : name
    }

    /// "Tụng hằng ngày" chip, then one chip per purpose (design `su.chips`).
    private static func tagModels(for sutra: ILSutraDetailSutraEntity) -> [ILSutraDetailTagModel] {
        var titles = sutra.isDailyChant ? [ILSutrasViewModel.categoryLabel(.dailyChant)] : []
        titles += sutra.purposes.map { ILSutrasViewModel.categoryLabel(.purpose($0)) }
        return titles.map { ILSutraDetailTagModel(title: $0, isFilled: false) }
    }

    private static func chapterModel(from chapter: ILSutraDetailChapterEntity) -> ILSutraDetailChapterModel {
        ILSutraDetailChapterModel(
            id: chapter.id,
            number: chapter.number,
            title: chapter.title,
            subtitle: String(format: "sutraDetail.chapter.lineCount".localized, chapter.lineCount),
            // @ai: the API has no per-section duration — see TD-SutraDetail-001
            durationText: "",
            isCurrent: false
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
