//
//  ILDeviceAttestationUseCaseTests.swift
//  InnerLampTests
//
//  Covers the DeviceAttestation core service (`ILDeviceAttestationUseCaseImpl`): the full
//  attestation flow with the bypass/support gates, key persistence + reuse, the fail-closed paths,
//  and stale-key re-attestation. The Apple device capability is mocked at the repository boundary;
//  the real `ILAppAttestDataSource` (which talks to `DCAppAttestService`) is covered by manual /
//  integration testing on real hardware, not here.
//

import XCTest
@testable import InnerLamp

/// `@MainActor` so the async test methods can access the app target's MainActor-isolated types
/// (`ILDeviceAttestationEntity`, `ILDeviceAttestationUseCaseImpl`'s `static` storage keys) without
/// an `await` — the same reason `ILAlertTests` is annotated.
@MainActor
final class ILDeviceAttestationUseCaseTests: XCTestCase {

    private var repository: MockILDeviceAttestationRepository!
    private var keychainService: KeychainService!
    private var userDefaultsService: MockUserDefaultsService!
    private var sut: ILDeviceAttestationUseCaseImpl!

    override func setUp() {
        super.setUp()
        repository = MockILDeviceAttestationRepository()
        keychainService = KeychainServiceImpl()
        userDefaultsService = MockUserDefaultsService()
        sut = ILDeviceAttestationUseCaseImpl(
            repository: repository,
            keychainService: keychainService,
            userDefaultsService: userDefaultsService
        )
    }

