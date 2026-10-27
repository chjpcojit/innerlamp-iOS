//
//  ILSignUpUseCase.swift
//  InnerLamp
//

import Foundation

enum ILSignUpError: Error, LocalizedError, Equatable {
    case phoneAlreadyRegistered
    /// EN: `REGISTRATION_IN_PROGRESS` — another pending registration holds this email with a live code
    ///     and different details; `details.retry_after_seconds` is the wait (criterion 16a).
    /// VI: `REGISTRATION_IN_PROGRESS` — một đăng ký đang chờ giữ email này với mã còn sống và dữ liệu
    ///     khác; `details.retry_after_seconds` là thời gian chờ (tiêu chí 16a).
    case registrationInProgress(retryAfterSeconds: Int?)
    case rateLimited(retryAfterSeconds: Int?)
    case invalidEmail
    case invalidPhone
    case invalidPassword
    case invalidFullName
    case invalidDharmaName
    case invalidInput
    /// The picked ordination temple is unknown to the server (`INVALID_TEMPLE`) — e.g. removed
    /// from the catalog since the list was loaded. The user must pick again.
    case invalidTemple
    case server
    case networkUnavailable
    case timedOut

    var errorDescription: String? {
        switch self {
        case .phoneAlreadyRegistered:
            return "signup.error.phoneTaken".localized
        case .registrationInProgress(let retryAfterSeconds):
            guard let retryAfterSeconds, retryAfterSeconds > 0 else {
                return "signup.error.registrationInProgress".localized
            }
            return String(format: "signup.error.registrationInProgressSeconds".localized, retryAfterSeconds)
        case .rateLimited(let retryAfterSeconds):
            return ILRateLimitMessage.text(retryAfterSeconds: retryAfterSeconds)
        case .invalidEmail:
            return "signup.error.emailInvalid".localized
        case .invalidPhone:
            return "signup.error.phoneInvalid".localized
        case .invalidPassword:
            return "signup.error.passwordLength".localized
        case .invalidFullName:
            return "signup.error.fullNameInvalid".localized
        case .invalidDharmaName:
            return "signup.error.displayNameTooLong".localized
        case .invalidInput:
            return "signup.error.invalidInput".localized
        case .invalidTemple:
            return "signup.error.invalidTemple".localized
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

    /// EN: Suggestions for the "Gợi ý" chip (criterion 8); the user may keep, edit or clear the value.
    /// VI: Danh sách gợi ý cho nút "Gợi ý" (tiêu chí 8); người dùng có thể giữ, sửa hoặc xoá.
    var dharmaNameSuggestions: [String] { get }

    /// EN: Full name is required, 1–300 characters after trimming (BR-ONB-07).
    /// VI: Họ và tên bắt buộc, 1–300 ký tự sau khi cắt khoảng trắng (BR-ONB-07).
    func validateFullName(_ value: String) -> String?
    /// EN: Dharma name is optional, at most 255 characters after trimming (BR-ONB-07).
    /// VI: Pháp danh không bắt buộc, tối đa 255 ký tự sau khi cắt khoảng trắng (BR-ONB-07).
    func validateDisplayName(_ value: String) -> String?
    /// `nationalDigits`/`country` lấy từ `ILSignUpStateModel` — số hợp lệ khi đủ chữ số tối
    /// thiểu–tối đa của quốc gia đang chọn (`country.nationalDigitRange`), không còn cố định theo VN.
    func validatePhoneNumber(nationalDigits: String, country: ILCountry) -> String?
    /// EN: Email is required: trimmed, at most 254 characters, matched by `ILEmailValidator` (BR-ONB-05).
    /// VI: Email bắt buộc: cắt khoảng trắng, tối đa 254 ký tự, khớp `ILEmailValidator` (BR-ONB-05).
    func validateEmail(_ value: String) -> String?
    func validatePassword(_ value: String) -> String?

    /// `nil` khi password rỗng — chạy theo từng ký tự gõ để cập nhật `ILStrengthMeterView` live.
    func passwordStrength(for value: String) -> ILPasswordStrength?

    /// EN: Sends the registration and asks for an email code via `POST /v1/auth/register/request-otp`.
    /// VI: Gửi đăng ký và yêu cầu mã qua email bằng `POST /v1/auth/register/request-otp`.
    ///
    /// Trả về timing của server (`expires_in_seconds`/`resend_after_seconds`) để màn OTP khởi tạo
    /// countdown và câu hiển thị hạn mã bằng giá trị thật thay vì hardcode.
    ///
    /// Throws an `ILSignUpError` case — `phoneAlreadyRegistered`, `registrationInProgress`,
    /// `rateLimited`, a per-field invalid case, or the shared network/server cases.
    func sendVerificationCode(_ entity: ILSignUpEntity) async throws -> ILSignUpOTPEntity
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

    static let maximumFullNameLength = 300
    static let maximumDharmaNameLength = 255
    static let maximumEmailLength = 254

    /// EN: The dharma name starts empty (criterion 7); "Gợi ý" fills it.
    /// VI: Pháp danh để trống lúc mở (tiêu chí 7); bấm "Gợi ý" mới điền.
    func getInitialState() -> ILSignUpStateModel {
        ILSignUpStateModel.initial
    }

    func validateFullName(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).precomposedStringWithCanonicalMapping
        guard !trimmed.isEmpty else { return "signup.error.fullNameRequired".localized }
        guard trimmed.count <= Self.maximumFullNameLength else { return "signup.error.fullNameInvalid".localized }
        return nil
    }

    func validateDisplayName(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= Self.maximumDharmaNameLength else {
            return "signup.error.displayNameTooLong".localized
        }
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
        guard trimmed.count <= Self.maximumEmailLength, ILEmailValidator.isValid(trimmed) else {
            return "signup.error.emailInvalid".localized
        }
        return nil
    }

    static let minimumPasswordLength = 8
    static let maximumPasswordLength = 64

    /// EN: 8–64 characters after NFC, no trimming, no composition rule (BR-ONB-06).
    /// VI: 8–64 ký tự sau chuẩn hoá NFC, không cắt khoảng trắng, không luật thành phần (BR-ONB-06).
    func validatePassword(_ value: String) -> String? {
        guard !value.isEmpty else { return "signup.error.passwordRequired".localized }
        let length = value.precomposedStringWithCanonicalMapping.count
        guard (Self.minimumPasswordLength...Self.maximumPasswordLength).contains(length) else {
            return "signup.error.passwordLength".localized
        }
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

    func sendVerificationCode(_ entity: ILSignUpEntity) async throws -> ILSignUpOTPEntity {
        try await repository.requestRegistrationOTP(entity)
    }
}
