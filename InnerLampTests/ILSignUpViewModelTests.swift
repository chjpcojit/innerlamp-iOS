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
    private var displayNameChangedSubject: PassthroughSubject<String, Never>!
    private var ordinationPlaceChangedSubject: PassthroughSubject<String, Never>!
    private var ordinationPickerOpenedSubject: PassthroughSubject<Void, Never>!
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
        displayNameChangedSubject = PassthroughSubject<String, Never>()
        ordinationPlaceChangedSubject = PassthroughSubject<String, Never>()
        ordinationPickerOpenedSubject = PassthroughSubject<Void, Never>()
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
        displayNameChangedSubject = nil
        ordinationPlaceChangedSubject = nil
        ordinationPickerOpenedSubject = nil
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
            suggestDisplayNameTapped: suggestDisplayNameTappedSubject.eraseToAnyPublisher(),
            displayNameChanged: displayNameChangedSubject.eraseToAnyPublisher(),
            ordinationPlaceChanged: ordinationPlaceChangedSubject.eraseToAnyPublisher(),
            ordinationPickerOpened: ordinationPickerOpenedSubject.eraseToAnyPublisher(),
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

    func test_ordinationPlaceChanged_updatesStateWithoutSettingAnyError() {
        let output = makeOutput()
        var receivedState: ILSignUpStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        XCTAssertEqual(receivedState?.ordinationPlace, "")

        ordinationPlaceChangedSubject.send("Chùa Hoa Nghiêm")

        XCTAssertEqual(receivedState?.ordinationPlace, "Chùa Hoa Nghiêm")
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

        sut.applyProposedPlace(ILTempleProposalEntity(name: "Chùa Pháp Hoa", province: "Đà Nẵng", address: "12 Lê Lợi"))

        XCTAssertEqual(receivedState?.ordinationPlace, "Chùa Pháp Hoa")
        XCTAssertEqual(receivedState?.ordinationPlaceOptions.first?.name, "Chùa Pháp Hoa")
        XCTAssertEqual(receivedState?.selectedOrdinationPlaceID, receivedState?.ordinationPlaceOptions.first?.id)

        ordinationPlaceChangedSubject.send("")
        XCTAssertNil(receivedState?.selectedOrdinationPlaceID)
    }

    func test_ordinationPlaceFilter_emptyQuery_showsNoneThenFirstSixPlaces() {
        let options = (1...9).map { ILOrdinationPlaceEntity(id: "t\($0)", name: "Chùa \($0)", subtitle: "") }

        let rows = ILOrdinationPlaceFilter.rows(options: options, query: "  ", noneName: "Chưa xuất gia", noneSubtitle: "Cư sĩ")

        XCTAssertEqual(rows.count, 7)
        XCTAssertTrue(rows[0].isNone)
        XCTAssertEqual(rows[6].id, "t6")
    }

    func test_ordinationPlaceFilter_query_matchesNameAndAddressIgnoringDiacriticsAndCase() {
        let options = [
            ILOrdinationPlaceEntity(id: "t1", name: "Chùa Từ Quang", subtitle: "Đà Lạt, Lâm Đồng"),
            ILOrdinationPlaceEntity(id: "t2", name: "Chùa Trấn Quốc", subtitle: "Hà Nội")
        ]

        XCTAssertEqual(ILOrdinationPlaceFilter.rows(options: options, query: "tu quang", noneName: "", noneSubtitle: "").map(\.id), ["t1"])
        XCTAssertEqual(ILOrdinationPlaceFilter.rows(options: options, query: "DA LAT", noneName: "", noneSubtitle: "").map(\.id), ["t1"])
        XCTAssertTrue(ILOrdinationPlaceFilter.rows(options: options, query: "xyz", noneName: "", noneSubtitle: "").isEmpty)
    }

    func test_submitTapped_withEmptyOrdinationPlace_stillSubmitsWithEmptyValue() {
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
        XCTAssertEqual(mockRepository.receivedEntity?.ordinationPlace, "")
    }

    func test_submitTapped_withOrdinationPlace_sendsTrimmedValue() {
        let output = makeOutput()
        output.state.sink { _ in }.store(in: &cancellables)

        let expectation = expectation(description: "didRequestVerification")
        sut.navigationEventPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        toggleTermsTappedSubject.send(())
        ordinationPlaceChangedSubject.send("  Chùa Hoa Nghiêm \n")
        phoneNumberChangedSubject.send("0912345678")
        emailChangedSubject.send("phapdanh@email.com")
        passwordChangedSubject.send("secret12")

        submitTappedSubject.send(())

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(mockRepository.receivedEntity?.ordinationPlace, "Chùa Hoa Nghiêm")
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
    var places: [ILOrdinationPlaceEntity] = []
    var loadCallCount = 0

    func loadPlaces() async throws -> [ILOrdinationPlaceEntity] {
        loadCallCount += 1
        return places
    }
}
