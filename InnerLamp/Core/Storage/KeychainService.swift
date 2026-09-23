//
//  KeychainService.swift
//  base_project
//
//  Created by ChjpCoj on 2/5/26.
//

import Foundation
import LocalAuthentication
import Security

/// `nonisolated` — the Keychain is thread-safe and holds no main-actor state, but callers such as
/// `KeychainAuthTokenProviding` read it from `NetworkServiceImpl`'s actor isolation domain.
nonisolated protocol KeychainService {
    /// Writes `data` under `key` with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
    ///
    /// Idempotent and non-destructive: an existing item is updated in place, never deleted first,
    /// so a failed write cannot lose the previous value.
    ///
    /// - Important: Stores into the *plain* namespace. ``saveProtected(key:data:flags:)`` writes
    ///   under a different `kSecAttrAccount`, so the two never overwrite each other. See
    ///   ``protectedAccount(for:)``.
    func save(key: String, data: Data) throws

    /// Reads an item written by ``save(key:data:)``.
    ///
    /// This path never shows an authentication prompt. If the account somehow holds an
    /// ACL-protected legacy item (written by an older build, before the two namespaces were
    /// separated), the read fails fast with ``KeychainError/unreadableProtectedItem`` instead of
    /// blocking on a biometric sheet.
    func load(key: String) throws -> Data

    /// Removes the credential under `key` from **both** namespaces — an access token and its
    /// protected twin are one credential, and "forget this key" means forget all of it.
    ///
    /// Deletion never requires authentication, even for ACL-protected items, and a missing item is
    /// not an error.
    func delete(key: String) throws

    /// Whether ``save(key:data:)`` has an item under `key` — the plain namespace only.
    ///
    /// Reads attributes rather than data, so it decrypts nothing and never prompts, even if the
    /// account holds an ACL-protected item.
    func exists(key: String) -> Bool

    /// Stores an item behind a Keychain access control (ACL). The item's bytes are held by the
    /// Secure Enclave / keybag under `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` and the OS
    /// refuses to return them until a biometric (or passcode, depending on `flags`) match succeeds.
    ///
    /// Unlike ``load(key:)``, this protection is enforced by the system, not by the caller.
    ///
    /// The item is written under ``protectedAccount(for:)``, a distinct `kSecAttrAccount`, so it
    /// is a different Keychain item from ``save(key:data:)``'s and the two coexist. That separation
    /// is what keeps ``load(key:)`` — and therefore every authenticated network request — from ever
    /// matching this item and triggering a prompt.
    ///
    /// Writing does not require authentication; only reading back does.
    ///
    /// - Parameter flags: `.userPresence` (the default via the convenience overload) accepts either
    ///   a biometric match or the device passcode, and plays well with the policy the read path
    ///   evaluates — see ``loadProtected(key:reason:)``. `.biometryCurrentSet` is the strictest
    ///   option: biometric-only, and the item is destroyed if the enrolled biometrics change.
    ///   `.biometryAny` allows newly enrolled biometrics.
    /// - Important: Requires a device passcode to be set. On a device without one, creation fails.
    /// - Throws: `KeychainError.accessControlCreationFailed` when the ACL cannot be built.
    func saveProtected(key: String, data: Data, flags: SecAccessControlCreateFlags) throws

    /// Reads an item written by ``saveProtected(key:data:flags:)``.
    ///
    /// Performs the Keychain read with an authentication context, so the system shows the
    /// biometric prompt as part of the lookup and releases the bytes only after a successful
    /// match. There is no separate pre-flight evaluation: one prompt, one read.
    ///
    /// - Parameter policy: the `LAPolicy` pre-checked before the read. It must be consistent with
    ///   the `flags` the item was written with, or a device that cannot satisfy the real policy
    ///   will pass the pre-check and fail inside `SecItemCopyMatching`. `.biometryCurrentSet` and
    ///   `.biometryAny` items want `.deviceOwnerAuthenticationWithBiometrics`; `.userPresence`
    ///   items want `.deviceOwnerAuthentication`.
    /// - Throws: `KeychainError.biometryNotAvailable` when the device cannot evaluate the policy,
    ///   `KeychainError.biometryFailed` when the match fails, or `KeychainError.userCancelled`
    ///   when the user dismisses the prompt.
    func loadProtected(key: String, reason: String, policy: LAPolicy) async throws -> Data

    /// Whether ``saveProtected(key:data:flags:)`` has an item under `key`. Never prompts.
    func existsProtected(key: String) -> Bool

    /// Removes only the ACL-protected item under `key`, leaving ``save(key:data:)``'s item intact.
    func deleteProtected(key: String) throws
}

