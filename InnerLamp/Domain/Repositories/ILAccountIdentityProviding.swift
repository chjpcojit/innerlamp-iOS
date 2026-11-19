//
//  ILAccountIdentityProviding.swift
//  InnerLamp
//

import Foundation

/// EN: Identifies the account that owns account-scoped local data (memorial cache today). Every
/// read of such data must be filtered by this id; `nil` means "not signed in", never "all accounts".
/// VI: Xác định tài khoản sở hữu dữ liệu local theo tài khoản (hiện là cache sổ giỗ). Mọi lần đọc
/// dữ liệu đó phải lọc theo id này; `nil` nghĩa là "chưa đăng nhập", không bao giờ là "mọi tài khoản".
nonisolated protocol ILAccountIdentityProviding {
    func currentAccountID() async -> String?
}

/// The signed-in user's server id. The user row is stored by `ILUserRepository` on login and
/// removed on logout, so it follows the session without a second source of truth.
nonisolated final class ILUserAccountIdentityProvider: ILAccountIdentityProviding {

    private let userRepository: ILUserRepository

    init(userRepository: ILUserRepository) {
        self.userRepository = userRepository
    }

    func currentAccountID() async -> String? {
        guard let user = try? await userRepository.loadUser(), user.id > 0 else { return nil }
        return String(user.id)
    }
}

/// Test/temporary implementation. Production code must use `ILUserAccountIdentityProvider`; this
/// type exists so a cache test can switch accounts deterministically.
nonisolated final class ILFixedAccountIdentityProvider: ILAccountIdentityProviding {

    var accountID: String?

    init(accountID: String?) {
        self.accountID = accountID
    }

    func currentAccountID() async -> String? { accountID }
}
