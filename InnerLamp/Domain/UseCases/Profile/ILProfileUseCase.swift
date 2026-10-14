//
//  ILProfileUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILProfileUseCase {
    /// Local placeholder: account fields empty, stats still mock (no stats API yet).
    func getProfile() -> ILProfileEntity
    /// `getProfile()` with the account fields (`GET /v1/users/me`) filled in from the server.
    func loadProfile() async throws -> ILProfileEntity
    /// Ends the signed-in session: revokes it on the server (best effort — a failed revoke never
    /// keeps the user signed in) then clears the stored tokens, the local user and the other
    /// account-scoped local data (birth profile, memorial cache, chosen temple). Throws
    /// `ILProfileLogoutError.storageFailed` only when the local session could not be cleared.
    func logout() async throws
}

enum ILProfileLogoutError: Error, Equatable {
    /// The Keychain / local user store refused the delete — the device may still hold a session.
    case storageFailed
}

final class ILProfileUseCaseImpl: ILProfileUseCase {

    private let accountRepository: ILAccountProfileRepository
    private let logoutRepository: ILLogoutRepository
    private let keychainService: KeychainService
    private let sessionDataCleaner: ILSessionDataCleaner
    private let userDefaultsService: UserDefaultsService
    /// `UserDefaultsService` keys that hold account-scoped values (e.g. the chosen temple).
    private let accountScopedDefaultsKeys: [String]

    init(
        accountRepository: ILAccountProfileRepository,
        logoutRepository: ILLogoutRepository,
        keychainService: KeychainService,
        sessionDataCleaner: ILSessionDataCleaner,
        userDefaultsService: UserDefaultsService,
        accountScopedDefaultsKeys: [String]
    ) {
        self.accountRepository = accountRepository
        self.logoutRepository = logoutRepository
        self.keychainService = keychainService
        self.sessionDataCleaner = sessionDataCleaner
        self.userDefaultsService = userDefaultsService
        self.accountScopedDefaultsKeys = accountScopedDefaultsKeys
    }

    func logout() async throws {
        // Revoke first: the call needs the access token that is deleted below. The result is
        // ignored on purpose — offline / 5xx must not trap the user in a session they asked to
        // leave; the server session then simply expires on its own (TD-Profile-004). A guest has
        // no token, so there is nothing to revoke.
        if keychainService.exists(key: KeychainAuthTokenProviding.accessTokenKey) {
            try? await logoutRepository.revokeSession()
        }

        do {
            try deleteIgnoringMissing(key: KeychainAuthTokenProviding.accessTokenKey)
            try deleteIgnoringMissing(key: KeychainAuthTokenProviding.refreshTokenKey)
            try await sessionDataCleaner.clearUserScopedData()
            accountScopedDefaultsKeys.forEach(userDefaultsService.remove(key:))
        } catch {
            throw ILProfileLogoutError.storageFailed
        }
    }

    private func deleteIgnoringMissing(key: String) throws {
        do {
            try keychainService.delete(key: key)
        } catch KeychainError.itemNotFound {
            // Already gone — the goal of the delete is met.
        }
    }

    func loadProfile() async throws -> ILProfileEntity {
        let account = try await accountRepository.loadAccountProfile()
        var profile = getProfile()
        // Accounts registered before `full_name` became required have none — fall back to the email,
        // the only other always-present identity field.
        profile.fullName = account.fullName.isEmpty ? account.email : account.fullName
        profile.dharmaName = account.dharmaName
        return profile
    }

    func getProfile() -> ILProfileEntity {
        // TODO: chưa có API hồ sơ / thống kê / dấu ấn được xác nhận — thay dữ liệu mẫu bên dưới bằng
        // ILProfileRepository (ILUserRepository + network) khi có contract (dùng data-builder).
        ILProfileEntity(
            fullName: "profile.mock.fullName".localized,
            dharmaName: "profile.mock.dharmaName".localized,
            practiceStats: ILProfilePracticeStatsEntity(totalHours: 168, streakDays: 42, chantCount: 9_700),
            // 12 tuần × 7 ngày, mọi ngày đều có ghi chép (mức 1...9) — khớp dữ liệu mẫu của prototype.
            journalEntriesPerDay: (0..<84).map { ($0 * 37) % 9 + 1 },
            recentBadges: [
                ILProfileBadgeEntity(
                    id: "badge.mala108",
                    title: "profile.mock.badge.mala.title".localized,
                    subtitle: "profile.mock.badge.mala.subtitle".localized,
                    category: .mala
                ),
                ILProfileBadgeEntity(
                    id: "badge.retreat30",
                    title: "profile.mock.badge.streak.title".localized,
                    subtitle: "profile.mock.badge.streak.subtitle".localized,
                    category: .streak
                ),
                ILProfileBadgeEntity(
                    id: "badge.vulan",
                    title: "profile.mock.badge.offering.title".localized,
                    subtitle: "profile.mock.badge.offering.subtitle".localized,
                    category: .offering
                )
            ],
            totalBadgeCount: 18,
            offeringCount: 7,
            lanternCount: 3,
            plan: .free,
            reminder: ILProfileReminderEntity(hour: 5, minute: 30, activeDayCount: 6),
            community: ILProfileCommunityEntity(id: "sangha.tuquang", name: "profile.mock.community.name".localized)
        )
    }
}