enum KeychainError: Error, LocalizedError {
    case duplicateItem
    case itemNotFound
    case unexpectedStatus(OSStatus)
    case unableToConvertToData
    case unableToConvertToString
    case biometryNotAvailable
    case biometryFailed
    case userCancelled
    case accessControlCreationFailed
    /// The account holds an item whose ACL makes it unreadable without authentication, but the
    /// plain, non-prompting read path was used. Written by a build that predates the plain /
    /// protected namespace split; the next ``KeychainService/save(key:data:)`` under the same key
    /// repairs it.
    case unreadableProtectedItem

    var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "Duplicate item"
        case .itemNotFound:
            return "Item not found"
        case .unexpectedStatus(let status):
            return "Unexpected status: \(status)"
        case .unableToConvertToData:
            return "Unable to convert to data"
        case .unableToConvertToString:
            return "Unable to convert to string"
        case .biometryNotAvailable:
            return "Biometry is not available on this device"
        case .biometryFailed:
            return "Biometric authentication failed"
        case .userCancelled:
            return "Authentication was cancelled by the user"
        case .accessControlCreationFailed:
            return "Unable to create the Keychain access control"
        case .unreadableProtectedItem:
            return "Item is protected by an access control and cannot be read without authentication"
        }
    }
}

nonisolated final class KeychainServiceImpl: KeychainService {
    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "vn.weedigital.InnerLamp") {
        self.service = service
    }

    // MARK: - Namespacing

    /// Keychain item identity for `kSecClassGenericPassword` is `class` + `kSecAttrService` +
    /// `kSecAttrAccount` (+ access group). Neither `kSecAttrAccessible` nor `kSecAttrAccessControl`
    /// participates, so an ACL cannot be used to keep two values apart — they would be the *same*
    /// item and each write would clobber the other. Distinct accounts are the only reliable split.
    static func protectedAccount(for key: String) -> String {
        key + ".protected"
    }

    /// Lets the plain read path fail instead of prompting. Without it `SecItemCopyMatching` blocks
    /// and puts up a biometric sheet when the matched item carries an ACL — which is exactly what
    /// an authenticated network request must never do.
    ///
    /// Built from an `LAContext` with `interactionNotAllowed`, the supported replacement for the
    /// deprecated `kSecUseAuthenticationUI` / `kSecUseAuthenticationUIFail` pair. An item with no
    /// ACL is unaffected; one that needs authentication reports `errSecInteractionNotAllowed`.
    private static var suppressAuthenticationUIAttributes: [String: Any] {
        let context = LAContext()
        context.interactionNotAllowed = true
        return [kSecUseAuthenticationContext as String: context]
    }

    // MARK: - Plain

    func save(key: String, data: Data) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let addQuery = baseQuery(key: key).merging(attributes) { _, new in new }
        var status = SecItemAdd(addQuery as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Update in place rather than delete-then-add: a failure here leaves the previous
            // value readable instead of destroying it.
            status = SecItemUpdate(baseQuery(key: key) as CFDictionary, attributes as CFDictionary)

            // An item left under this account by a pre-namespace-split build carries its
            // protection class inside a `kSecAttrAccessControl` ACL, which cannot be replaced via
            // `kSecAttrAccessible`. Drop it — deletion needs no authentication — and write fresh.
            if status == errSecParam || status == errSecAuthFailed || status == errSecInteractionNotAllowed {
                SecItemDelete(baseQuery(key: key) as CFDictionary)
                status = SecItemAdd(addQuery as CFDictionary, nil)
            }
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func load(key: String) throws -> Data {
        let query = baseQuery(key: key).merging([
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]) { _, new in new }
            .merging(Self.suppressAuthenticationUIAttributes) { _, new in new }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        case errSecInteractionNotAllowed, errSecAuthFailed:
            throw KeychainError.unreadableProtectedItem
        default:
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.unableToConvertToData
        }

        return data
    }

    func exists(key: String) -> Bool {
        // Attributes only: requesting the data would decrypt the item, which on an ACL-protected
        // item triggers the biometric prompt — an existence check must not do that.
        let query = baseQuery(key: key).merging([
            kSecReturnAttributes as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]) { _, new in new }
            .merging(Self.suppressAuthenticationUIAttributes) { _, new in new }

        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Protected

    func saveProtected(key: String, data: Data, flags: SecAccessControlCreateFlags) throws {
        var aclError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            flags,
            &aclError
        ) else {
            throw KeychainError.accessControlCreationFailed
        }

        let account = Self.protectedAccount(for: key)
        let searchQuery = baseQuery(account: account)

        // `kSecAttrAccessControl` and `kSecAttrAccessible` are mutually exclusive — supplying both
        // is rejected with errSecParam. The protection class lives inside the ACL.
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessControl as String: accessControl
        ]

        var status = SecItemUpdate(searchQuery as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            status = SecItemAdd(searchQuery.merging(attributes) { _, new in new } as CFDictionary, nil)
        }

        // `SecItemUpdate` cannot swap an ACL: changing `flags` means the old ACL has to go.
        if status == errSecParam {
            SecItemDelete(searchQuery as CFDictionary)
            status = SecItemAdd(searchQuery.merging(attributes) { _, new in new } as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func loadProtected(key: String, reason: String, policy: LAPolicy) async throws -> Data {
        let context = LAContext()
        context.localizedCancelTitle = "Huỷ"
        context.localizedReason = reason

        var authError: NSError?
        guard context.canEvaluatePolicy(policy, error: &authError) else {
            throw KeychainError.biometryNotAvailable
        }

        let query = baseQuery(account: Self.protectedAccount(for: key)).merging([
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]) { _, new in new }

        return try await Self.copyMatching(query: query)
    }

    func existsProtected(key: String) -> Bool {
        let query = baseQuery(account: Self.protectedAccount(for: key)).merging([
            kSecReturnAttributes as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]) { _, new in new }
            .merging(Self.suppressAuthenticationUIAttributes) { _, new in new }

        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Delete

    func delete(key: String) throws {
        try delete(account: key)
        // Tolerate "not found": the credential is gone either way, which is what the caller asked.
        try? delete(account: Self.protectedAccount(for: key))
    }

    func deleteProtected(key: String) throws {
        try delete(account: Self.protectedAccount(for: key))
    }

    // MARK: - Internals

    private func baseQuery(key: String) -> [String: Any] {
        baseQuery(account: key)
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func delete(account: String) throws {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// `SecItemCopyMatching` is synchronous and, with an authentication context, does not return
    /// until the user answers the prompt. Running it on a cooperative-pool thread would block that
    /// thread for the whole interaction, so it is parked on a dedicated queue and bridged back.
    private static func copyMatching(query: [String: Any]) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result: AnyObject?
                let status = SecItemCopyMatching(query as CFDictionary, &result)

                switch status {
                case errSecSuccess:
                    guard let data = result as? Data else {
                        continuation.resume(throwing: KeychainError.unableToConvertToData)
                        return
                    }
                    continuation.resume(returning: data)
                case errSecItemNotFound:
                    continuation.resume(throwing: KeychainError.itemNotFound)
                case errSecUserCanceled:
                    continuation.resume(throwing: KeychainError.userCancelled)
                case errSecAuthFailed, errSecInteractionNotAllowed:
                    continuation.resume(throwing: KeychainError.biometryFailed)
                default:
                    continuation.resume(throwing: KeychainError.unexpectedStatus(status))
                }
            }
        }
    }
}

// Extension save string directly
nonisolated extension KeychainService {
    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unableToConvertToData
        }

        try save(key: key, data: data)
    }

    func loadString(key: String) throws -> String {
        let data = try load(key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unableToConvertToString
        }

        return string
    }
}

