//
//  ILSanghaViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILSanghaNavEvent: Equatable {
    /// Mở Trang chùa của `id` (thẻ chùa tu tập hoặc hàng "Chùa gần bạn").
    case openTemple(id: String)
    /// "Tất cả" ở "Khóa tu & lễ sắp tới" hoặc chạm 1 khóa tu — màn Sự kiện & khóa học.
    case openEvents
    case openTalk(id: String)
    /// "Công đức · cúng dường" (màn Cúng dường chưa build).
    case openOffer
    /// "Đổi chùa" — mở màn "Chọn chùa tu tập".
    case openTempleFinder
    /// Chạm 1 buổi tu học trực tuyến (màn đích chưa build).
    case openOnlineSession(id: String)
    /// "Lịch lễ" hoặc chạm 1 ngày lễ — màn Lịch lễ Phật giáo.
    case openFestivals
}

protocol ILSanghaViewModelProtocol: ViewModelType {
    var navigationEventPublisher: AnyPublisher<ILSanghaNavEvent, Never> { get }
}

/// Tab Chùa — chùa người dùng đang tu tập (chùa tự chọn trong app, nếu không thì chùa trong hồ sơ
/// tài khoản); nội dung còn lại là dữ liệu mẫu, không có loading / lỗi mạng. Có chùa: thẻ chùa, thông báo, khóa tu & lễ sắp tới,
/// pháp thoại, cúng dường, số Phật tử. Chưa có: chùa gần bạn (chọn), chùa trực tuyến, khóa tu.
/// Cả hai trạng thái đều có khối "Ngày lễ & ngày chay sắp tới".
final class ILSanghaViewModel: ILSanghaViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        /// Mỗi lần tab hiện lại (kể cả lần đầu) — nạp lại để thấy chùa vừa đổi ở màn "Chọn chùa tu tập".
        let viewWillAppear: AnyPublisher<Void, Never>
        /// "Đổi chùa" — mở màn "Chọn chùa tu tập".
        let changeTempleTapped: AnyPublisher<Void, Never>
        let myTempleTapped: AnyPublisher<Void, Never>
        /// "Tất cả" / chạm 1 khóa tu / chạm 1 khóa tu ở trạng thái chưa chọn.
        let eventsTapped: AnyPublisher<Void, Never>
        /// Nút pill của 1 khóa tu — mang theo `id` khóa tu.
        let eventActionTapped: AnyPublisher<String, Never>
        /// Chạm 1 pháp thoại — mang theo `talkID`.
        let talkTapped: AnyPublisher<String, Never>
        let offerTapped: AnyPublisher<Void, Never>
        /// Chạm hàng "Chùa gần bạn" — mở Trang chùa.
        let nearbyTempleTapped: AnyPublisher<String, Never>
        /// "Chọn" ở hàng "Chùa gần bạn" — đặt làm chùa tu tập.
        let pickTapped: AnyPublisher<String, Never>
        let onlineSessionTapped: AnyPublisher<String, Never>
        let festivalsTapped: AnyPublisher<Void, Never>
        /// Nút "Nhắc tôi" của 1 ngày lễ — mang theo `id` ngày.
        let dayReminderTapped: AnyPublisher<String, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILSanghaStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILSanghaNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILSanghaNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILSanghaStateModel>, Never>(.idle)
    private let useCase: ILSanghaUseCase
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?

    private var myTemple: ILSanghaMyTempleEntity?
    private var chooser: ILSanghaChooserEntity?
    private var days: [ILFestivalDayEntity] = []
    /// Nút "Nhắc tôi" / "Giữ chỗ" đang bật — chỉ là trạng thái hiển thị, chưa lưu (xem TD-Sangha-001).
    private var activeEventIDs = Set<String>()
    private var remindedDayIDs = Set<String>()

    private static let upcomingDaysLimit = 4
    /// Hiển thị cố định như prototype (`chHere`) — chưa có định vị thật.
    private static let mockLocationName = "Quận 1, TP. Hồ Chí Minh"

    // MARK: - Initializer
    init(useCase: ILSanghaUseCase, now: @escaping () -> Date = Date.init) {
        self.useCase = useCase
        self.now = now
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.load() }
            .store(in: &cancellables)

        input.viewWillAppear
            .sink { [weak self] _ in self?.load() }
            .store(in: &cancellables)

        input.changeTempleTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openTempleFinder) }
            .store(in: &cancellables)

        input.myTempleTapped
            .sink { [weak self] _ in
                guard let id = self?.myTemple?.temple.id else { return }
                self?.navigationEventSubject.send(.openTemple(id: id))
            }
            .store(in: &cancellables)

        input.eventsTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openEvents) }
            .store(in: &cancellables)

        input.eventActionTapped
            .sink { [weak self] id in
                guard let self else { return }
                if activeEventIDs.contains(id) { activeEventIDs.remove(id) } else { activeEventIDs.insert(id) }
                publishState()
            }
            .store(in: &cancellables)

        input.talkTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openTalk(id: id)) }
            .store(in: &cancellables)

        input.offerTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openOffer) }
            .store(in: &cancellables)

        input.nearbyTempleTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openTemple(id: id)) }
            .store(in: &cancellables)

        input.pickTapped
            .sink { [weak self] id in
                self?.useCase.selectMyTemple(id: id)
                self?.load()
            }
            .store(in: &cancellables)

        input.onlineSessionTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openOnlineSession(id: id)) }
            .store(in: &cancellables)

        input.festivalsTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openFestivals) }
            .store(in: &cancellables)

        input.dayReminderTapped
            .sink { [weak self] id in
                guard let self else { return }
                if remindedDayIDs.contains(id) { remindedDayIDs.remove(id) } else { remindedDayIDs.insert(id) }
                publishState()
            }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Loading
    /// Chùa tu tập có thể cần gọi mạng (hồ sơ tài khoản) nên nạp bất đồng bộ; nội dung đang hiển thị
    /// được giữ nguyên cho tới khi có kết quả mới, lần nạp cũ còn dở bị hủy.
    private func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            let loadedTemple = await useCase.loadMyTemple()
            guard !Task.isCancelled else { return }
            myTemple = loadedTemple
            chooser = loadedTemple == nil ? useCase.loadChooser() : nil
            days = useCase.loadUpcomingDays(limit: Self.upcomingDaysLimit)
            publishState()
        }
    }

    private func publishState() {
        var model = ILSanghaStateModel()
        model.myTemple = myTemple.map(makeMyTempleModel)
        model.chooser = chooser.map(makeChooserModel)
        model.days = days.map { makeDayRow($0, templeName: myTemple?.temple.name) }
        stateSubject.send(.success(model))
    }

    // MARK: - Entity -> StateModel mapping
    private func makeMyTempleModel(_ content: ILSanghaMyTempleEntity) -> ILSanghaMyTempleModel {
        let temple = content.temple
        let name = temple.name
        let status = Self.status(operatingHours: temple.operatingHours, now: now())
        let abbot = temple.abbot.isEmpty ? "sangha.abbot.unknown".localized : temple.abbot

        return ILSanghaMyTempleModel(
            id: temple.id,
            name: name,
            place: temple.address,
            imageURL: temple.imageURL,
            statusText: status?.text ?? "",
            isOpen: status?.isOpen ?? false,
            abbotText: String(format: "sangha.abbot.format".localized, abbot),
            announcements: content.announcements.map {
                ILSanghaAnnouncementRowModel(id: $0.id, timeText: Self.relativeDay(from: $0.postedAt, now: now()), text: $0.text)
            },
            events: content.events.map { makeEventRow($0) },
            talks: content.talks.enumerated().map { index, talk in
                ILSanghaTalkRowModel(
                    id: index,
                    talkID: talk.id,
                    title: talk.title,
                    subtitle: String(format: "sangha.talk.subtitle".localized, talk.speaker, talk.durationMinutes)
                )
            },
            offerSubtitle: String(format: "sangha.offer.subtitle".localized, name),
            peersText: String(
                format: "sangha.peers.format".localized,
                Self.formatCount(content.practitionerCount), name, content.upcomingRetreatAttendeeCount
            )
        )
    }

    private func makeChooserModel(_ content: ILSanghaChooserEntity) -> ILSanghaChooserModel {
        ILSanghaChooserModel(
            locationText: Self.mockLocationName,
            nearby: content.nearbyTemples.map {
                ILSanghaNearbyRowModel(
                    id: $0.id, name: $0.name,
                    subtitle: String(format: "sangha.nearby.subtitle".localized, $0.address, Self.formatDistance($0.distanceKm))
                )
            },
            online: content.onlineSessions.map {
                ILSanghaOnlineRowModel(
                    id: $0.id, schedule: $0.schedule, isDaily: $0.isDaily, title: $0.title, subtitle: $0.detail
                )
            },
            retreats: content.retreats.map { makeEventRow($0) }
        )
    }

    private func makeEventRow(_ event: ILSanghaEventEntity) -> ILSanghaEventRowModel {
        let calendar = Calendar(identifier: .gregorian)
        let isOn = activeEventIDs.contains(event.id)
        let label: String?
        switch event.action {
        case .remind: label = (isOn ? "sangha.action.reminded" : "sangha.action.remind").localized
        case .reserve: label = (isOn ? "sangha.action.reserved" : "sangha.action.reserve").localized
        case .none: label = nil
        }
        return ILSanghaEventRowModel(
            id: event.id,
            dayNumber: String(format: "%02d", calendar.component(.day, from: event.date)),
            monthLabel: Self.monthLabel(event.date, calendar: calendar),
            title: event.title,
            subtitle: event.detail,
            actionLabel: label,
            isActionOn: isOn,
            isGoldAction: event.action == .remind
        )
    }

    private func makeDayRow(_ day: ILFestivalDayEntity, templeName: String?) -> ILSanghaDayRowModel {
        let calendar = Calendar(identifier: .gregorian)
        let base = ILFestivalsViewModel.makeDayModel(day)
        let lunar = ILLunarCalendar.solarToLunar(date: day.date, calendar: calendar)
        let isReminded = remindedDayIDs.contains(day.id)

        var subtitle = String(format: "festivals.item.lunarDateFormat".localized, lunar.day, lunar.month)
            + " · " + base.countdownText
        if let templeName {
            subtitle += " · " + String(format: "sangha.day.templeHasRite".localized, templeName)
        }

        let suggestionKey: String
        if day.kind == .festival {
            suggestionKey = "sangha.day.suggestion.festival"
        } else if lunar.day == 15 {
            suggestionKey = "sangha.day.suggestion.fullMoon"
        } else {
            suggestionKey = "sangha.day.suggestion.newMoon"
        }

        return ILSanghaDayRowModel(
            id: day.id,
            dayNumber: base.dayNumber,
            monthLabel: Self.monthLabel(day.date, calendar: calendar),
            title: day.title,
            subtitle: subtitle,
            suggestion: suggestionKey.localized,
            isFestival: base.isFestival,
            reminderLabel: (isReminded ? "sangha.action.reminded" : "sangha.action.remind").localized,
            isReminderOn: isReminded
        )
    }

    // MARK: - Formatting
    /// "TH10" — tháng dương.
    private static func monthLabel(_ date: Date, calendar: Calendar) -> String {
        String(format: "sangha.month.format".localized, calendar.component(.month, from: date))
    }

    /// "Hôm nay" khi cùng ngày, còn lại "N ngày trước".
    static func relativeDay(from date: Date, now: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        return days <= 0
            ? "sangha.time.today".localized
            : String(format: "sangha.time.daysAgo".localized, days)
    }

    /// "3,2 km" — dấu phẩy thập phân kiểu Việt.
    static func formatDistance(_ km: Double) -> String {
        String(format: "%.1f km", km).replacingOccurrences(of: ".", with: ",")
    }

    /// Nhóm hàng nghìn theo kiểu Việt: 1248 → "1.248".
    static func formatCount(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: NSNumber(value: count)) ?? String(count)
    }

    /// "Đang mở · đến 18:00" / "Đã đóng · mở 6:00" theo `operating_hours`; `nil` khi giờ không hợp lệ.
    static func status(operatingHours: String, now: Date) -> (text: String, isOpen: Bool)? {
        guard let hours = ILTempleViewModel.parseOperatingHours(operatingHours) else { return nil }
        let calendar = Calendar(identifier: .gregorian)
        let minute = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let isOpen = hours.close > hours.open
            ? minute >= hours.open && minute < hours.close
            : minute >= hours.open || minute < hours.close
        let time = { (value: Int) in "\(value / 60):" + String(format: "%02d", value % 60) }
        let text = isOpen
            ? String(format: "sangha.status.open".localized, time(hours.close))
            : String(format: "sangha.status.closed".localized, time(hours.open))
        return (text, isOpen)
    }
}
