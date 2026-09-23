//
//  ILForgotPasswordUseCase.swift
//  InnerLamp
//

import Foundation

enum ILForgotPasswordError: Error, LocalizedError {
    case contactNotFound

    var errorDescription: String? {
        switch self {
        case .contactNotFound:
            return "forgot.error.contactNotFound".localized
        }
    }
}

protocol ILForgotPasswordUseCase {
    func getInitialState() -> ILForgotPasswordEntity

    /// Gửi hướng dẫn đặt lại mật khẩu tới `contact` (số điện thoại hoặc email tùy `method`).
    ///
    /// Out of scope for `il-screen-builder` — cần network call (Auth API) thật để gửi SMS/email,
    /// nên giữ nguyên dạng stub cho tới khi có API thật — xem
    /// `references/data_layer_boundaries.md`.
    func sendResetInstructions(method: ILForgotPasswordMethod, contact: String) async throws
}

final class ILForgotPasswordUseCaseImpl: ILForgotPasswordUseCase {

    // TODO: inject NetworkService/Repository thật khi implement `sendResetInstructions` thật —
    // không inject sẵn ở đây vì hiện chưa có logic thật nào trong file này cần dùng tới, xem
    // `references/data_layer_boundaries.md`.
    init() {}

    /// Out of scope for `il-screen-builder` — nạp số điện thoại/email đã đăng ký cần một local
    /// Repository call (Keychain) hoặc Auth API thật, cả hai đều không được phép implement thật
    /// ở đây (xem `references/data_layer_boundaries.md`). Trả về entity rỗng cho tới khi có
    /// contract thật; `ILForgotPasswordStateModel` vẫn render đúng (thẻ lựa chọn hiện trống,
    /// `isSubmitEnabled` là `false` cho tới khi có dữ liệu).
    func getInitialState() -> ILForgotPasswordEntity {
        ILForgotPasswordEntity.empty
    }

    func sendResetInstructions(method: ILForgotPasswordMethod, contact: String) async throws {
        print("TODO: implement sendResetInstructions — network/repository call, not built by il-screen-builder")
    }
}
