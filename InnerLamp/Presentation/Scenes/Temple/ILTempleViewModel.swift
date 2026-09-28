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

final class ILTempleViewModel: ILTempleViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
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
        let state: AnyPublisher<ViewState<ILTempleStateModel>, Never>
    }

    /// Vị trí người dùng cố định dùng để tính khoảng cách (prototype cố định ở Quận 1, TP.HCM,
    /// khớp design handoff — chưa xin quyền vị trí thật).
    private static let userLatitude = 10.7769
    private static let userLongitude = 106.7009

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILTempleNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILTempleNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILTempleStateModel>, Never>
    private var currentEntity: ILTempleEntity
    private var currentState: ILTempleStateModel
    private let useCase: ILTempleUseCase
    private let initialTempleID: String
    /// Nguồn "hôm nay" — tiêm vào để test trạng thái mở/đóng cửa không phụ thuộc đồng hồ máy.
    private let now: () -> Date
    private var isFollowing = false
    private var isBiographyExpanded = false
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILTempleUseCase, templeID: String, now: @escaping () -> Date = Date.init) {
        self.useCase = useCase
        self.initialTempleID = templeID
        self.now = now
        let initialEntity = useCase.getInitialState(templeID: templeID)
        self.currentEntity = initialEntity
        self.currentState = Self.makeStateModel(
            from: initialEntity, isFollowing: false, isBiographyExpanded: false, now: now()
        )
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
                guard let self else { return }
                navigationEventSubject.send(.openURL(Self.googleMapsURL(for: currentEntity)))
            }
            .store(in: &cancellables)

        input.appleMapsTapped
            .sink { [weak self] _ in
                guard let self else { return }
                navigationEventSubject.send(.openURL(Self.appleMapsURL(for: currentEntity)))
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
                      let contact = currentEntity.contacts.first(where: { $0.id == id }),
                      let url = Self.contactURL(for: contact) else { return }
                navigationEventSubject.send(.openURL(url))
            }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState(templeID: initialTempleID))
    }

    /// Theo dõi / bỏ theo dõi chùa — cập nhật UI ngay (optimistic); `ILTempleUseCase.toggleFollow`
    /// là stub (cần repository lưu danh sách chùa đang theo dõi, chưa build) nên trạng thái
    /// `isFollowing` chỉ giữ ở đây, không nằm trong `ILTempleEntity`.
    private func handleFollowTapped() {
        isFollowing.toggle()
        publishState()

        let templeID = currentEntity.id
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.useCase.toggleFollow(templeID: templeID)
            } catch {
                self.stateSubject.send(.failure(error))
            }
        }
    }

    // MARK: - Entity -> StateModel
    private func applyEntity(_ entity: ILTempleEntity) {
        currentEntity = entity
        publishState()
    }

    private func publishState() {
        currentState = Self.makeStateModel(
            from: currentEntity, isFollowing: isFollowing, isBiographyExpanded: isBiographyExpanded, now: now()
        )
        stateSubject.send(.success(currentState))
    }

    /// `Entity -> StateModel` là việc riêng của presentation (nhãn nút, trạng thái mở/đóng cửa
    /// theo giờ hiện tại + âm lịch, khoảng cách theo `ILLunarCalendar`/haversine, các chuỗi đã
    /// format sẵn) nên nằm ở đây, không phải trong Mapper dùng chung
    /// (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(
        from entity: ILTempleEntity, isFollowing: Bool, isBiographyExpanded: Bool, now: Date
    ) -> ILTempleStateModel {
        var state = ILTempleStateModel()

        state.headerTitle = entity.name
        state.rankChip = entity.rank ?? "temple.rank.none".localized
        state.sectChip = entity.sect
        state.name = entity.name
        state.hasAlias = !entity.aliases.isEmpty
        state.aliasLine = String(format: "temple.hero.alias".localized, entity.aliases.joined(separator: " · "))
        state.placeLine = "\(entity.district), \(entity.province)"

        state.followButtonTitle = (isFollowing ? "temple.following" : "temple.follow").localized
        state.directionsButtonTitle = "temple.directions".localized
        state.offerButtonTitle = "temple.offer".localized

        let today = ILLunarCalendar.solarToLunar(date: now)
        let isHoliday = today.day == 1 || today.day == 15
        let hours = isHoliday ? entity.holidayHours : entity.regularHours
        let minuteOfDay = Calendar.current.component(.hour, from: now) * 60 + Calendar.current.component(.minute, from: now)
        state.isOpen = minuteOfDay >= hours.openMinute && minuteOfDay < hours.closeMinute
        state.openStatusText = (state.isOpen ? "temple.status.open" : "temple.status.closed").localized
        state.openNoteText = state.isOpen
            ? String(format: "temple.status.closesAt".localized, Self.formatMinuteOfDay(hours.closeMinute))
            : String(format: "temple.status.opensAt".localized, Self.formatMinuteOfDay(hours.openMinute))
        state.distanceText = String(format: "temple.distance.near".localized, Self.formatDistance(to: entity))
        state.hourRows = [
            ILTempleHourRowModel(
                id: "weekday", label: "temple.hours.weekday".localized,
                value: "\(Self.formatMinuteOfDay(entity.regularHours.openMinute)) – \(Self.formatMinuteOfDay(entity.regularHours.closeMinute))",
                isToday: !isHoliday
            ),
            ILTempleHourRowModel(
                id: "holiday", label: "temple.hours.holiday".localized,
                value: "\(Self.formatMinuteOfDay(entity.holidayHours.openMinute)) – \(Self.formatMinuteOfDay(entity.holidayHours.closeMinute))",
                isToday: isHoliday
            )
        ]

        state.facts = [
            ILTempleFactModel(id: "era", label: "temple.facts.era".localized, value: entity.era),
            ILTempleFactModel(id: "rank", label: "temple.facts.rank".localized, value: entity.rank ?? "temple.info.updating".localized),
            ILTempleFactModel(id: "sect", label: "temple.facts.sect".localized, value: entity.sect),
            ILTempleFactModel(id: "region", label: "temple.facts.region".localized, value: entity.subRegion)
        ]

        state.descriptionText = entity.bio
        state.isBiographyExpanded = isBiographyExpanded
        state.biographyToggleTitle = (isBiographyExpanded ? "temple.bio.collapse" : "temple.bio.readMore").localized

        state.orgInfo = entity.orgInfo.map { info in
            ILTempleOrgInfoModel(
                id: info.id, label: info.label,
                value: info.value ?? "temple.info.updating".localized,
                hasValue: info.value != nil
            )
        }

        state.archStyle = entity.archStyle
        state.materials = entity.materials
        state.highlights = entity.highlights

        state.amenities = entity.amenities.map { amenity in
            let isAvailable = amenity.value != nil
            return ILTempleAmenityModel(
                id: amenity.id, label: amenity.label,
                value: amenity.value ?? "temple.amenity.none".localized,
                isAvailable: isAvailable
            )
        }

        state.visitRules = entity.visitRules.enumerated().map { index, text in
            ILTempleRuleModel(id: "rule-\(index)", number: String(format: "%02d", index + 1), text: text)
        }

        state.hasUpcomingSchedule = entity.hasUpcomingSchedule
        state.sessions = entity.sessions.map { session in
            ILTempleSessionModel(
                id: session.id, title: session.title, subtitle: session.subtitle,
                trailingText: session.trailingText, tone: session.tone, glyph: session.glyph
            )
        }

        state.addressLine = [entity.street, entity.ward, entity.district, entity.province].joined(separator: ", ")
        state.regionLine = entity.subRegion != entity.region ? "\(entity.region) · \(entity.subRegion)" : entity.region
        state.coordinateText = String(format: "%.4f° B, %.4f° Đ", entity.latitude, entity.longitude)
        state.contacts = entity.contacts.map { contact in
            ILTempleContactModel(
                id: contact.id, label: contact.label,
                value: contact.rawValue ?? "temple.info.updating".localized,
                hasValue: contact.rawValue != nil
            )
        }

        state.updatedText = String(format: "temple.footer.updated".localized, entity.updatedLabel)

        return state
    }

    // MARK: - URL builders
    private static func googleMapsURL(for entity: ILTempleEntity) -> String {
        "https://www.google.com/maps/dir/?api=1&destination=\(entity.latitude),\(entity.longitude)"
    }

    private static func appleMapsURL(for entity: ILTempleEntity) -> String {
        "https://maps.apple.com/?daddr=\(entity.latitude),\(entity.longitude)"
    }

    private static func contactURL(for contact: ILTempleContactEntity) -> String? {
        guard let rawValue = contact.rawValue, !rawValue.isEmpty else { return nil }
        switch contact.id {
        case "phone": return "tel:" + rawValue.replacingOccurrences(of: " ", with: "")
        case "fanpage", "website": return "https://" + rawValue
        case "email": return "mailto:" + rawValue
        default: return nil
        }
    }

    // MARK: - Formatting helpers
    /// "5:00" — `minute` là số phút trong ngày (khớp `hours`/`holHours` trong design handoff).
    private static func formatMinuteOfDay(_ minute: Int) -> String {
        "\(minute / 60):" + String(format: "%02d", minute % 60)
    }

    /// "3,2" (dưới 10km, 1 số lẻ, dấu phẩy thập phân Việt Nam) hoặc "12" (từ 10km, làm tròn) —
    /// công thức haversine từ `userLatitude`/`userLongitude` (khớp design handoff).
    private static func formatDistance(to entity: ILTempleEntity) -> String {
        let earthRadiusKm = 6371.0
        let userLatRad = userLatitude * .pi / 180
        let templeLatRad = entity.latitude * .pi / 180
        let deltaLat = (entity.latitude - userLatitude) * .pi / 180
        let deltaLng = (entity.longitude - userLongitude) * .pi / 180

        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(userLatRad) * cos(templeLatRad) * sin(deltaLng / 2) * sin(deltaLng / 2)
        let distanceKm = 2 * earthRadiusKm * asin(min(1, sqrt(a)))

        if distanceKm < 10 {
            return String(format: "%.1f", distanceKm).replacingOccurrences(of: ".", with: ",")
        }
        return String(Int(distanceKm.rounded()))
    }
}
