//
//  ILFestivalDetailViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILFestivalDetailNavEvent: Equatable {
    /// Nút ‹ ở header — đóng màn chi tiết ngày lễ.
    case back
}

protocol ILFestivalDetailViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILFestivalDetailCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILFestivalDetailNavEvent, Never> { get }
}

/// Màn "Chi tiết ngày lễ". `viewDidLoad` tải sự kiện + lần xuất hiện từ server qua
/// `ILFestivalDetailUseCase`: state đi `.loading` → `.success` (hoặc `.failure`, `retryTapped`
/// tải lại).
final class ILFestivalDetailViewModel: ILFestivalDetailViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        /// "Thử lại" ở trạng thái lỗi.
        let retryTapped: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILFestivalDetailStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILFestivalDetailNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILFestivalDetailNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILFestivalDetailStateModel>, Never>(.idle)
    private let useCase: ILFestivalDetailUseCase
    private let eventCode: String
    private let date: Date
    private var loadTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILFestivalDetailUseCase, eventCode: String, date: Date) {
        self.useCase = useCase
        self.eventCode = eventCode
        self.date = date
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.load() }
            .store(in: &cancellables)

        input.retryTapped
            .sink { [weak self] _ in self?.load() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func load() {
        loadTask?.cancel()
        stateSubject.send(.loading)
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let entity = try await self.useCase.loadDetail(code: self.eventCode, date: self.date, today: Date())
                guard !Task.isCancelled else { return }
                self.stateSubject.send(.success(Self.makeStateModel(from: entity)))
            } catch {
                guard !Task.isCancelled else { return }
                self.stateSubject.send(.failure(error))
            }
        }
    }

    // MARK: - Entity -> StateModel mapping
    static func makeStateModel(from entity: ILFestivalDetailEntity) -> ILFestivalDetailStateModel {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: entity.date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        let weekday = components.weekday ?? 1 // 1 = Chủ nhật ... 7 = Thứ Bảy

        var model = ILFestivalDetailStateModel()

        model.imageURL = entity.imageURL
        model.imageEmptyText = "festivalDetail.image.empty".localized

        // BR-CAL-10: major mark first, then the group names; nothing to show → the row is hidden.
        let kindParts = (entity.isMajor ? ["festivals.tab.major".localized] : []) + entity.groupNames
        model.kindText = kindParts.joined(separator: " · ").uppercased()
        model.title = entity.name
        model.lunarText = String(
            format: "festivalDetail.lunar.format".localized,
            entity.lunarDay,
            ILLunarCalendar.lunarMonthLabel(entity.lunarMonth, isLeap: entity.isLeapMonth)
        )

        // Mô tả dài, mỗi dòng một đoạn.
        let longParagraphs = paragraphs(from: entity.longDescription)
        // BR-CAL-14: an empty long description is not replaced by the short one (section hidden).
        model.aboutParagraphs = longParagraphs

        model.dayText = String(format: "%02d", day)
        let weekdayText = weekday == 1
            ? "festivals.weekday.sunday".localized
            : String(format: "festivals.weekday.format".localized, weekday)
        model.dateText = "\(weekdayText), " + String(format: "festivals.month.labelYear".localized, month, year)
        model.dateCaption = String(format: "festivalDetail.date.caption".localized, year)
        model.countdownText = countdownText(entity.daysUntil)

        model.practicesTitle = "festivalDetail.practices.title".localized
        model.practices = paragraphs(from: entity.guidance).map(stripListMarker)


        return model
    }

    /// Tách theo dòng, bỏ dòng trống.
    private static func paragraphs(from text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Bỏ ký tự đầu dòng danh sách ("- ", "• ") — hàng thực hành đã có số thứ tự riêng.
    private static func stripListMarker(_ line: String) -> String {
        guard let first = line.first, "-•*".contains(first) else { return line }
        return line.dropFirst().trimmingCharacters(in: .whitespaces)
    }

    private static func countdownText(_ days: Int) -> String {
        switch days {
        case ..<0: return "festivals.item.countdown.past".localized
        case 0: return "festivals.item.countdown.today".localized
        case 1: return "festivals.item.countdown.tomorrow".localized
        default: return String(format: "festivalDetail.countdown.days".localized, days)
        }
    }
}
