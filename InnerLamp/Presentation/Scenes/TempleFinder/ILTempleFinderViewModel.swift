//
//  ILTempleFinderViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

/// Chip lọc miền ở màn "Chọn chùa tu tập".
enum ILTempleFinderRegionFilter: CaseIterable, Equatable {
    case all
    case north
    case central
    case south

    var title: String {
        switch self {
        case .all: return "templeFinder.region.all".localized
        case .north: return "templeFinder.region.north".localized
        case .central: return "templeFinder.region.central".localized
        case .south: return "templeFinder.region.south".localized
        }
    }

    func matches(_ region: ILTempleRegion) -> Bool {
        switch self {
        case .all: return true
        case .north: return region == .north
        case .central: return region == .central
        case .south: return region == .south
        }
    }
}

enum ILTempleFinderNavEvent: Equatable {
    case back
    /// Chạm 1 hàng chùa — mở Trang chùa.
    case openTemple(id: String)
    /// Đã đặt chùa tu tập — đóng màn, tab Chùa tự tải lại khi hiện.
    case picked
}

protocol ILTempleFinderViewModelProtocol: ViewModelType {
    var navigationEventPublisher: AnyPublisher<ILTempleFinderNavEvent, Never> { get }
}

/// Màn "Chọn chùa tu tập" (`findtp` ở chế độ chọn): nạp toàn bộ danh bạ, lọc theo từ khóa + miền
/// ở client, "Chọn" đặt chùa tu tập, "Không thấy chùa bạn tìm?" mở form đề xuất chùa mới.
/// Gửi đề xuất **chưa lưu / chưa gửi đi đâu** (chưa có API) — chỉ kiểm tra và báo "đã gửi".
final class ILTempleFinderViewModel: ILTempleFinderViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let queryChanged: AnyPublisher<String, Never>
        let regionSelected: AnyPublisher<ILTempleFinderRegionFilter, Never>
        /// Chạm hàng chùa — mang theo `id`.
        let templeTapped: AnyPublisher<String, Never>
        /// "Chọn" ở 1 hàng chùa — mang theo `id`.
        let pickTapped: AnyPublisher<String, Never>
        let retryTapped: AnyPublisher<Void, Never>
        /// "Không thấy chùa bạn tìm?" — mở form đề xuất.
        let addTapped: AnyPublisher<Void, Never>
        let addCancelled: AnyPublisher<Void, Never>
        let addSubmitted: AnyPublisher<ILTempleFinderProposal, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILTempleFinderStateModel>, Never>
        /// 4 chip miền — có từ khung hình đầu, độc lập với việc nạp danh bạ.
        let filters: AnyPublisher<[ILTempleFinderRegionChipModel], Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILTempleFinderNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILTempleFinderNavEvent, Never>()
    private let stateSubject = CurrentValueSubject<ViewState<ILTempleFinderStateModel>, Never>(.idle)
    private lazy var filtersSubject = CurrentValueSubject<[ILTempleFinderRegionChipModel], Never>(
        Self.makeChips(selected: region)
    )
    private let useCase: ILTempleFinderUseCase
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?

    private var temples: [ILTempleSummaryEntity] = []
    private var myTemple: (id: String, name: String)?
    private var hasLoaded = false
    private var query = ""
    private var region: ILTempleFinderRegionFilter = .all
    private var addForm: ILTempleFinderAddFormModel?
    private var sentName: String?

    // MARK: - Initializer
    init(useCase: ILTempleFinderUseCase) {
        self.useCase = useCase
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

        input.queryChanged
            .sink { [weak self] text in
                self?.query = text
                self?.publishIfLoaded()
            }
            .store(in: &cancellables)

        input.regionSelected
            .sink { [weak self] filter in
                guard let self, filter != region else { return }
                region = filter
                filtersSubject.send(Self.makeChips(selected: filter))
                publishIfLoaded()
            }
            .store(in: &cancellables)

        input.templeTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openTemple(id: id)) }
            .store(in: &cancellables)

        input.pickTapped
            .sink { [weak self] id in
                guard let self, let temple = temples.first(where: { $0.id == id }) else { return }
                useCase.selectMyTemple(temple)
                navigationEventSubject.send(.picked)
            }
            .store(in: &cancellables)

        input.addTapped
            .sink { [weak self] _ in
                guard let self else { return }
                sentName = nil
                addForm = ILTempleFinderAddFormModel(
                    prefillName: query.trimmingCharacters(in: .whitespacesAndNewlines),
                    errorMessage: nil, errorField: nil
                )
                publishIfLoaded()
            }
            .store(in: &cancellables)

        input.addCancelled
            .sink { [weak self] _ in
                self?.addForm = nil
                self?.publishIfLoaded()
            }
            .store(in: &cancellables)

        input.addSubmitted
            .sink { [weak self] proposal in self?.submit(proposal) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher(), filters: filtersSubject.eraseToAnyPublisher())
    }

    // MARK: - Loading
    private func load() {
        loadTask?.cancel()
        stateSubject.send(.loading)
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let loaded = try await useCase.loadTemples()
                guard !Task.isCancelled else { return }
                temples = loaded
                myTemple = useCase.loadMyTemple()
                hasLoaded = true
                publish()
            } catch {
                guard !Task.isCancelled else { return }
                stateSubject.send(.failure(error))
            }
        }
    }

    private func publishIfLoaded() {
        guard hasLoaded else { return }
        publish()
    }

    private func publish() {
        stateSubject.send(.success(makeState()))
    }

    // MARK: - Proposal (UI only)
    // @ai: assumption — see Docs/Assumptions/TempleFinder/AS-TempleFinder-001-proposal-ui-only.md
    // TODO: gửi đề xuất lên backend khi có contract (xem Docs/Tech-Debt/TempleFinder/TD-TempleFinder-001-*.md).
    private func submit(_ proposal: ILTempleFinderProposal) {
        let name = proposal.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let province = proposal.province.trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty {
            showFormError("templeFinder.add.error.name".localized, field: .name, proposal: proposal)
            return
        }
        if province.isEmpty {
            showFormError("templeFinder.add.error.province".localized, field: .province, proposal: proposal)
            return
        }
        if let duplicate = temples.first(where: { Self.isDuplicate($0, name: name, province: province) }) {
            showFormError(
                String(format: "templeFinder.add.error.duplicate".localized, duplicate.name),
                field: .name, proposal: proposal
            )
            return
        }

        addForm = nil
        sentName = name
        query = ""
        publish()
    }

    private func showFormError(_ message: String, field: ILTempleFinderAddField, proposal: ILTempleFinderProposal) {
        addForm = ILTempleFinderAddFormModel(prefillName: proposal.name, errorMessage: message, errorField: field)
        publish()
    }

    /// Trùng khi cùng tên (không dấu) và địa chỉ của chùa trong danh bạ có chứa tỉnh / thành đã nhập.
    static func isDuplicate(_ temple: ILTempleSummaryEntity, name: String, province: String) -> Bool {
        normalize(temple.name) == normalize(name) && normalize(temple.location.address).contains(normalize(province))
    }

    // MARK: - Entity -> StateModel
    private func makeState() -> ILTempleFinderStateModel {
        var state = ILTempleFinderStateModel()
        state.subtitle = myTemple.map { String(format: "templeFinder.subtitle.current".localized, $0.name) }
            ?? "templeFinder.subtitle.none".localized
        state.addForm = addForm
        state.sentMessage = sentName.map { String(format: "templeFinder.sent".localized, $0) }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let needle = Self.normalize(trimmed)
        let matches = temples.filter { temple in
            region.matches(temple.region)
                && (needle.isEmpty || Self.normalize(temple.name + " " + temple.location.address).contains(needle))
        }
        state.rows = matches.map {
            ILTempleFinderRowModel(
                id: $0.id, name: $0.name, subtitle: $0.location.address, isMine: $0.id == myTemple?.id
            )
        }
        if matches.isEmpty {
            state.emptyText = Self.emptyText(query: trimmed, region: region)
        }
        return state
    }

    private static func emptyText(query: String, region: ILTempleFinderRegionFilter) -> String {
        switch (query.isEmpty, region == .all) {
        case (false, true):
            return String(format: "templeFinder.empty.query".localized, query)
        case (false, false):
            return String(format: "templeFinder.empty.queryRegion".localized, query, region.title)
        case (true, _):
            return String(format: "templeFinder.empty.region".localized, region.title)
        }
    }

    private static func makeChips(selected: ILTempleFinderRegionFilter) -> [ILTempleFinderRegionChipModel] {
        ILTempleFinderRegionFilter.allCases.map {
            ILTempleFinderRegionChipModel(filter: $0, label: $0.title, isSelected: $0 == selected)
        }
    }

    /// Chữ thường, bỏ dấu, `đ` → `d` — tìm "tu quang" ra "Từ Quang".
    static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
    }
}

/// Dữ liệu form "Đề xuất thêm chùa" — số điện thoại và địa chỉ không bắt buộc nên chưa được dùng
/// để kiểm tra; giữ lại cho lúc có API gửi đề xuất.
struct ILTempleFinderProposal: Equatable {
    let name: String
    let address: String
    let province: String
    let phone: String
}