    override func tearDown() {
        try? keychainService.delete(key: ILDeviceAttestationUseCaseImpl.keyIdKey)
        sut = nil
        userDefaultsService = nil
        keychainService = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - attestDevice: success

    func test_attestDevice_success_returnsAttestedEntityAndPersistsKey() async throws {
        repository.generateKeyResults = ["key-1"]
        repository.isAppAttestSupported = true

        let entity = try await sut.attestDevice()

        XCTAssertTrue(entity.isAttested)
        XCTAssertTrue(entity.isSupported)
        XCTAssertFalse(entity.isBypassed)
        XCTAssertEqual(entity.keyId, "key-1")

        // The key must be persisted and reused, not regenerated on the next call.
        XCTAssertEqual(try keychainService.loadString(key: ILDeviceAttestationUseCaseImpl.keyIdKey), "key-1")
        XCTAssertEqual(repository.generateKeyCallCount, 1)
        XCTAssertTrue(repository.fetchAttestationChallengeCalled)
        XCTAssertTrue(repository.attestKeyCalled)
        XCTAssertTrue(repository.submitAttestationCalled)
    }

    func test_attestDevice_reusesPersistedKeyWithoutRegenerating() async throws {
        // Pre-seed a persisted key: the flow must reuse it, not call generateKey again.
        try keychainService.save(key: ILDeviceAttestationUseCaseImpl.keyIdKey, value: "key-existing")
        repository.isAppAttestSupported = true

        let entity = try await sut.attestDevice()

        XCTAssertEqual(entity.keyId, "key-existing")
        XCTAssertTrue(entity.isAttested)
        XCTAssertEqual(repository.generateKeyCallCount, 0)
        XCTAssertEqual(repository.attestKeyReceivedKeyId, "key-existing")
    }

    // MARK: - attestDevice: support & bypass gates

    func test_attestDevice_unsupportedWithoutBypass_throwsUnsupported() async {
        repository.isAppAttestSupported = false

        do {
            _ = try await sut.attestDevice()
            XCTFail("Expected .unsupported")
        } catch let error as ILDeviceAttestationError {
            XCTAssertEqual(error, .unsupported)
        } catch {
            XCTFail("Expected ILDeviceAttestationError, got \(error)")
        }

        // Fail-closed: no key generated, no server round-trip.
        XCTAssertEqual(repository.generateKeyCallCount, 0)
        XCTAssertFalse(repository.fetchAttestationChallengeCalled)
    }

    func test_attestDevice_bypassEnabled_shortCircuitsWithoutContactingBackend() async throws {
        userDefaultsService.saveBool(key: ILDeviceAttestationUseCaseImpl.bypassKey, value: true)
        repository.isAppAttestSupported = false // bypass must win even on an unsupported device

        let entity = try await sut.attestDevice()

        XCTAssertTrue(entity.isAttested)
        XCTAssertTrue(entity.isBypassed)
        XCTAssertFalse(entity.isSupported)
        XCTAssertNil(entity.keyId)

        // No Apple call, no server call, no key generation.
        XCTAssertEqual(repository.generateKeyCallCount, 0)
        XCTAssertFalse(repository.fetchAttestationChallengeCalled)
        XCTAssertFalse(repository.attestKeyCalled)
    }

    // MARK: - attestDevice: fail-closed

    func test_attestDevice_challengeFetchFails_throwsAndDoesNotMarkAttested() async {
        repository.isAppAttestSupported = true
        repository.generateKeyResults = ["key-1"]
        repository.fetchAttestationChallengeError = ILDeviceAttestationError.challengeFailed

        do {
            _ = try await sut.attestDevice()
            XCTFail("Expected .challengeFailed")
        } catch let error as ILDeviceAttestationError {
            XCTAssertEqual(error, .challengeFailed)
        } catch {
            XCTFail("Expected ILDeviceAttestationError, got \(error)")
        }

        // Fail-closed: attestKey was never called, so nothing could be marked attested.
        XCTAssertFalse(repository.attestKeyCalled)
    }

    func test_attestDevice_serverRejectsAttestation_throwsAndDiscardsKey() async {
        repository.isAppAttestSupported = true
        repository.generateKeyResults = ["key-1"]
        repository.submitAttestationError = ILDeviceAttestationError.attestationRejected

        do {
            _ = try await sut.attestDevice()
            XCTFail("Expected .attestationRejected")
        } catch let error as ILDeviceAttestationError {
            XCTAssertEqual(error, .attestationRejected)
        } catch {
            XCTFail("Expected ILDeviceAttestationError, got \(error)")
        }

        // The rejected key is discarded so the next call re-attests fresh.
        XCTAssertFalse(keychainService.exists(key: ILDeviceAttestationUseCaseImpl.keyIdKey))
    }

    // MARK: - attestDevice: stale-key re-attest

    func test_attestDevice_staleKey_regeneratesAndReattestsOnce() async throws {
        repository.isAppAttestSupported = true
        repository.generateKeyResults = ["key-stale", "key-fresh"]
        // First attestKey call surfaces DCError.invalidKey (stale SE key); second succeeds.
        repository.attestKeyErrors = [ILDeviceAttestationError.invalidKey]

        let entity = try await sut.attestDevice()

        XCTAssertTrue(entity.isAttested)
        XCTAssertEqual(entity.keyId, "key-fresh")

        // The stale key was discarded, a new one generated, and re-attested in the same call.
        XCTAssertEqual(repository.generateKeyCallCount, 2)
        XCTAssertEqual(repository.attestKeyReceivedKeyIds, ["key-stale", "key-fresh"])
        XCTAssertEqual(try keychainService.loadString(key: ILDeviceAttestationUseCaseImpl.keyIdKey), "key-fresh")
    }

    func test_attestDevice_staleKeyTwice_throws() async {
        repository.isAppAttestSupported = true
        repository.generateKeyResults = ["key-stale", "key-stale-2"]
        // Both attestKey calls fail: regeneration is bounded to one attempt, then fail-closed.
        repository.attestKeyErrors = [ILDeviceAttestationError.invalidKey, ILDeviceAttestationError.invalidKey]

        do {
            _ = try await sut.attestDevice()
            XCTFail("Expected .assertionFailed")
        } catch let error as ILDeviceAttestationError {
            XCTAssertEqual(error, .assertionFailed)
        } catch {
            XCTFail("Expected ILDeviceAttestationError, got \(error)")
        }
    }

    // MARK: - generateAssertion

    func test_generateAssertion_success_returnsAssertion() async throws {
        try keychainService.save(key: ILDeviceAttestationUseCaseImpl.keyIdKey, value: "key-1")
        repository.generateAssertionResult = Data([0xAA, 0xBB])

        let assertion = try await sut.generateAssertion(clientData: Data("client".utf8))

        XCTAssertEqual(assertion, Data([0xAA, 0xBB]))
        XCTAssertTrue(repository.fetchAssertionChallengeCalled)
        XCTAssertEqual(repository.generateAssertionReceivedKeyId, "key-1")
        XCTAssertEqual(repository.generateAssertionReceivedClientData, Data("client".utf8))
    }

    func test_generateAssertion_noPersistedKey_throwsAssertionFailed() async {
        do {
            _ = try await sut.generateAssertion(clientData: Data("client".utf8))
            XCTFail("Expected .assertionFailed")
        } catch let error as ILDeviceAttestationError {
            XCTAssertEqual(error, .assertionFailed)
        } catch {
            XCTFail("Expected ILDeviceAttestationError, got \(error)")
        }

        // No server round-trip happened: the call fails closed before any network.
        XCTAssertFalse(repository.fetchAssertionChallengeCalled)
    }

    func test_generateAssertion_bypassEnabled_throwsBypassed() async {
        userDefaultsService.saveBool(key: ILDeviceAttestationUseCaseImpl.bypassKey, value: true)

        do {
            _ = try await sut.generateAssertion(clientData: Data("client".utf8))
            XCTFail("Expected .bypassed")
        } catch let error as ILDeviceAttestationError {
            XCTAssertEqual(error, .bypassed)
        } catch {
            XCTFail("Expected ILDeviceAttestationError, got \(error)")
        }

        XCTAssertFalse(repository.fetchAssertionChallengeCalled)
    }

    func test_generateAssertion_challengeFetchFails_throws() async throws {
        try keychainService.save(key: ILDeviceAttestationUseCaseImpl.keyIdKey, value: "key-1")
        repository.fetchAssertionChallengeError = ILDeviceAttestationError.challengeFailed

        do {
            _ = try await sut.generateAssertion(clientData: Data("client".utf8))
            XCTFail("Expected .challengeFailed")
        } catch let error as ILDeviceAttestationError {
            XCTAssertEqual(error, .challengeFailed)
        } catch {
            XCTFail("Expected ILDeviceAttestationError, got \(error)")
        }
    }
}

// MARK: - Mock ILDeviceAttestationRepository

final class MockILDeviceAttestationRepository: ILDeviceAttestationRepository {