// Extension save codable objects
nonisolated extension KeychainService {
    func save<T: Encodable>(key: String, object: T) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try save(key: key, data: data)
    }

    func load<T: Decodable>(key: String, type: T.Type) throws -> T {
        let data = try load(key: key)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

// Extension protected variants — defaults and value-type conveniences.
nonisolated extension KeychainService {
    /// `.userPresence` — accepts either a biometric match or the device passcode. This is the
    /// policy ``loadProtected(key:reason:)`` pre-checks, so a device that has a passcode but
    /// broken, unenrolled, or absent biometrics still has a working read path instead of failing
    /// deep inside `SecItemCopyMatching`.
    ///
    /// Re-enrolling biometrics does **not** destroy the item. Pass the `flags:` overload with
    /// `.biometryCurrentSet` when the value must die with the old enrollment.
    func saveProtected(key: String, data: Data) throws {
        try saveProtected(key: key, data: data, flags: .userPresence)
    }

    /// Reads with the `.userPresence` policy — the counterpart of the default
    /// ``saveProtected(key:data:)``.
    func loadProtected(key: String, reason: String) async throws -> Data {
        try await loadProtected(key: key, reason: reason, policy: .deviceOwnerAuthentication)
    }

    /// Reads an item written with the `flags:` overload. Pass the policy that matches those flags.
    func loadProtectedString(key: String, reason: String, policy: LAPolicy) async throws -> String {
        let data = try await loadProtected(key: key, reason: reason, policy: policy)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unableToConvertToString
        }

        return string
    }

    func loadProtectedString(key: String, reason: String) async throws -> String {
        try await loadProtectedString(key: key, reason: reason, policy: .deviceOwnerAuthentication)
    }

    /// JSON-encodes `object` and stores it under `saveProtected(key:data:)`'s default policy.
    func saveProtected<T: Encodable>(key: String, object: T) throws {
        let data = try JSONEncoder().encode(object)
        try saveProtected(key: key, data: data)
    }

    /// Reads an item written by ``saveProtected(key:object:)``. Triggers the biometric prompt.
    func loadProtected<T: Decodable>(key: String, type: T.Type, reason: String) async throws -> T {
        let data = try await loadProtected(key: key, reason: reason)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
