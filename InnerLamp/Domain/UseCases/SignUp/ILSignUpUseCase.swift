//
//  ILSignUpUseCase.swift
//  InnerLamp
//

import Foundation

enum ILSignUpError: Error, LocalizedError, Equatable {
    case phoneAlreadyRegistered
    case emailTaken
    case otpLocked(lockedUntil: String?)
    case otpSendLimited(lockedUntil: String?)
    case otpResendTooSoon(retryAfterSeconds: Int?)
    case smsSendFailed
    case invalidInput
    case server
    case networkUnavailable
    case timedOut

    var errorDescription: String? {
        switch self {
        case .phoneAlreadyRegistered:
            return "signup.error.phoneTaken".localized
        case .emailTaken:
            return "signup.error.emailTaken".localized
        case .otpLocked(let lockedUntil):
            guard let formatted = ILUnlockTimeFormatter.displayString(from: lockedUntil) else {
                return "signup.error.otpLocked".localized
            }
            return String(format: "signup.error.otpLockedUntil".localized, formatted)
        case .otpSendLimited(let lockedUntil):
            guard let formatted = ILUnlockTimeFormatter.displayString(from: lockedUntil) else {
                return "signup.error.otpSendLimited".localized
            }
            return String(format: "signup.error.otpSendLimitedUntil".localized, formatted)
        case .otpResendTooSoon(let retryAfterSeconds):
            guard let retryAfterSeconds else {
                return "signup.error.otpResendTooSoon".localized
            }
            return String(format: "signup.error.otpResendTooSoonSeconds".localized, retryAfterSeconds)
        case .smsSendFailed:
            return "signup.error.smsSendFailed".localized
        case .invalidInput:
            return "signup.error.invalidInput".localized
        case .server:
            return "error.generic".localized
        case .networkUnavailable:
            return "error.no_internet".localized
        case .timedOut:
            return "signup.error.timedOut".localized
        }
    }
}

protocol ILSignUpUseCase {
    func getInitialState() -> ILSignUpStateModel

    /// Danh sách pháp danh gợi ý cho nút "Gợi ý" — khớp `NAMES` trong design handoff. Field
    /// "Pháp danh hoặc tên gọi" chỉ chọn từ danh sách này, không có ô nhập tự do.
    var dharmaNameSuggestions: [String] { get }

    /// Trả về message lỗi (`nil` nếu hợp lệ). Chạy mỗi lần bấm "Gửi mã xác thực", không chạy
    /// theo từng ký tự gõ.
    func validateDisplayName(_ value: String) -> String?
    /// `nationalDigits`/`country` lấy từ `ILSignUpStateModel` — số hợp lệ khi đủ chữ số tối
    /// thiểu–tối đa của quốc gia đang chọn (`country.nationalDigitRange`), không còn cố định theo VN.
    func validatePhoneNumber(nationalDigits: String, country: ILCountry) -> String?
    /// Email bắt buộc — rỗng hoặc sai định dạng đều trả lỗi và chặn submit.
    func validateEmail(_ value: String) -> String?
    func validatePassword(_ value: String) -> String?

    /// `nil` khi password rỗng — chạy theo từng ký tự gõ để cập nhật `ILStrengthMeterView` live.
    func passwordStrength(for value: String) -> ILPasswordStrength?

    /// Gửi mã OTP xác thực số điện thoại qua `POST /v1/auth/register/request-otp`.
    ///
    /// Trả về timing của server (`expires_in_seconds`/`resend_after_seconds`) để màn OTP khởi tạo
    /// countdown và câu hiển thị hạn mã bằng giá trị thật thay vì hardcode.
    ///
    /// Throws an `ILSignUpError` case — `phoneAlreadyRegistered`/`emailTaken` when the phone or
    /// email already has an account, the 429 lock/cooldown/cap cases, `smsSendFailed`, the shared
    /// network/server cases.
    func sendVerificationCode(displayName: String, ordinationPlace: String, phoneNumber: String, email: String, password: String) async throws -> ILSignUpOTPEntity
}

final class ILSignUpUseCaseImpl: ILSignUpUseCase {

    private let repository: ILSignUpRepository

    init(repository: ILSignUpRepository) {
        self.repository = repository
    }

    let dharmaNameSuggestions: [String] = [
        "Diệu Tâm", "Tịnh An", "Minh Đăng", "Huệ Nhẫn", "Chân Như",
        "Thiện Duyên", "Giác Ngộ", "Liên Hoa", "Từ Quang", "An Lạc"
    ]

    func getInitialState() -> ILSignUpStateModel {
        var state = ILSignUpStateModel.initial
        state.displayName = dharmaNameSuggestions[0]
        return state
    }

    func validateDisplayName(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "signup.error.displayNameRequired".localized }
        return nil
    }

    func validatePhoneNumber(nationalDigits: String, country: ILCountry) -> String? {
        guard !nationalDigits.isEmpty else { return "signup.error.phoneRequired".localized }
        guard country.isValidNationalDigitCount(nationalDigits.count) else {
            return "signup.error.phoneInvalid".localized
        }
        return nil
    }

    func validateEmail(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "signup.error.emailRequired".localized }
        guard ILEmailValidator.isValid(trimmed) else {
            return "signup.error.emailInvalid".localized
        }
        return nil
    }

    static let minimumPasswordLength = 8

    func validatePassword(_ value: String) -> String? {
        guard !value.isEmpty else { return "signup.error.passwordRequired".localized }
        guard value.count >= Self.minimumPasswordLength else { return "signup.error.passwordTooShort".localized }
        return nil
    }

    func passwordStrength(for value: String) -> ILPasswordStrength? {
        guard !value.isEmpty else { return nil }

        var score = 0
        if value.count >= Self.minimumPasswordLength { score += 1 }
        if value.count >= 10 { score += 1 }
        if value.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if value.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { score += 1 }

        switch score {
        case 0...1: return .weak
        case 2: return .fair
        default: return .strong
        }
    }

    func sendVerificationCode(displayName: String, ordinationPlace: String, phoneNumber: String, email: String, password: String) async throws -> ILSignUpOTPEntity {
        let entity = ILSignUpEntity(
            displayName: displayName,
            ordinationPlace: ordinationPlace,
            phoneNumber: phoneNumber,
            email: email,
            password: password
        )
        return try await repository.requestRegistrationOTP(entity)
    }
}