    var isAppAttestSupported = true

    // MARK: generateKey
    var generateKeyCallCount = 0
    var generateKeyResults: [String] = []
    var generateKeyError: Error?

    func generateKey() async throws -> String {
        generateKeyCallCount += 1
        if let generateKeyError {
            throw generateKeyError
        }
        if !generateKeyResults.isEmpty {
            return generateKeyResults.removeFirst()
        }
        return "key-default"
    }

    // MARK: attestKey
    var attestKeyCalled = false
    var attestKeyReceivedKeyId: String?
    var attestKeyReceivedKeyIds: [String] = []
    var attestKeyReceivedChallenge: Data?
    var attestKeyErrors: [Error] = []
    var attestKeyResult: Data = Data([0x01])

    func attestKey(keyId: String, challenge: Data) async throws -> Data {
        attestKeyCalled = true
        attestKeyReceivedKeyId = keyId
        attestKeyReceivedKeyIds.append(keyId)
        attestKeyReceivedChallenge = challenge
        if !attestKeyErrors.isEmpty {
            throw attestKeyErrors.removeFirst()
        }
        return attestKeyResult
    }

    // MARK: generateAssertion
    var generateAssertionCalled = false
    var generateAssertionReceivedKeyId: String?
    var generateAssertionReceivedClientData: Data?
    var generateAssertionResult: Data = Data([0x02])
    var generateAssertionError: Error?

    func generateAssertion(keyId: String, clientData: Data) async throws -> Data {
        generateAssertionCalled = true
        generateAssertionReceivedKeyId = keyId
        generateAssertionReceivedClientData = clientData
        if let generateAssertionError {
            throw generateAssertionError
        }
        return generateAssertionResult
    }

    // MARK: fetchAttestationChallenge
    var fetchAttestationChallengeCalled = false
    var fetchAttestationChallengeResult: Data = Data([0x03])
    var fetchAttestationChallengeError: Error?

    func fetchAttestationChallenge() async throws -> Data {
        fetchAttestationChallengeCalled = true
        if let fetchAttestationChallengeError {
            throw fetchAttestationChallengeError
        }
        return fetchAttestationChallengeResult
    }

    // MARK: submitAttestation
    var submitAttestationCalled = false
    var submitAttestationError: Error?

    func submitAttestation(keyId: String, attestation: Data, challenge: Data) async throws {
        submitAttestationCalled = true
        if let submitAttestationError {
            throw submitAttestationError
        }
    }

    // MARK: fetchAssertionChallenge
    var fetchAssertionChallengeCalled = false
    var fetchAssertionChallengeResult: Data = Data([0x04])
    var fetchAssertionChallengeError: Error?

    func fetchAssertionChallenge() async throws -> Data {
        fetchAssertionChallengeCalled = true
        if let fetchAssertionChallengeError {
            throw fetchAssertionChallengeError
        }
        return fetchAssertionChallengeResult
    }
}

// MARK: - Mock UserDefaultsService

/// In-memory `UserDefaultsService` for controlling the bypass flag deterministically.
///
/// `@MainActor` to match the `UserDefaultsService` protocol, whose requirements are MainActor-
/// isolated by the app target's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
@MainActor
final class MockUserDefaultsService: UserDefaultsService {

    private var storage: [String: Any] = [:]

    func save<T: Codable>(key: String, value: T) {
        storage[key] = value
    }

    func load<T: Codable>(key: String, type: T.Type) -> T? {
        storage[key] as? T
    }

    func remove(key: String) {
        storage[key] = nil
    }

    func exists(key: String) -> Bool {
        storage[key] != nil
    }
}
