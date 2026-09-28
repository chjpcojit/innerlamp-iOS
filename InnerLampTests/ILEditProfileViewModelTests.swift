//
//  ILEditProfileViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILEditProfileViewModelTests: XCTestCase {

    private var mockUseCase: MockILEditProfileUseCase!
    private var sut: ILEditProfileViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var saveTappedSubject: PassthroughSubject<Void, Never>!
    private var changeAvatarTappedSubject: PassthroughSubject<Void, Never>!
    private var displayNameChangedSubject: PassthroughSubject<String, Never>!
    private var templeNameChangedSubject: PassthroughSubject<String, Never>!
    private var bioChangedSubject: PassthroughSubject<String, Never>!
    private var visibilityTappedSubject: PassthroughSubject<ILEditProfileVisibilityItem, Never>!
    private var changePasswordTappedSubject: PassthroughSubject<Void, Never>!
    private var deleteAccountTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILEditProfileUseCase()
        sut = ILEditProfileViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        saveTappedSubject = PassthroughSubject<Void, Never>()
        changeAvatarTappedSubject = PassthroughSubject<Void, Never>()
        displayNameChangedSubject = PassthroughSubject<String, Never>()
        templeNameChangedSubject = PassthroughSubject<String, Never>()
        bioChangedSubject = PassthroughSubject<String, Never>()
        visibilityTappedSubject = PassthroughSubject<ILEditProfileVisibilityItem, Never>()
        changePasswordTappedSubject = PassthroughSubject<Void, Never>()
        deleteAccountTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        backTappedSubject = nil
        saveTappedSubject = nil
        changeAvatarTappedSubject = nil
        displayNameChangedSubject = nil
        templeNameChangedSubject = nil
        bioChangedSubject = nil
        visibilityTappedSubject = nil
        changePasswordTappedSubject = nil
        deleteAccountTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILEditProfileViewModel.Input {
        ILEditProfileViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            saveTapped: saveTappedSubject.eraseToAnyPublisher(),
            changeAvatarTapped: changeAvatarTappedSubject.eraseToAnyPublisher(),
            displayNameChanged: displayNameChangedSubject.eraseToAnyPublisher(),
            templeNameChanged: templeNameChangedSubject.eraseToAnyPublisher(),
            bioChanged: bioChangedSubject.eraseToAnyPublisher(),
            visibilityTapped: visibilityTappedSubject.eraseToAnyPublisher(),
            changePasswordTapped: changePasswordTappedSubject.eraseToAnyPublisher(),
            deleteAccountTapped: deleteAccountTappedSubject.eraseToAnyPublisher()
        )
    }

    /// Subscribes to `output.state` and returns a closure giving the latest `.success` model.
    private func bindLatestModel() -> () -> ILEditProfileStateModel? {
        var latest: ILEditProfileStateModel?
        sut.transform(input: makeInput()).state
            .sink { state in
                if case .success(let model) = state { latest = model }
            }
            .store(in: &cancellables)
        return { latest }
    }

    private func collectNavigationEvents() -> () -> [ILEditProfileNavEvent] {
        var events: [ILEditProfileNavEvent] = []
        sut.navigationEventPublisher
            .sink { events.append($0) }
            .store(in: &cancellables)
        return { events }
    }

    // MARK: - Initial state / viewDidLoad

    func test_viewDidLoad_mapsEntityToStateModel() {
        let latest = bindLatestModel()

        viewDidLoadSubject.send(())

        let model = latest()
        XCTAssertTrue(mockUseCase.getProfileCalled)
        XCTAssertEqual(model?.displayName, "Diệu Tâm")
        XCTAssertEqual(model?.initials, "DT")
        XCTAssertEqual(model?.phoneNumber, "+84 912 345 678")
        XCTAssertEqual(model?.templeName, "Đạo tràng Từ Quang")
        XCTAssertEqual(model?.bio, "Bio")
        XCTAssertEqual(model?.streakVisibilityTitle, ILEditProfileViewModel.visibilityTitle(.publicToSangha))
        XCTAssertEqual(model?.journalVisibilityTitle, ILEditProfileViewModel.visibilityTitle(.onlyMe))
        XCTAssertEqual(model?.offeringHistoryVisibilityTitle, ILEditProfileViewModel.visibilityTitle(.anonymous))
        XCTAssertNil(model?.displayNameError)
        XCTAssertEqual(model?.isSaving, false)
    }

    // MARK: - Field changes

    func test_displayNameChanged_updatesNameAndInitials() {
        let latest = bindLatestModel()

        displayNameChangedSubject.send("Tâm Minh An")

        XCTAssertEqual(latest()?.displayName, "Tâm Minh An")
        XCTAssertEqual(latest()?.initials, "TA")
    }

    func test_displayNameChanged_clearsPreviousError() {
        let latest = bindLatestModel()
        displayNameChangedSubject.send("   ")
        saveTappedSubject.send(())
        XCTAssertNotNil(latest()?.displayNameError)

        displayNameChangedSubject.send("A")

        XCTAssertNil(latest()?.displayNameError)
    }

    func test_templeNameChanged_updatesTempleName() {
        let latest = bindLatestModel()

        templeNameChangedSubject.send("Chùa Giác Ngộ")

        XCTAssertEqual(latest()?.templeName, "Chùa Giác Ngộ")
    }

    func test_bioChanged_updatesBio() {
        let latest = bindLatestModel()

        bioChangedSubject.send("Mới")

        XCTAssertEqual(latest()?.bio, "Mới")
    }

    // MARK: - Save

    func test_saveTapped_withEmptyName_setsErrorAndDoesNotSave() {
        let latest = bindLatestModel()
        let events = collectNavigationEvents()
        displayNameChangedSubject.send("  ")

        saveTappedSubject.send(())

        XCTAssertEqual(mockUseCase.validatedNames.last, "  ")
        XCTAssertEqual(
            latest()?.displayNameError,
            ILEditProfileViewModel.message(for: .displayNameRequired)
        )
        XCTAssertFalse(mockUseCase.saveProfileCalled)
        XCTAssertTrue(events().isEmpty)
    }

    func test_saveTapped_withValidForm_savesTrimmedProfileAndFiresSaved() {
        let saved = expectation(description: "saved nav event")
        sut.navigationEventPublisher
            .sink { event in if case .saved = event { saved.fulfill() } }
            .store(in: &cancellables)
        _ = bindLatestModel()
        displayNameChangedSubject.send("  Tâm Minh ")
        templeNameChangedSubject.send("Chùa Giác Ngộ ")
        bioChangedSubject.send(" Mới ")

        saveTappedSubject.send(())

        wait(for: [saved], timeout: 1)
        XCTAssertEqual(mockUseCase.savedProfile?.displayName, "Tâm Minh")
        XCTAssertEqual(mockUseCase.savedProfile?.templeName, "Chùa Giác Ngộ")
        XCTAssertEqual(mockUseCase.savedProfile?.bio, "Mới")
        // Read-only fields are carried over unchanged.
        XCTAssertEqual(mockUseCase.savedProfile?.phoneNumber, "+84 912 345 678")
        XCTAssertEqual(mockUseCase.savedProfile?.journalVisibility, .onlyMe)
    }

    func test_saveTapped_whenSaveFails_emitsFailureAndResetsSaving() {
        struct SaveError: Error {}
        mockUseCase.saveError = SaveError()
        let failed = expectation(description: "failure state")
        var latestModel: ILEditProfileStateModel?
        sut.transform(input: makeInput()).state
            .sink { state in
                switch state {
                case .failure: failed.fulfill()
                case .success(let model): latestModel = model
                default: break
                }
            }
            .store(in: &cancellables)
        let events = collectNavigationEvents()

        saveTappedSubject.send(())

        wait(for: [failed], timeout: 1)
        XCTAssertTrue(mockUseCase.saveProfileCalled)
        XCTAssertEqual(latestModel?.isSaving, false)
        XCTAssertEqual(events(), [])
    }

    // MARK: - Navigation

    func test_backTapped_firesGoBack() {
        _ = bindLatestModel()
        let events = collectNavigationEvents()

        backTappedSubject.send(())

        XCTAssertEqual(events(), [.goBack])
    }

    func test_changeAvatarTapped_firesChangeAvatar() {
        _ = bindLatestModel()
        let events = collectNavigationEvents()

        changeAvatarTappedSubject.send(())

        XCTAssertEqual(events(), [.changeAvatar])
    }

    func test_visibilityTapped_firesOpenVisibilityWithItem() {
        _ = bindLatestModel()
        let events = collectNavigationEvents()

        visibilityTappedSubject.send(.journal)

        XCTAssertEqual(events(), [.openVisibility(.journal)])
    }

    func test_changePasswordTapped_firesChangePassword() {
        _ = bindLatestModel()
        let events = collectNavigationEvents()

        changePasswordTappedSubject.send(())

        XCTAssertEqual(events(), [.changePassword])
    }

    func test_deleteAccountTapped_firesDeleteAccount() {
        _ = bindLatestModel()
        let events = collectNavigationEvents()

        deleteAccountTappedSubject.send(())

        XCTAssertEqual(events(), [.deleteAccount])
    }

    // MARK: - Helpers

    func test_initials_handlesEdgeCases() {
        XCTAssertEqual(ILEditProfileViewModel.initials(of: "Diệu Tâm"), "DT")
        XCTAssertEqual(ILEditProfileViewModel.initials(of: "nguyễn bình an"), "NA")
        XCTAssertEqual(ILEditProfileViewModel.initials(of: "An"), "A")
        XCTAssertEqual(ILEditProfileViewModel.initials(of: "   "), "")
    }

    func test_useCaseImpl_validateDisplayName() {
        let useCase = ILEditProfileUseCaseImpl()
        XCTAssertEqual(useCase.validateDisplayName(""), .displayNameRequired)
        XCTAssertEqual(useCase.validateDisplayName(" \n "), .displayNameRequired)
        XCTAssertNil(useCase.validateDisplayName("Diệu Tâm"))
    }
}

// MARK: - Mock ILEditProfileUseCase
final class MockILEditProfileUseCase: ILEditProfileUseCase {
    var getProfileCalled = false
    var validatedNames: [String] = []
    var saveProfileCalled = false
    var savedProfile: ILEditProfileEntity?
    var saveError: Error?

    var profileToReturn = ILEditProfileEntity(
        displayName: "Diệu Tâm",
        phoneNumber: "+84 912 345 678",
        templeName: "Đạo tràng Từ Quang",
        bio: "Bio",
        streakVisibility: .publicToSangha,
        journalVisibility: .onlyMe,
        offeringHistoryVisibility: .anonymous
    )

    func getProfile() -> ILEditProfileEntity {
        getProfileCalled = true
        return profileToReturn
    }

    func validateDisplayName(_ name: String) -> ILEditProfileValidationError? {
        validatedNames.append(name)
        return name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .displayNameRequired : nil
    }

    func saveProfile(_ profile: ILEditProfileEntity) async throws {
        saveProfileCalled = true
        savedProfile = profile
        if let saveError { throw saveError }
    }
}
