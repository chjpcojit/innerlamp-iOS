//
//  ILSignUpViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILSignUpViewModelTests: XCTestCase {

    private var mockRepository: MockILSignUpRepository!
    /// Real UseCase, fake Repository — so the tests exercise the real validation, Entity→DTO
    /// construction and error mapping rather than stubbing them away.
    private var useCase: ILSignUpUseCaseImpl!
    private var sut: ILSignUpViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var suggestDisplayNameTappedSubject: PassthroughSubject<Void, Never>!
    private var fullNameChangedSubject: PassthroughSubject<String, Never>!
    private var displayNameChangedSubject: PassthroughSubject<String, Never>!
    private var ordinationPlaceChangedSubject: PassthroughSubject<ILOrdinationPlaceSelection, Never>!
    private var ordinationPickerOpenedSubject: PassthroughSubject<Void, Never>!
    private var ordinationSearchChangedSubject: PassthroughSubject<String, Never>!
    private var ordinationLoadMoreSubject: PassthroughSubject<Void, Never>!
    private var addTempleTappedSubject: PassthroughSubject<String, Never>!
    private var mockOrdinationPlaceUseCase: MockILOrdinationPlaceUseCase!
    private var countryChangedSubject: PassthroughSubject<ILCountry, Never>!
    private var phoneNumberChangedSubject: PassthroughSubject<String, Never>!
    private var emailChangedSubject: PassthroughSubject<String, Never>!
    private var passwordChangedSubject: PassthroughSubject<String, Never>!
    private var togglePasswordVisibilityTappedSubject: PassthroughSubject<Void, Never>!
    private var toggleTermsTappedSubject: PassthroughSubject<Void, Never>!
    private var submitTappedSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var loginPromptTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockRepository = MockILSignUpRepository()
        useCase = ILSignUpUseCaseImpl(repository: mockRepository)
        mockOrdinationPlaceUseCase = MockILOrdinationPlaceUseCase()
        sut = ILSignUpViewModel(useCase: useCase, ordinationPlaceUseCase: mockOrdinationPlaceUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        suggestDisplayNameTappedSubject = PassthroughSubject<Void, Never>()
        fullNameChangedSubject = PassthroughSubject<String, Never>()
        displayNameChangedSubject = PassthroughSubject<String, Never>()
        ordinationPlaceChangedSubject = PassthroughSubject<ILOrdinationPlaceSelection, Never>()
        ordinationPickerOpenedSubject = PassthroughSubject<Void, Never>()
        ordinationSearchChangedSubject = PassthroughSubject<String, Never>()
        ordinationLoadMoreSubject = PassthroughSubject<Void, Never>()
        addTempleTappedSubject = PassthroughSubject<String, Never>()
        countryChangedSubject = PassthroughSubject<ILCountry, Never>()
        phoneNumberChangedSubject = PassthroughSubject<String, Never>()
        emailChangedSubject = PassthroughSubject<String, Never>()
        passwordChangedSubject = PassthroughSubject<String, Never>()
        togglePasswordVisibilityTappedSubject = PassthroughSubject<Void, Never>()
        toggleTermsTappedSubject = PassthroughSubject<Void, Never>()
        submitTappedSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        loginPromptTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        suggestDisplayNameTappedSubject = nil
        fullNameChangedSubject = nil
        displayNameChangedSubject = nil
        ordinationPlaceChangedSubject = nil
        ordinationPickerOpenedSubject = nil
        ordinationSearchChangedSubject = nil
        ordinationLoadMoreSubject = nil
        addTempleTappedSubject = nil
        mockOrdinationPlaceUseCase = nil
        countryChangedSubject = nil
        phoneNumberChangedSubject = nil
        emailChangedSubject = nil
        passwordChangedSubject = nil
        togglePasswordVisibilityTappedSubject = nil
        toggleTermsTappedSubject = nil
        submitTappedSubject = nil
        backTappedSubject = nil
        loginPromptTappedSubject = nil
        sut = nil
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }

    private func makeOutput() -> ILSignUpViewModel.Output {
        sut.transform(input: .init(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            fullNameChanged: fullNameChangedSubject.eraseToAnyPublisher(),
            suggestDisplayNameTapped: suggestDisplayNameTappedSubject.eraseToAnyPublisher(),
            displayNameChanged: displayNameChangedSubject.eraseToAnyPublisher(),
            ordinationPlaceChanged: ordinationPlaceChangedSubject.eraseToAnyPublisher(),
            ordinationPickerOpened: ordinationPickerOpenedSubject.eraseToAnyPublisher(),
            ordinationSearchChanged: ordinationSearchChangedSubject.eraseToAnyPublisher(),
            ordinationLoadMoreRequested: ordinationLoadMoreSubject.eraseToAnyPublisher(),
            addTempleTapped: addTempleTappedSubject.eraseToAnyPublisher(),
            countryChanged: countryChangedSubject.eraseToAnyPublisher(),
            phoneNumberChanged: phoneNumberChangedSubject.eraseToAnyPublisher(),
            emailChanged: emailChangedSubject.eraseToAnyPublisher(),
            passwordChanged: passwordChangedSubject.eraseToAnyPublisher(),
            togglePasswordVisibilityTapped: togglePasswordVisibilityTappedSubject.eraseToAnyPublisher(),
            toggleTermsTapped: toggleTermsTappedSubject.eraseToAnyPublisher(),
            submitTapped: submitTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            loginPromptTapped: loginPromptTappedSubject.eraseToAnyPublisher()
        ))
    }

    /// Pumps `viewDidLoad` and fills the form with valid values, leaving the box ticked — the
    /// common starting point for the submit tests.
    private func fillValidForm() {
        viewDidLoadSubject.send(())
        toggleTermsTappedSubject.send(())
        fullNameChangedSubject.send("Nguyễn Bình An")
        phoneNumberChangedSubject.send("0912345678")
        emailChangedSubject.send("phapdanh@email.com")
        passwordChangedSubject.send("secret12")
    }

    func test_initialState_matchesUseCaseDefault() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        XCTAssertNotNil(receivedState)
        XCTAssertEqual(receivedState?.displayName, useCase.dharmaNameSuggestions[0])
        XCTAssertEqual(receivedState?.selectedCountry, .default)
        XCTAssertFalse(receivedState!.isSubmitEnabled)
    }

    func test_suggestDisplayNameTapped_cyclesThroughSuggestions() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        suggestDisplayNameTappedSubject.send(())

        XCTAssertEqual(receivedState?.displayName, useCase.dharmaNameSuggestions[1])

        suggestDisplayNameTappedSubject.send(())
        XCTAssertEqual(receivedState?.displayName, useCase.dharmaNameSuggestions[2])
    }

    func test_countryChanged_updatesSelectedCountryAndClearsPhoneError() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        let japan = ILCountry.all.first { $0.iso == "JP" }!
        countryChangedSubject.send(japan)

        XCTAssertEqual(receivedState?.selectedCountry, japan)
        XCTAssertNil(receivedState?.phoneNumberError)
    }

    func test_phoneNumberChanged_updatesValidityAgainstSelectedCountry() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        phoneNumberChangedSubject.send("09123")
        XCTAssertFalse(receivedState!.isPhoneValid)

        phoneNumberChangedSubject.send("0912345678")
        XCTAssertTrue(receivedState!.isPhoneValid)
        XCTAssertEqual(receivedState?.phoneE164, "+84 912 345 678")
    }

    func test_phoneNumberChanged_validOnlyWithinNationalDigitRange() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        // VN range is exactly 9 national digits (leading 0 not counted).
        phoneNumberChangedSubject.send("91234567")
        XCTAssertFalse(receivedState!.isPhoneValid)

        phoneNumberChangedSubject.send("912345678")
        XCTAssertTrue(receivedState!.isPhoneValid)

        phoneNumberChangedSubject.send("0912345678")
        XCTAssertTrue(receivedState!.isPhoneValid)

        // One extra digit (11 digits with the leading 0) must be rejected.
        phoneNumberChangedSubject.send("09497970711")
        XCTAssertFalse(receivedState!.isPhoneValid)

        phoneNumberChangedSubject.send("9123456789")
        XCTAssertFalse(receivedState!.isPhoneValid)
    }

    func test_passwordChanged_updatesStrength() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        // Long + digit + symbol → real scoring gives "strong".
        passwordChangedSubject.send("Sup3r$ecret!")

        XCTAssertEqual(receivedState?.passwordStrength, .strong)
    }

    func test_emailChanged_liveFormatCheckOnlyWhenNonEmpty() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        XCTAssertFalse(receivedState!.hasEmailValue)

        emailChangedSubject.send("not-an-email")
        XCTAssertTrue(receivedState!.hasEmailValue)
        XCTAssertFalse(receivedState!.isEmailFormatValid)

        emailChangedSubject.send("phapdanh@email.com")
        XCTAssertTrue(receivedState!.isEmailFormatValid)
    }

    func test_submitTapped_withValidForm_sendsEmailAlongWithOtherFields() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)

        let expectation = expectation(description: "didRequestVerification")
        sut.navigationEventPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        fillValidForm()
        submitTappedSubject.send(())

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(mockRepository.receivedEntity?.email, "phapdanh@email.com")
    }

    func test_fullNameChanged_updatesStateAndClearsPreviousError() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        toggleTermsTappedSubject.send(())
        submitTappedSubject.send(())
        XCTAssertNotNil(receivedState?.fullNameError)

        fullNameChangedSubject.send("Nguyễn Bình An")

        XCTAssertEqual(receivedState?.fullName, "Nguyễn Bình An")
        XCTAssertNil(receivedState?.fullNameError)
    }

    func test_submitTapped_withBlankFullName_setsFullNameErrorAndDoesNotCallRepository() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        fillValidForm()
        fullNameChangedSubject.send("   ")
        submitTappedSubject.send(())

        XCTAssertNotNil(receivedState?.fullNameError)
        XCTAssertTrue(receivedState!.hasValidationError)
        XCTAssertFalse(mockRepository.requestRegistrationOTPCalled)
    }

    func test_submitTapped_sendsTrimmedFullNameSeparatelyFromDharmaName() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)

        let expectation = expectation(description: "didRequestVerification")
        sut.navigationEventPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        fillValidForm()
        fullNameChangedSubject.send("  Nguyễn Bình An \n")
        submitTappedSubject.send(())

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(mockRepository.receivedEntity?.fullName, "Nguyễn Bình An")
        XCTAssertEqual(mockRepository.receivedEntity?.displayName, useCase.dharmaNameSuggestions[0])
    }

    func test_ordinationPlaceChanged_updatesStateWithoutSettingAnyError() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        XCTAssertEqual(receivedState?.ordinationPlace, "")

        ordinationPlaceChangedSubject.send(ILOrdinationPlaceSelection(id: "temple_north_011", name: "Chùa Hoa Nghiêm"))

        XCTAssertEqual(receivedState?.ordinationPlace, "Chùa Hoa Nghiêm")
        XCTAssertEqual(receivedState?.selectedOrdinationPlaceID, "temple_north_011")
        XCTAssertFalse(receivedState!.hasValidationError)
    }

    func test_ordinationPickerOpened_loadsPlacesOnce() {
        let places = [
            ILOrdinationPlaceEntity(id: "t1", name: "Chùa Từ Quang", subtitle: "TP. Hồ Chí Minh"),
            ILOrdinationPlaceEntity(id: "t2", name: "Chùa Trấn Quốc", subtitle: "Hà Nội")
        ]
        mockOrdinationPlaceUseCase.places = places
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        let loaded = expectation(description: "places loaded")
        output.state
            .sink {
                guard case .success(let model) = $0 else { return }
                receivedState = model
                if model.ordinationPlaceOptions == places { loaded.fulfill() }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        ordinationPickerOpenedSubject.send(())
        wait(for: [loaded], timeout: 1)
        ordinationPickerOpenedSubject.send(())

        XCTAssertEqual(receivedState?.isLoadingOrdinationPlaces, false)
        XCTAssertEqual(mockOrdinationPlaceUseCase.loadCallCount, 1)
    }

    func test_addTempleTapped_emitsOpenAddTempleEventWithQueryAndLoadedPlaces() {
        let places = [ILOrdinationPlaceEntity(id: "t1", name: "Chùa Từ Quang", subtitle: "TP. Hồ Chí Minh")]
        mockOrdinationPlaceUseCase.places = places
        let output = makeOutput()
        let loaded = expectation(description: "places loaded")
        output.state
            .sink { if case .success(let model) = $0, model.ordinationPlaceOptions == places { loaded.fulfill() } }
            .store(in: &cancellables)
        var receivedEvent: ILSignUpNavEvent?
        sut.navigationEventPublisher.sink { receivedEvent = $0 }.store(in: &cancellables)

        viewDidLoadSubject.send(())
        ordinationPickerOpenedSubject.send(())
        wait(for: [loaded], timeout: 1)
        addTempleTappedSubject.send("Pháp Hoa")

        XCTAssertEqual(receivedEvent, .openAddTemple(prefillName: "Pháp Hoa", existingPlaces: places))
    }

    func test_applyProposedPlace_selectsProposalAndPutsItFirst() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)
        viewDidLoadSubject.send(())

        sut.applyProposedPlace(ILTempleProposalEntity(name: "Chùa Pháp Hoa", province: "Đà Nẵng", ward: "Hải Châu", address: "12 Lê Lợi"))

        XCTAssertEqual(receivedState?.ordinationPlace, "Chùa Pháp Hoa")
        XCTAssertEqual(receivedState?.ordinationPlaceOptions.first?.name, "Chùa Pháp Hoa")
        XCTAssertEqual(receivedState?.selectedOrdinationPlaceID, receivedState?.ordinationPlaceOptions.first?.id)

        ordinationPlaceChangedSubject.send(ILOrdinationPlaceSelection(id: nil, name: ""))
        XCTAssertNil(receivedState?.selectedOrdinationPlaceID)
    }

    // MARK: - Ordination picker: server search + paging

    func test_ordinationSearchChanged_debouncesAndReloadsFromPageOneWithServerQuery() {
        mockOrdinationPlaceUseCase.pagesByQuery[""] = [[ILOrdinationPlaceEntity(id: "t1", name: "Chùa Từ Quang", subtitle: "Hà Nội")]]
        let match = ILOrdinationPlaceEntity(id: "t9", name: "Chùa Trấn Quốc", subtitle: "Hà Nội")
        mockOrdinationPlaceUseCase.pagesByQuery["trấn"] = [[match]]
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        let searched = expectation(description: "search results")
        output.state
            .sink {
                guard case .success(let model) = $0 else { return }
                receivedState = model
                if model.ordinationPlaceOptions == [match], !model.isLoadingOrdinationPlaces { searched.fulfill() }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        ordinationSearchChangedSubject.send("t")
        ordinationSearchChangedSubject.send("tr")
        ordinationSearchChangedSubject.send("  trấn ")
        wait(for: [searched], timeout: 2)

        XCTAssertEqual(mockOrdinationPlaceUseCase.calls.map(\.query), ["trấn"], "Only the settled, trimmed keyword reaches the server")
        XCTAssertEqual(mockOrdinationPlaceUseCase.calls.map(\.page), [1])
        XCTAssertEqual(receivedState?.hasMoreOrdinationPlaces, false)
    }

    func test_ordinationLoadMore_appendsNextPageUntilServerSaysNoMore() {
        let page1 = (1...2).map { ILOrdinationPlaceEntity(id: "t\($0)", name: "Chùa \($0)", subtitle: "") }
        let page2 = [ILOrdinationPlaceEntity(id: "t3", name: "Chùa 3", subtitle: "")]
        mockOrdinationPlaceUseCase.pagesByQuery[""] = [page1, page2]
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        let firstPage = expectation(description: "first page")
        let secondPage = expectation(description: "second page")
        output.state
            .sink {
                guard case .success(let model) = $0 else { return }
                receivedState = model
                if model.ordinationPlaceOptions == page1, model.hasMoreOrdinationPlaces { firstPage.fulfill() }
                if model.ordinationPlaceOptions == page1 + page2, !model.isLoadingMoreOrdinationPlaces { secondPage.fulfill() }
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        ordinationPickerOpenedSubject.send(())
        wait(for: [firstPage], timeout: 1)
        ordinationLoadMoreSubject.send(())
        wait(for: [secondPage], timeout: 1)
        ordinationLoadMoreSubject.send(())

        XCTAssertEqual(receivedState?.hasMoreOrdinationPlaces, false)
        XCTAssertEqual(mockOrdinationPlaceUseCase.calls.map(\.page), [1, 2], "No request once the server reported the last page")
    }

    func test_ordinationPlaceFilter_emptyQuery_showsNoneThenEveryLoadedPlace() {
        let options = (1...9).map { ILOrdinationPlaceEntity(id: "t\($0)", name: "Chùa \($0)", subtitle: "") }

        let rows = ILOrdinationPlaceFilter.rows(options: options, query: "  ", noneName: "Chưa xuất gia", noneSubtitle: "Cư sĩ")

        XCTAssertEqual(rows.count, 10)
        XCTAssertTrue(rows[0].isNone)
        XCTAssertEqual(rows[9].id, "t9")
    }

    func test_ordinationPlaceFilter_query_showsServerResultsAsIsWithoutNoneRow() {
        let options = [
            ILOrdinationPlaceEntity(id: "t1", name: "Chùa Từ Quang", subtitle: "Đà Lạt"),
            ILOrdinationPlaceEntity(id: "t2", name: "Chùa Trấn Quốc", subtitle: "Hà Nội")
        ]

        let rows = ILOrdinationPlaceFilter.rows(options: options, query: "quang", noneName: "Chưa xuất gia", noneSubtitle: "")

        XCTAssertEqual(rows.map(\.id), ["t1", "t2"], "The server already filtered; the client must not filter again")
        XCTAssertFalse(rows.contains { $0.isNone })
    }

    func test_submitTapped_withoutOrdinationPlace_stillSubmitsWithoutTempleID() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)

        let expectation = expectation(description: "didRequestVerification")
        sut.navigationEventPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        fillValidForm()
        submitTappedSubject.send(())

        wait(for: [expectation], timeout: 1)

        XCTAssertTrue(mockRepository.requestRegistrationOTPCalled)
        XCTAssertNil(mockRepository.receivedEntity?.ordinationTempleID)
    }

    func test_submitTapped_withSelectedTemple_sendsItsServerID() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)

        let expectation = expectation(description: "didRequestVerification")
        sut.navigationEventPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        toggleTermsTappedSubject.send(())
        ordinationPlaceChangedSubject.send(ILOrdinationPlaceSelection(id: "temple_north_011", name: "Chùa Hoa Nghiêm"))
        phoneNumberChangedSubject.send("0912345678")
        emailChangedSubject.send("phapdanh@email.com")
        passwordChangedSubject.send("secret12")

        submitTappedSubject.send(())

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(mockRepository.receivedEntity?.ordinationTempleID, "temple_north_011")
    }

    func test_submitTapped_withProposedPendingTemple_doesNotSendItsTemporaryID() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)
        let expectation = expectation(description: "didRequestVerification")
        sut.navigationEventPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        toggleTermsTappedSubject.send(())
        sut.applyProposedPlace(ILTempleProposalEntity(name: "Chùa Pháp Hoa", province: "Đà Nẵng", ward: "Hải Châu", address: "12 Lê Lợi"))
        phoneNumberChangedSubject.send("0912345678")
        emailChangedSubject.send("phapdanh@email.com")
        passwordChangedSubject.send("secret12")
        submitTappedSubject.send(())

        wait(for: [expectation], timeout: 1)

        XCTAssertNil(mockRepository.receivedEntity?.ordinationTempleID)
    }

    func test_submitTapped_withEmptyEmail_setsEmailErrorAndDoesNotCallRepository() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        toggleTermsTappedSubject.send(())
        phoneNumberChangedSubject.send("0912345678")
        passwordChangedSubject.send("secret12")
        submitTappedSubject.send(())

        XCTAssertNotNil(receivedState?.emailError)
        XCTAssertTrue(receivedState!.hasValidationError)
        XCTAssertFalse(mockRepository.requestRegistrationOTPCalled)
    }

    func test_submitTapped_withInvalidEmail_setsEmailErrorAndDoesNotCallRepository() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        toggleTermsTappedSubject.send(())
        phoneNumberChangedSubject.send("0912345678")
        emailChangedSubject.send("not-an-email")
        passwordChangedSubject.send("secret12")
        submitTappedSubject.send(())

        XCTAssertNotNil(receivedState?.emailError)
        XCTAssertFalse(mockRepository.requestRegistrationOTPCalled)
    }

    func test_emailChanged_clearsPreviousEmailError() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        toggleTermsTappedSubject.send(())
        submitTappedSubject.send(())
        XCTAssertNotNil(receivedState?.emailError)

        emailChangedSubject.send("phapdanh@email.com")

        XCTAssertNil(receivedState?.emailError)
    }

    func test_submitTapped_withSevenCharPassword_setsPasswordError() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        toggleTermsTappedSubject.send(())
        phoneNumberChangedSubject.send("0912345678")
        emailChangedSubject.send("phapdanh@email.com")
        passwordChangedSubject.send("secret1")
        submitTappedSubject.send(())

        XCTAssertNotNil(receivedState?.passwordError)
        XCTAssertFalse(mockRepository.requestRegistrationOTPCalled)
    }

    func test_togglePasswordVisibility_flipsFlag() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        togglePasswordVisibilityTappedSubject.send(())

        XCTAssertTrue(receivedState!.isPasswordVisible)
    }

    func test_toggleTerms_flipsFlagAndEnablesSubmit() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        toggleTermsTappedSubject.send(())

        XCTAssertTrue(receivedState!.didAcceptTerms)
        XCTAssertTrue(receivedState!.isSubmitEnabled)
    }

    func test_backTapped_firesGoBackEvent() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)
        var receivedEvent: ILSignUpNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goBack)
    }

    func test_loginPromptTapped_firesGoToLoginEvent() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)
        var receivedEvent: ILSignUpNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        loginPromptTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goToLogin)
    }

    func test_submitTapped_withoutAcceptingTerms_doesNothing() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        submitTappedSubject.send(())

        XCTAssertFalse(mockRepository.requestRegistrationOTPCalled)
        XCTAssertNil(receivedState?.submitError)
    }

    func test_submitTapped_withInvalidPhone_setsValidationErrorAndDoesNotCallRepository() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        toggleTermsTappedSubject.send(())
        phoneNumberChangedSubject.send("091")
        emailChangedSubject.send("phapdanh@email.com")
        passwordChangedSubject.send("secret12")

        submitTappedSubject.send(())

        XCTAssertNotNil(receivedState?.phoneNumberError)
        XCTAssertFalse(mockRepository.requestRegistrationOTPCalled)
    }

    func test_submitTapped_withValidForm_sendsVerificationAndFiresDidRequestVerification() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        let expectation = expectation(description: "didRequestVerification")
        var receivedEvent: ILSignUpNavEvent?
        sut.navigationEventPublisher
            .sink {
                receivedEvent = $0
                expectation.fulfill()
            }
            .store(in: &cancellables)

        fillValidForm()
        submitTappedSubject.send(())

        wait(for: [expectation], timeout: 1)

        XCTAssertTrue(mockRepository.requestRegistrationOTPCalled)
        XCTAssertEqual(mockRepository.receivedEntity?.phoneNumber, "+84 912 345 678")
        XCTAssertEqual(receivedEvent, .didRequestVerification(
            phoneNumber: "+84 912 345 678",
            otpExpiresInSeconds: 90,
            resendAfterSeconds: 60
        ))
        XCTAssertFalse(receivedState!.isSubmitting)
    }

    func test_submitTapped_whenPhoneAlreadyRegistered_showsErrorAndStaysOnScreen() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        let expectation = expectation(description: "submitError")
        output.state
            .sink {
                if case .success(let model) = $0, model.submitError != nil {
                    receivedState = model
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        var receivedEvent: ILSignUpNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        mockRepository.requestRegistrationOTPError = ILSignUpError.phoneAlreadyRegistered

        fillValidForm()
        submitTappedSubject.send(())

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(receivedState?.submitError, ILSignUpError.phoneAlreadyRegistered.localizedDescription)
        XCTAssertEqual(receivedState?.isSubmitting, false)
        XCTAssertNil(receivedEvent)
    }

    func test_submitTapped_whenEmailTaken_showsErrorAndStaysOnScreen() {
        assertSubmitFailure(ILSignUpError.emailTaken)
    }

    func test_submitTapped_whenOtpLocked_showsLockedMessageAndStaysOnScreen() {
        assertSubmitFailure(ILSignUpError.otpLocked(lockedUntil: "2026-09-22T10:30:00Z"))
    }

    func test_submitTapped_whenOtpResendTooSoon_showsCooldownMessage() {
        assertSubmitFailure(ILSignUpError.otpResendTooSoon(retryAfterSeconds: 30))
    }

    func test_submitTapped_whenOffline_showsNoInternetMessageAndDoesNotNavigate() {
        assertSubmitFailure(ILSignUpError.networkUnavailable)
    }

    func test_submitTapped_whenServerFails_showsGenericMessageAndDoesNotNavigate() {
        assertSubmitFailure(ILSignUpError.server)
    }

    /// Asserts that a repository failure is surfaced as `submitError`, clears `isSubmitting`, and
    /// emits no navigation event (the v1.9 "stay on SignUp" behaviour).
    private func assertSubmitFailure(_ error: ILSignUpError, file: StaticString = #filePath, line: UInt = #line) {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        let expectation = expectation(description: "submitError")
        output.state
            .sink {
                if case .success(let model) = $0, model.submitError != nil {
                    receivedState = model
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        var receivedEvent: ILSignUpNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        mockRepository.requestRegistrationOTPError = error

        fillValidForm()
        submitTappedSubject.send(())

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(receivedState?.submitError, error.localizedDescription, file: file, line: line)
        XCTAssertEqual(receivedState?.isSubmitting, false, file: file, line: line)
        XCTAssertNil(receivedEvent, file: file, line: line)
    }
}

// MARK: - Mock ILSignUpRepository

/// Test double for `ILSignUpRepository`, replacing the old `MockILSignUpUseCase`'s network-path
/// responsibility so the tests exercise the real `ILSignUpUseCaseImpl` on top of it.
nonisolated final class MockILSignUpRepository: ILSignUpRepository {

    var requestRegistrationOTPCalled = false
    var requestRegistrationOTPCallCount = 0
    var receivedEntity: ILSignUpEntity?
    /// Set to make the next call throw. Leave `nil` for the success path.
    var requestRegistrationOTPError: Error?
    /// Returned on success — the timing the OTP screen is seeded with.
    var requestRegistrationOTPResult = ILSignUpOTPEntity(expiresInSeconds: 90, resendAfterSeconds: 60)

    func requestRegistrationOTP(_ entity: ILSignUpEntity) async throws -> ILSignUpOTPEntity {
        requestRegistrationOTPCalled = true
        requestRegistrationOTPCallCount += 1
        receivedEntity = entity

        if let error = requestRegistrationOTPError {
            throw error
        }
        return requestRegistrationOTPResult
    }
}

// MARK: - Mock ILOrdinationPlaceUseCase

nonisolated final class MockILOrdinationPlaceUseCase: ILOrdinationPlaceUseCase {
    /// Pages per search keyword (`""` = no keyword). A missing keyword answers with an empty last page.
    var pagesByQuery: [String: [[ILOrdinationPlaceEntity]]] = [:]
    private(set) var calls: [(query: String, page: Int)] = []
    var loadCallCount: Int { calls.count }

    /// Shorthand for a single page of the unfiltered list.
    var places: [ILOrdinationPlaceEntity] {
        get { pagesByQuery[""]?.first ?? [] }
        set { pagesByQuery[""] = [newValue] }
    }

    func loadPlaces(query: String, page: Int) async throws -> ILCatalogPageEntity<ILOrdinationPlaceEntity> {
        calls.append((query, page))
        let pages = pagesByQuery[query] ?? []
        let items = page <= pages.count ? pages[page - 1] : []
        return ILCatalogPageEntity(items: items, page: page, hasMore: page < pages.count)
    }
}
