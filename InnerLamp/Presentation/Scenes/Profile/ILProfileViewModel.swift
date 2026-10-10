//
//  ILProfileViewModel.swift
//  InnerLamp
//

import Foundation
import CoreGraphics
import Combine

enum ILProfileNavEvent: Equatable {
    case editProfile
    case openStats
    case openAwards
    case openOffering
    case openDonate
    case openReminder
    case openMeritBook
    case openSettings
    case openNotifications
    case openFamilyTree
    case createFamilyTree
    case openCommunity(id: String)
}

protocol ILProfileViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILProfileCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILProfileNavEvent, Never> { get }
}

final class ILProfileViewModel: ILProfileViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let editProfileTapped: AnyPublisher<Void, Never>
        let statsTapped: AnyPublisher<Void, Never>
        let awardsTapped: AnyPublisher<Void, Never>
        let offeringTapped: AnyPublisher<Void, Never>
        let donateTapped: AnyPublisher<Void, Never>
        let reminderTapped: AnyPublisher<Void, Never>
        let meritBookTapped: AnyPublisher<Void, Never>
        let settingsTapped: AnyPublisher<Void, Never>
        let notificationsTapped: AnyPublisher<Void, Never>
        let familyTreeTapped: AnyPublisher<Void, Never>
        let createFamilyTreeTapped: AnyPublisher<Void, Never>
        let communityTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILProfileStateModel>, Never>
    }

    // MARK: - Constants
    /// Độ đậm ô nhật ký: ngày không ghi vẫn hiện mờ, ngày nhiều nhất đậm nhất (khớp prototype .12 → .92).
    private enum Heatmap {
        static let minAlpha: CGFloat = 0.12
        static let alphaSpan: CGFloat = 0.8
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILProfileNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILProfileNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILProfileStateModel>, Never>
    private var profile: ILProfileEntity
    private var currentState: ILProfileStateModel
    private let useCase: ILProfileUseCase
    private let bundle: Bundle
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILProfileUseCase, bundle: Bundle = .main) {
        self.useCase = useCase
        self.bundle = bundle
        let initialProfile = useCase.getProfile()
        self.profile = initialProfile
        let initialState = ILProfileViewModel.makeStateModel(profile: initialProfile, bundle: bundle)
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.editProfileTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.editProfile) }
            .store(in: &cancellables)

        input.statsTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openStats) }
            .store(in: &cancellables)

        input.awardsTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openAwards) }
            .store(in: &cancellables)

        input.offeringTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openOffering) }
            .store(in: &cancellables)

        input.donateTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openDonate) }
            .store(in: &cancellables)

        input.reminderTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openReminder) }
            .store(in: &cancellables)

        input.meritBookTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openMeritBook) }
            .store(in: &cancellables)

        input.settingsTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openSettings) }
            .store(in: &cancellables)

        input.notificationsTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openNotifications) }
            .store(in: &cancellables)

        input.familyTreeTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openFamilyTree) }
            .store(in: &cancellables)

        input.createFamilyTreeTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.createFamilyTree) }
            .store(in: &cancellables)

        input.communityTapped
            .sink { [weak self] _ in self?.handleCommunityTapped() }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        profile = useCase.getProfile()
        currentState = ILProfileViewModel.makeStateModel(profile: profile, bundle: bundle)
        stateSubject.send(.success(currentState))
    }

    private func handleCommunityTapped() {
        guard let community = profile.community else { return }
        navigationEventSubject.send(.openCommunity(id: community.id))
    }

    // MARK: - Entity -> StateModel mapping
    /// Việc riêng của presentation (format số, ghép câu phụ, chuẩn hóa độ đậm) nên nằm ở đây,
    /// không phải trong Mapper dùng chung (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(profile: ILProfileEntity, bundle: Bundle) -> ILProfileStateModel {
        var model = ILProfileStateModel()

        model.header = ILProfileHeaderModel(
            initial: initial(of: profile.fullName),
            fullName: profile.fullName,
            subtitle: makeSubtitle(dharmaName: profile.dharmaName),
            subtitleHighlight: profile.dharmaName.isEmpty ? nil : profile.dharmaName
        )

        model.stats = [
            ILProfileStatModel(
                value: String(profile.practiceStats.totalHours),
                caption: "profile.stats.hours".localized
            ),
            ILProfileStatModel(
                value: String(profile.practiceStats.streakDays),
                caption: "profile.stats.streak".localized
            ),
            ILProfileStatModel(
                value: formatCompactCount(profile.practiceStats.chantCount),
                caption: "profile.stats.chants".localized
            )
        ]

        if !profile.journalEntriesPerDay.isEmpty {
            let days = profile.journalEntriesPerDay
            let loggedDays = days.filter { $0 > 0 }.count
            model.heatmap = ILProfileHeatmapModel(
                summaryText: String(format: "profile.heatmap.summary".localized, loggedDays, days.count),
                intensities: makeIntensities(from: days)
            )
        }

        model.badgesLinkText = String(format: "profile.badges.seeAll".localized, profile.totalBadgeCount)
        model.badges = profile.recentBadges.map {
            ILProfileBadgeModel(id: $0.id, title: $0.title, subtitle: $0.subtitle, category: $0.category)
        }

        model.meritSummary = String(
            format: "profile.merit.summary".localized,
            profile.offeringCount,
            profile.lanternCount
        )
        model.reminderValue = formatReminder(profile.reminder)
        model.communityValue = profile.community?.name ?? "profile.menu.community.none".localized

        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        model.versionText = String(format: "profile.footer.version".localized, version)
        model.buildText = String(format: "profile.footer.build".localized, build)
        return model
    }

    /// "Pháp danh Tâm Minh · Phật tử tại gia"; chưa có pháp danh thì chỉ còn vai trò.
    private static func makeSubtitle(dharmaName: String) -> String {
        guard !dharmaName.isEmpty else { return "profile.header.role".localized }
        return String(format: "profile.header.subtitle".localized, dharmaName)
    }

    /// Chuẩn hóa số mục/ngày thành alpha ô: 0 → `minAlpha`, ngày nhiều nhất → `minAlpha + alphaSpan`.
    static func makeIntensities(from entriesPerDay: [Int]) -> [CGFloat] {
        let peak = CGFloat(max(entriesPerDay.max() ?? 0, 1))
        return entriesPerDay.map { Heatmap.minAlpha + Heatmap.alphaSpan * CGFloat(max($0, 0)) / peak }
    }

    /// Rút gọn số lớn kiểu "9.7k" (1 chữ số thập phân, bỏ ".0"); dưới 1000 giữ nguyên.
    static func formatCompactCount(_ count: Int) -> String {
        guard count >= 1_000 else { return String(count) }
        let thousands = String(format: "%.1f", Double(count) / 1_000)
        return (thousands.hasSuffix(".0") ? String(thousands.dropLast(2)) : thousands) + "k"
    }

    /// "05:30 · 6 ngày mỗi tuần" / "05:30 · mỗi ngày"; chưa đặt chuông thì "Chưa đặt".
    static func formatReminder(_ reminder: ILProfileReminderEntity?) -> String {
        guard let reminder else { return "profile.menu.reminder.none".localized }
        let time = String(format: "%02d:%02d", reminder.hour, reminder.minute)
        let days = reminder.activeDayCount >= 7
            ? "profile.menu.reminder.everyDay".localized
            : String(format: "profile.menu.reminder.daysPerWeek".localized, reminder.activeDayCount)
        return String(format: "profile.menu.reminder.summary".localized, time, days)
    }

    /// Chữ cái đầu của tên gọi (từ cuối) — "Nguyễn Bình An" → "A".
    static func initial(of name: String) -> String {
        guard let lastWord = name.split(separator: " ").last, let first = lastWord.first else { return "" }
        return String(first).uppercased()
    }
}
