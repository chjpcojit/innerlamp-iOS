//
//  ILAccountProfileTests.swift
//  InnerLampTests
//
//  `GET /v1/users/me`: endpoint shape, DTO decoding of the wire shape (optional keys absent),
//  mapping, error mapping and the profile use case merge.
//

import XCTest
@testable import InnerLamp

@MainActor
final class ILAccountProfileTests: XCTestCase {

    private let path = "/v1/users/me"

    func test_endpoint_isAuthenticatedGetOnUsersMe() {
        let endpoint = UserMeEndpoint()

        XCTAssertEqual(endpoint.path, "/v1/users/me")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertTrue(endpoint.requiresAuth)
    }

    func test_repository_decodesFullPayload() async throws {
        let network = MockCatalogNetworkService()
        network.responses[path] = .success(ILCatalogFixtures.envelope(
            #"{"email":"a@b.com","email_verified":true,"phone_number":"+84901234567","full_name":"Nguyễn Bình An","dharma_name":"Diệu Tâm","ordination_temple":{"id":"temple_north_011","name":"Chùa Một Cột"},"avatar_url":"https://x.test/a.jpg","avatar_url_expires_at":"2026-10-11T07:15:00Z"}"#
        ))
        let repository = ILAccountProfileRepositoryImpl(networkService: network)

        let profile = try await repository.loadAccountProfile()

        XCTAssertEqual(profile.email, "a@b.com")
        XCTAssertTrue(profile.isEmailVerified)
        XCTAssertEqual(profile.phoneNumber, "+84901234567")
        XCTAssertEqual(profile.fullName, "Nguyễn Bình An")
        XCTAssertEqual(profile.dharmaName, "Diệu Tâm")
        XCTAssertEqual(profile.ordinationTemple, .init(id: "temple_north_011", name: "Chùa Một Cột"))
        XCTAssertEqual(profile.avatarURL, URL(string: "https://x.test/a.jpg"))
        XCTAssertNotNil(profile.avatarURLExpiresAt)
    }

    func test_repository_omittedOptionalKeys_mapToEmptyValues() async throws {
        let network = MockCatalogNetworkService()
        network.responses[path] = .success(ILCatalogFixtures.envelope(
            #"{"email":"a@b.com","email_verified":false,"phone_number":"+84901234567"}"#
        ))
        let repository = ILAccountProfileRepositoryImpl(networkService: network)

        let profile = try await repository.loadAccountProfile()

        XCTAssertEqual(profile.fullName, "")
        XCTAssertEqual(profile.dharmaName, "")
        XCTAssertNil(profile.ordinationTemple)
        XCTAssertNil(profile.avatarURL)
        XCTAssertNil(profile.avatarURLExpiresAt)
    }

    func test_errorMapping() {
        XCTAssertEqual(ILAccountProfileError.from(NetworkError.noInternetConnection), .offline)
        XCTAssertEqual(ILAccountProfileError.from(NetworkError.unauthorized), .unauthorized)
        XCTAssertEqual(ILAccountProfileError.from(NetworkError.timeout), .offline)
    }

    private func makeUseCase(accountResult: Result<ILAccountProfileEntity, Error>) -> ILProfileUseCaseImpl {
        ILProfileUseCaseImpl(
            accountRepository: StubAccountRepository(result: accountResult),
            logoutRepository: StubLogoutRepository(error: nil),
            keychainService: KeychainServiceImpl(),
            sessionDataCleaner: ILSessionDataCleanerImpl(stack: CoreDataStack(inMemory: true)),
            userDefaultsService: UserDefaultsServiceImpl(),
            accountScopedDefaultsKeys: []
        )
    }

    func test_useCase_mergesAccountIntoProfile() async throws {
        let account = ILAccountProfileEntity(
            email: "a@b.com", isEmailVerified: true, phoneNumber: "+84901234567", fullName: "Nguyễn Bình An",
            dharmaName: "Diệu Tâm", ordinationTemple: nil, avatarURL: nil, avatarURLExpiresAt: nil
        )
        let useCase = makeUseCase(accountResult: .success(account))

        let profile = try await useCase.loadProfile()

        XCTAssertEqual(profile.fullName, "Nguyễn Bình An")
        XCTAssertEqual(profile.dharmaName, "Diệu Tâm")
    }

    func test_useCase_accountWithoutFullName_fallsBackToEmail() async throws {
        let account = ILAccountProfileEntity(
            email: "a@b.com", isEmailVerified: true, phoneNumber: "+84901234567", fullName: "",
            dharmaName: "", ordinationTemple: nil, avatarURL: nil, avatarURLExpiresAt: nil
        )
        let useCase = makeUseCase(accountResult: .success(account))

        let profile = try await useCase.loadProfile()

        XCTAssertEqual(profile.fullName, "a@b.com")
    }

    func test_useCase_propagatesRepositoryFailure() async {
        let useCase = makeUseCase(accountResult: .failure(ILAccountProfileError.unauthorized))

        do {
            _ = try await useCase.loadProfile()
            XCTFail("expected throw")
        } catch {
            XCTAssertEqual(error as? ILAccountProfileError, .unauthorized)
        }
    }
}

private struct StubAccountRepository: ILAccountProfileRepository {
    let result: Result<ILAccountProfileEntity, Error>
    func loadAccountProfile() async throws -> ILAccountProfileEntity { try result.get() }
}

private struct StubLogoutRepository: ILLogoutRepository {
    let error: Error?
    func revokeSession() async throws { if let error { throw error } }
}
