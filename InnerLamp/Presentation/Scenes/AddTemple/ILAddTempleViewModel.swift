//
//  ILAddTempleViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILAddTempleNavEvent: Equatable {
    case back
    /// Form hợp lệ — trả đề xuất về màn gọi.
    case submitted(ILTempleProposalEntity)
}

final class ILAddTempleViewModel: ViewModelType {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let nameChanged: AnyPublisher<String, Never>
        let provincePickerOpened: AnyPublisher<Void, Never>
        let provinceSelected: AnyPublisher<String, Never>
        let wardPickerOpened: AnyPublisher<Void, Never>
        let wardSelected: AnyPublisher<String, Never>
        let addressChanged: AnyPublisher<String, Never>
        let submitTapped: AnyPublisher<Void, Never>
        let cancelTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILAddTempleStateModel>, Never>
    }

    // MARK: - Properties
    /// Độc lập với `transform(input:)` — coordinator subscribe trực tiếp trong `start()`.
    var navigationEventPublisher: AnyPublisher<ILAddTempleNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    var state: ILAddTempleStateModel { currentState }

    private let navigationEventSubject = PassthroughSubject<ILAddTempleNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILAddTempleStateModel>, Never>
    private var currentState: ILAddTempleStateModel
    private let useCase: ILAddTempleUseCase
    private let existingPlaces: [ILOrdinationPlaceEntity]
    /// Tỉnh đã tải — cần `code` của tỉnh đang chọn để gọi API phường/xã.
    private var provinces: [ILProvinceEntity] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILAddTempleUseCase, prefillName: String, existingPlaces: [ILOrdinationPlaceEntity]) {
        self.useCase = useCase
        self.existingPlaces = existingPlaces
        var initial = ILAddTempleStateModel.initial
        initial.name = prefillName
        self.currentState = initial
        self.stateSubject = CurrentValueSubject(.success(initial))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in
                guard let self else { return }
                stateSubject.send(.success(currentState))
                loadProvinces()
            }
            .store(in: &cancellables)

        input.nameChanged
            .sink { [weak self] text in self?.update { $0.name = text } }
            .store(in: &cancellables)

        input.provincePickerOpened
            .sink { [weak self] _ in self?.loadProvincesIfNeeded() }
            .store(in: &cancellables)

        input.provinceSelected
            .sink { [weak self] province in self?.selectProvince(province) }
            .store(in: &cancellables)

        input.wardPickerOpened
            .sink { [weak self] _ in self?.loadWardsIfNeeded() }
            .store(in: &cancellables)

        input.wardSelected
            .sink { [weak self] ward in self?.update { $0.ward = ward } }
            .store(in: &cancellables)

        input.addressChanged
            .sink { [weak self] text in self?.update { $0.address = text } }
            .store(in: &cancellables)

        input.submitTapped
            .sink { [weak self] _ in self?.handleSubmit() }
            .store(in: &cancellables)

        input.cancelTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.back) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    /// Gõ lại thì xoá lỗi đang hiện.
    private func update(_ change: (inout ILAddTempleStateModel) -> Void) {
        change(&currentState)
        currentState.errorMessage = nil
        currentState.errorField = nil
        stateSubject.send(.success(currentState))
    }

    // MARK: - Metadata
    private func loadProvincesIfNeeded() {
        guard currentState.provinceOptions.isEmpty, !currentState.isLoadingProvinces else { return }
        loadProvinces()
    }

    private func loadProvinces() {
        currentState.isLoadingProvinces = true
        stateSubject.send(.success(currentState))

        Task { [weak self] in
            guard let self else { return }
            do {
                provinces = try await useCase.loadProvinces()
                currentState.provinceOptions = provinces.map(\.name)
            } catch {
                currentState.errorMessage = error.localizedDescription
            }
            currentState.isLoadingProvinces = false
            stateSubject.send(.success(currentState))
        }
    }

    /// Đổi tỉnh thì xoá phường/xã đã chọn (không còn thuộc tỉnh mới) rồi tải lại danh sách.
    private func selectProvince(_ province: String) {
        guard province != currentState.province else { return }
        currentState.wardOptions = []
        update {
            $0.province = province
            $0.ward = ""
        }
        loadWards()
    }

    private func loadWardsIfNeeded() {
        guard !currentState.province.isEmpty,
              currentState.wardOptions.isEmpty,
              !currentState.isLoadingWards else { return }
        loadWards()
    }

    private func loadWards() {
        let province = currentState.province
        guard let provinceCode = provinces.first(where: { $0.name == province })?.code else { return }
        currentState.isLoadingWards = true
        stateSubject.send(.success(currentState))

        Task { [weak self] in
            guard let self else { return }
            let result: Result<[ILWardEntity], Error>
            do {
                result = .success(try await useCase.loadWards(provinceCode: provinceCode))
            } catch {
                result = .failure(error)
            }
            // Người dùng đã đổi sang tỉnh khác trong lúc chờ — bỏ kết quả cũ.
            guard currentState.province == province else { return }
            switch result {
            case .success(let wards):
                currentState.wardOptions = wards.map(\.fullName)
            case .failure(let error):
                currentState.errorMessage = error.localizedDescription
            }
            currentState.isLoadingWards = false
            stateSubject.send(.success(currentState))
        }
    }

    // MARK: - Submit
    private func handleSubmit() {
        let error = useCase.validate(
            name: currentState.name,
            province: currentState.province,
            ward: currentState.ward,
            existing: existingPlaces
        )
        guard let error else {
            let proposal = useCase.makeProposal(
                name: currentState.name,
                province: currentState.province,
                ward: currentState.ward,
                address: currentState.address
            )
            navigationEventSubject.send(.submitted(proposal))
            return
        }

        switch error {
        case .nameRequired:
            currentState.errorMessage = "addTemple.error.name".localized
            currentState.errorField = .name
        case .provinceRequired:
            currentState.errorMessage = "addTemple.error.province".localized
            currentState.errorField = .province
        case .wardRequired:
            currentState.errorMessage = "addTemple.error.ward".localized
            currentState.errorField = .ward
        case .duplicate(let name):
            currentState.errorMessage = String(format: "addTemple.error.duplicate".localized, name)
            currentState.errorField = .name
        }
        stateSubject.send(.success(currentState))
    }
}
