//
//  ILTempleViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILTempleNavEvent: Equatable {
    /// Nút ‹ ở header — đóng màn Trang chùa.
    case back
    /// Nút "Cúng dường" — mở màn Cúng dường (chưa build).
    case offer
    /// "Xem tất cả" / khung rỗng ở mục "Sự kiện & khóa học" — mở màn Sự kiện & khóa học của chùa
    /// này (chưa build).
    case events
    /// Chạm 1 thời khóa sắp tới — mang theo `id` thời khóa (màn chi tiết thời khóa/đọc kinh chưa
    /// build).
    case session(id: String)
    /// Mở 1 URL hệ thống (chỉ đường Google/Apple Maps, gọi Hotline, mở Fanpage/Website, gửi Email)
    /// — `Coordinator` gọi `UIApplication.shared.open(_:)`, `ViewModel` chỉ dựng chuỗi URL.
    case openURL(String)
}

protocol ILTempleViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILTempleCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILTempleNavEvent, Never> { get }
}

/// Temple detail screen. On `viewDidLoad` the profile is fetched from the server
/// (`ILTempleUseCase.loadTemple(id:)` → `GET /v1/temples/{id}`): the state goes `.loading` →
/// `.success` (or `.failure`, from which `retryTapped` loads again).
///
/// Only data from that response is filled into the state. Every section of the screen is kept;
/// a field the API does not send is left empty and shown as "Đang cập nhật".
final class ILTempleViewModel: ILTempleViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        /// "Thử lại" on the error state — loads the profile again.
        let retryTapped: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let followTapped: AnyPublisher<Void, Never>
        let bioToggled: AnyPublisher<Void, Never>
        /// Nút "Chỉ đường" và nút "Google Maps" ở mục Vị trí & liên hệ — cùng mở Google Maps
        /// (khớp design handoff dùng chung `tpGmaps`).
        let googleMapsTapped: AnyPublisher<Void, Never>
        let appleMapsTapped: AnyPublisher<Void, Never>
        let offerTapped: AnyPublisher<Void, Never>
        let eventsTapped: AnyPublisher<Void, Never>
        /// Chạm 1 thời khóa sắp tới — mang theo `id` thời khóa.
        let sessionTapped: AnyPublisher<String, Never>
        /// Chạm 1 mục liên hệ — mang theo `id` ("phone"/"fanpage"/"website"/"email").
        let contactTapped: AnyPublisher<String, Never>
    }

    struct Output {
        /// Whole-screen state: `.loading` while fetching, `.failure` when the profile could not
        /// be loaded (the screen shows an error + retry).
        let state: AnyPublisher<ViewState<ILTempleStateModel>, Never>
        /// Transient error after the profile is on screen (e.g. follow failed) — shown as a toast
        /// without replacing the content.
        let errorMessage: AnyPublisher<String, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILTempleNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILTempleNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILTempleStateModel>, Never>(.idle)
    private let errorMessageSubject = PassthroughSubject<String, Never>()
    private let useCase: ILTempleUseCase
    private let templeID: String
    /// Nguồn "bây giờ" — tiêm vào để test trạng thái mở/đóng cửa không phụ thuộc đồng hồ máy.
    private let now: () -> Date
    /// `nil` until the first successful load.
    private var currentDetail: ILTempleDetailEntity?
    private var currentState: ILTempleStateModel?
    private var loadTask: Task<Void, Never>?
    private var isFollowing = false
    private var isBiographyExpanded = false
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILTempleUseCase, templeID: String, now: @escaping () -> Date = Date.init) {
        self.useCase = useCase
        self.templeID = templeID
        self.now = now
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.loadTemple() }
            .store(in: &cancellables)

        input.retryTapped
            .sink { [weak self] _ in self?.loadTemple() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        input.followTapped
            .sink { [weak self] _ in self?.handleFollowTapped() }
            .store(in: &cancellables)

        input.bioToggled
            .sink { [weak self] _ in
                guard let self else { return }
                isBiographyExpanded.toggle()
                publishState()
            }
            .store(in: &cancellables)

        input.googleMapsTapped
            .sink { [weak self] _ in
                guard let detail = self?.currentDetail else { return }
                self?.navigationEventSubject.send(.openURL(Self.googleMapsURL(for: detail)))
            }
            .store(in: &cancellables)

        input.appleMapsTapped
            .sink { [weak self] _ in
                guard let detail = self?.currentDetail else { return }
                self?.navigationEventSubject.send(.openURL(Self.appleMapsURL(for: detail)))
            }
            .store(in: &cancellables)

        input.offerTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.offer) }
            .store(in: &cancellables)

        input.eventsTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.events) }
            .store(in: &cancellables)

        input.sessionTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.session(id: id)) }
            .store(in: &cancellables)

        input.contactTapped
            .sink { [weak self] id in
                guard let self,
                      let contact = currentState?.contacts.first(where: { $0.id == id && $0.hasValue }),
                      let url = Self.contactURL(id: contact.id, value: contact.value) else { return }
                navigationEventSubject.send(.openURL(url))
            }
            .store(in: &cancellables)

        return Output(
            state: stateSubject.eraseToAnyPublisher(),
            errorMessage: errorMessageSubject.eraseToAnyPublisher()
        )
    }

    // MARK: - Actions
    /// Fetches the profile. `self` is not held across the network call, so popping the screen
    /// mid-load releases the ViewModel; a superseded load is cancelled and its result dropped.
    private func loadTemple() {
        loadTask?.cancel()
        stateSubject.send(.loading)

        let useCase = useCase
        let templeID = templeID
        loadTask = Task { [weak self] in
            do {
                let detail = try await useCase.loadTemple(id: templeID)
                guard !Task.isCancelled, let self else { return }
                currentDetail = detail
                publishState()
            } catch {
                guard !Task.isCancelled, let self else { return }
                stateSubject.send(.failure(error))
            }
        }
    }

    /// Theo dõi / bỏ theo dõi chùa — cập nhật UI ngay (optimistic) và hoàn tác nếu use case ném
    /// lỗi. `ILTempleUseCase.toggleFollow` là stub (cần repository lưu danh sách chùa đang theo
    /// dõi, chưa build) nên trạng thái `isFollowing` chỉ giữ ở đây.
    private func handleFollowTapped() {
        guard currentDetail != nil else { return }
        isFollowing.toggle()
        publishState()

        let useCase = useCase
        let templeID = templeID
        Task { [weak self] in
            do {
                try await useCase.toggleFollow(templeID: templeID)
            } catch {
                guard let self else { return }
                isFollowing.toggle()
                publishState()
                errorMessageSubject.send(error.localizedDescription)
            }
        }
    }

    // MARK: - Entity -> StateModel
    private func publishState() {
        guard let currentDetail else { return }
        let state = Self.makeStateModel(
            from: currentDetail, isFollowing: isFollowing, isBiographyExpanded: isBiographyExpanded, now: now()
        )
        currentState = state
        stateSubject.send(.success(state))
    }

    /// `Entity -> StateModel` là việc riêng của presentation (nhãn nút, trạng thái mở/đóng cửa
    /// theo giờ hiện tại, các chuỗi đã format sẵn) nên nằm ở đây, không phải trong Mapper dùng
    /// chung (xem `references/data_layer_boundaries.md`).
    ///
    /// Only API fields are filled; everything else stays empty / "Đang cập nhật".
    private static func makeStateModel(
        from detail: ILTempleDetailEntity, isFollowing: Bool, isBiographyExpanded: Bool, now: Date
    ) -> ILTempleStateModel {
        let summary = detail.summary
        let updating = "temple.info.updating".localized
        let rankText = ILTempleCatalogLabels.heritageRankLabel(summary.heritageRank) ?? "temple.rank.none".localized
        let sectText = ILTempleCatalogLabels.sectLabel(summary.sect)
        let regionText = ILTempleCatalogLabels.regionLabel(summary.region)

        var state = ILTempleStateModel()

        // Hero
        state.headerTitle = summary.name
        state.rankChip = rankText
        state.sectChip = sectText
        state.name = summary.name
        state.hasAlias = !detail.aliases.isEmpty
        state.aliasLine = String(format: "temple.hero.alias".localized, detail.aliases.joined(separator: " · "))
        state.placeLine = Self.placeLine(from: summary.location.address)
        state.heroImageURL = summary.imageURL

        state.followButtonTitle = (isFollowing ? "temple.following" : "temple.follow").localized
        state.directionsButtonTitle = "temple.directions".localized
        state.offerButtonTitle = "temple.offer".localized

        // Status card — the API sends one range ("06:00 - 18:00"), shown as the weekday row; it
        // has no holiday (Rằm & Mùng Một) range and no user location for the distance.
        let hours = Self.parseOperatingHours(detail.operatingHours)
        if let hours {
            let calendar = Calendar.current
            let minuteOfDay = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
            state.isOpen = Self.isOpen(at: minuteOfDay, open: hours.open, close: hours.close)
            state.openStatusText = (state.isOpen ? "temple.status.open" : "temple.status.closed").localized
            state.openNoteText = state.isOpen
                ? String(format: "temple.status.closesAt".localized, Self.formatMinuteOfDay(hours.close))
                : String(format: "temple.status.opensAt".localized, Self.formatMinuteOfDay(hours.open))
        } else {
            state.isOpen = false
            state.openStatusText = "temple.status.unknown".localized
            state.openNoteText = ""
        }
        state.distanceText = ""
        state.hourRows = [
            ILTempleHourRowModel(
                id: "weekday", label: "temple.hours.weekday".localized,
                value: hours.map { "\(Self.formatMinuteOfDay($0.open)) – \(Self.formatMinuteOfDay($0.close))" } ?? updating,
                isToday: hours != nil
            ),
            ILTempleHourRowModel(id: "holiday", label: "temple.hours.holiday".localized, value: updating, isToday: false)
        ]

        // Facts grid
        state.facts = [
            ILTempleFactModel(
                id: "era", label: "temple.facts.era".localized,
                value: summary.establishedYear > 0
                    ? String(format: "temple.facts.eraFormat".localized, summary.establishedYear)
                    : updating
            ),
            ILTempleFactModel(id: "rank", label: "temple.facts.rank".localized, value: rankText),
            ILTempleFactModel(id: "sect", label: "temple.facts.sect".localized, value: sectText),
            ILTempleFactModel(id: "region", label: "temple.facts.region".localized, value: regionText)
        ]

        // Giới thiệu
        state.descriptionText = detail.introduction
        state.isBiographyExpanded = isBiographyExpanded
        state.biographyToggleTitle = (isBiographyExpanded ? "temple.bio.collapse" : "temple.bio.readMore").localized

        // Tổ chức & truyền thừa — "Giáo hội" is not in the API.
        state.orgInfo = [
            Self.orgInfo(id: "abbot", label: "temple.org.abbot".localized, value: detail.currentAbbot),
            Self.orgInfo(id: "founder", label: "temple.org.founder".localized, value: detail.founder),
            Self.orgInfo(id: "sangha", label: "temple.org.sangha".localized, value: "")
        ]

        // Kiến trúc & di sản — one paragraph; the API has no separate highlight cards.
        state.architectureText = detail.architectureHeritage
        state.highlights = []

        // Tiện ích — "Kinh sách" is not in the API.
        let facilities = detail.facilities
        state.amenities = [
            Self.amenity(id: "car", label: "temple.amenity.car".localized, isAvailable: facilities.hasCarParking),
            Self.amenity(id: "bike", label: "temple.amenity.bike".localized, isAvailable: facilities.hasMotorbikeParking),
            Self.amenity(id: "veg", label: "temple.amenity.veg".localized, isAvailable: facilities.servesVegetarianMeals),
            Self.amenity(id: "books", label: "temple.amenity.books".localized, isAvailable: nil),
            Self.amenity(id: "retreat", label: "temple.amenity.retreat".localized, isAvailable: facilities.hasSummerRetreat)
        ]

        // Lưu ý khi viếng thăm — numbered "01", "02"…
        state.visitRules = detail.visitingNotes.enumerated().map { index, note in
            ILTempleRuleModel(id: "rule_\(index)", number: String(format: "%02d", index + 1), text: note)
        }

        // Sự kiện & khóa học — not in the API.
        state.hasUpcomingSchedule = false
        state.sessions = []

        // Vị trí & liên hệ — contacts are not in the API.
        state.addressLine = summary.location.address
        state.regionLine = regionText
        state.coordinateText = String(format: "%.4f° B, %.4f° Đ", summary.location.latitude, summary.location.longitude)
        state.contacts = [
            ("phone", "temple.contact.phone"), ("fanpage", "temple.contact.fanpage"),
            ("website", "temple.contact.website"), ("email", "temple.contact.email")
        ].map { id, labelKey in
            ILTempleContactModel(id: id, label: labelKey.localized, value: updating, hasValue: false)
        }

        // Chân trang — no "updated" date in the API.
        state.updatedText = ""

        return state
    }

    private static func orgInfo(id: String, label: String, value: String) -> ILTempleOrgInfoModel {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return ILTempleOrgInfoModel(
            id: id, label: label,
            value: trimmed.isEmpty ? "temple.info.updating".localized : trimmed,
            hasValue: !trimmed.isEmpty
        )
    }

    /// `isAvailable == nil` — the API does not say; shown as "Đang cập nhật", unticked.
    private static func amenity(id: String, label: String, isAvailable: Bool?) -> ILTempleAmenityModel {
        let valueKey: String
        switch isAvailable {
        case true?: valueKey = "temple.amenity.available"
        case false?: valueKey = "temple.amenity.none"
        case nil: valueKey = "temple.info.updating"
        }
        return ILTempleAmenityModel(id: id, label: label, value: valueKey.localized, isAvailable: isAvailable == true)
    }

    /// "Phường Kim Long, TP. Huế" — the last two address parts (district-level + province); the
    /// full address is shown in the location section.
    private static func placeLine(from address: String) -> String {
        ILTempleCatalogLabels.addressComponents(of: address).suffix(2).joined(separator: ", ")
    }

    // MARK: - Opening hours
    /// Parses the server's `operating_hours` ("06:00 - 18:00") into minutes of the day. `nil` for
    /// an empty or unrecognized value.
    static func parseOperatingHours(_ raw: String) -> (open: Int, close: Int)? {
        let parts = raw
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let open = minuteOfDay(from: parts[0]),
              let close = minuteOfDay(from: parts[1]) else { return nil }
        return (open, close)
    }

    /// "06:30" → 390. `nil` unless it is a valid `H:mm` / `HH:mm` time.
    private static func minuteOfDay(from text: String) -> Int? {
        let pieces = text.split(separator: ":")
        guard pieces.count == 2,
              let hour = Int(pieces[0]), let minute = Int(pieces[1]),
              (0...24).contains(hour), (0..<60).contains(minute) else { return nil }
        let total = hour * 60 + minute
        return total <= 24 * 60 ? total : nil
    }

    /// Open when `minute` is in `[open, close)`; a range past midnight (`close <= open`) wraps.
    private static func isOpen(at minute: Int, open: Int, close: Int) -> Bool {
        close > open
            ? minute >= open && minute < close
            : minute >= open || minute < close
    }

    /// "5:00" — `minute` là số phút trong ngày.
    private static func formatMinuteOfDay(_ minute: Int) -> String {
        "\(minute / 60):" + String(format: "%02d", minute % 60)
    }

    // MARK: - URL builders
    private static func googleMapsURL(for detail: ILTempleDetailEntity) -> String {
        let location = detail.summary.location
        return "https://www.google.com/maps/dir/?api=1&destination=\(location.latitude),\(location.longitude)"
    }

    private static func appleMapsURL(for detail: ILTempleDetailEntity) -> String {
        let location = detail.summary.location
        return "https://maps.apple.com/?daddr=\(location.latitude),\(location.longitude)"
    }

    private static func contactURL(id: String, value: String) -> String? {
        guard !value.isEmpty else { return nil }
        switch id {
        case "phone": return "tel:" + value.replacingOccurrences(of: " ", with: "")
        case "fanpage", "website": return "https://" + value
        case "email": return "mailto:" + value
        default: return nil
        }
    }
}
