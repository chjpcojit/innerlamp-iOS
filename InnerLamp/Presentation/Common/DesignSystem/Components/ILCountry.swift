//
//  ILCountry.swift
//  InnerLamp
//

import Foundation

/// Danh sách quốc gia cho bộ chọn mã vùng số điện thoại (`ILPhoneField` +
/// `ILCountryPickerViewController`) — dữ liệu tham chiếu UI thuần, không phải business entity
/// của riêng feature nào (dùng lại được ở Đăng ký, Đăng nhập, Quên mật khẩu...) nên đặt ở Design
/// System, không phải `Domain/Entities/`. Khớp `Component.COUNTRIES` trong design handoff
/// (`InnerLamp Prototype.dc.html`).
public struct ILCountry: Equatable {
    public let iso: String
    public let flag: String
    public let name: String
    public let dialCode: String
    /// Số chữ số quốc gia hợp lệ, min...max (không tính mã vùng, không tính số 0 đầu). Cận trên
    /// còn dùng để `ILPhoneField` chặn gõ dư.
    public let nationalDigitRange: ClosedRange<Int>

    public init(iso: String, flag: String, name: String, dialCode: String, nationalDigitRange: ClosedRange<Int>) {
        self.iso = iso
        self.flag = flag
        self.name = name
        self.dialCode = dialCode
        self.nationalDigitRange = nationalDigitRange
    }

    /// `true` khi số chữ số quốc gia nằm trong `nationalDigitRange` — quy tắc hợp lệ dùng chung
    /// cho Đăng ký, Đăng nhập, Quên mật khẩu.
    public func isValidNationalDigitCount(_ count: Int) -> Bool {
        nationalDigitRange.contains(count)
    }

    /// Thứ tự và giá trị khớp `Component.COUNTRIES` trong design handoff — Việt Nam mặc định đầu danh sách.
    public static let all: [ILCountry] = [
        ILCountry(iso: "VN", flag: "🇻🇳", name: "Việt Nam", dialCode: "+84", nationalDigitRange: 9...9),
        ILCountry(iso: "US", flag: "🇺🇸", name: "Hoa Kỳ", dialCode: "+1", nationalDigitRange: 10...10),
        ILCountry(iso: "JP", flag: "🇯🇵", name: "Nhật Bản", dialCode: "+81", nationalDigitRange: 10...10),
        ILCountry(iso: "KR", flag: "🇰🇷", name: "Hàn Quốc", dialCode: "+82", nationalDigitRange: 9...9),
        ILCountry(iso: "TH", flag: "🇹🇭", name: "Thái Lan", dialCode: "+66", nationalDigitRange: 9...9),
        ILCountry(iso: "SG", flag: "🇸🇬", name: "Singapore", dialCode: "+65", nationalDigitRange: 8...8),
        ILCountry(iso: "MY", flag: "🇲🇾", name: "Malaysia", dialCode: "+60", nationalDigitRange: 9...9),
        ILCountry(iso: "TW", flag: "🇹🇼", name: "Đài Loan", dialCode: "+886", nationalDigitRange: 9...9),
        ILCountry(iso: "AU", flag: "🇦🇺", name: "Úc", dialCode: "+61", nationalDigitRange: 9...9),
        ILCountry(iso: "DE", flag: "🇩🇪", name: "Đức", dialCode: "+49", nationalDigitRange: 10...10),
        ILCountry(iso: "FR", flag: "🇫🇷", name: "Pháp", dialCode: "+33", nationalDigitRange: 9...9),
        ILCountry(iso: "CA", flag: "🇨🇦", name: "Canada", dialCode: "+1", nationalDigitRange: 10...10)
    ]

    public static let `default` = all[0]

    /// So khớp không dấu, không phân biệt hoa/thường — dùng cho ô tìm kiếm trong bộ chọn.
    public func matches(query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.foldedForSearch()
        return name.foldedForSearch().contains(q) || dialCode.contains(q) || iso.foldedForSearch().contains(q)
    }
}

private extension String {
    /// Bỏ dấu tiếng Việt (kể cả `đ`) + hạ chữ thường — khớp `_norm()` trong design handoff.
    func foldedForSearch() -> String {
        folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "d")
            .lowercased()
    }
}
