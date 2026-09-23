//
//  ILLoginUseCase.swift
//  InnerLamp
//

import Foundation

enum ILLoginError: Error, LocalizedError {
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "login.error.invalidCredentials".localized
        }
    }
}

protocol ILLoginUseCase {
    func getInitialState() -> ILLoginStateModel

    /// Trả về message lỗi (`nil` nếu hợp lệ). Chạy mỗi lần bấm "Đăng nhập", không chạy
    /// theo từng ký tự gõ. `nationalDigits`/`country` lấy từ `ILLoginStateModel` — cùng quy tắc
    /// với `ILSignUpUseCase.validatePhoneNumber`.
    func validatePhone(nationalDigits: String, country: ILCountry) -> String?
    func validatePassword(_ value: String) -> String?

    /// Đăng nhập bằng số điện thoại + mật khẩu.
    ///
    /// Out of scope for `il-screen-builder` — cần network call (Auth API) thật để so khớp tài
    /// khoản, nên giữ nguyên dạng stub cho tới khi có API thật — xem
    /// `references/data_layer_boundaries.md`. Không giả lập bằng Keychain/UserDefaults (đó vẫn
    /// là một local Repository call, không được phép implement thật ở đây — xem Changelog trong
    /// `Presentation/Scenes/Login/README.md`).
    func login(_ credential: ILLoginEntity) async throws
}

final class ILLoginUseCaseImpl: ILLoginUseCase {

    // TODO: inject NetworkService/Repository thật khi implement `login` thật — không inject sẵn
    // ở đây vì hiện chưa có logic thật nào trong file này cần dùng tới, xem
    // `references/data_layer_boundaries.md`.
    init() {}

    func getInitialState() -> ILLoginStateModel {
        ILLoginStateModel.initial
    }

    func validatePhone(nationalDigits: String, country: ILCountry) -> String? {
        guard !nationalDigits.isEmpty else { return "login.error.phoneRequired".localized }
        guard country.isValidNationalDigitCount(nationalDigits.count) else {
            return "login.error.phoneInvalid".localized
        }
        return nil
    }

    func validatePassword(_ value: String) -> String? {
        guard !value.isEmpty else { return "login.error.passwordRequired".localized }
        return nil
    }

    func login(_ credential: ILLoginEntity) async throws {
        print("TODO: implement login — network/repository call, not built by il-screen-builder")
    }
}
