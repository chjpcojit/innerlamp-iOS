//
//  ILAddTempleUseCase.swift
//  InnerLamp
//

import Foundation

/// Lỗi kiểm tra form "Thêm thông tin chùa".
enum ILAddTempleError: Error, Equatable {
    case nameRequired
    case provinceRequired
    /// Chùa đã có trong danh bạ — kèm tên chùa trùng để báo người dùng quay lại chọn.
    case duplicate(String)
}

/// Kiểm tra và chuẩn hoá đề xuất chùa mới. Chưa có API gửi đề xuất (xem TD-SignUp-002) nên use
/// case này chỉ làm phần nghiệp vụ cục bộ: bắt buộc tên + tỉnh/thành, chặn trùng danh bạ.
protocol ILAddTempleUseCase {
    /// `nil` khi hợp lệ. `existing` là danh bạ chùa đã tải để chặn trùng (có thể rỗng).
    func validate(name: String, province: String, existing: [ILOrdinationPlaceEntity]) -> ILAddTempleError?
    func makeProposal(name: String, province: String, address: String) -> ILTempleProposalEntity
}

final class ILAddTempleUseCaseImpl: ILAddTempleUseCase {

    /// Tên bắt đầu bằng một trong các tiền tố này thì giữ nguyên, ngược lại tự thêm "Chùa ".
    private static let namePrefixes = ["chùa", "thiền viện", "tịnh xá", "niệm phật đường"]
    private static let defaultPrefix = "Chùa"

    func validate(name: String, province: String, existing: [ILOrdinationPlaceEntity]) -> ILAddTempleError? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProvince = province.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return .nameRequired }
        guard !trimmedProvince.isEmpty else { return .provinceRequired }

        let needle = Self.coreName(trimmedName)
        let provinceNeedle = Self.normalize(trimmedProvince)
        let duplicate = existing.first {
            Self.coreName($0.name) == needle && Self.normalize($0.subtitle).contains(provinceNeedle)
        }
        if let duplicate { return .duplicate(duplicate.name) }
        return nil
    }

    func makeProposal(name: String, province: String, address: String) -> ILTempleProposalEntity {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasPrefix = Self.namePrefixes.contains { trimmedName.lowercased().hasPrefix($0) }
        return ILTempleProposalEntity(
            name: hasPrefix ? trimmedName : "\(Self.defaultPrefix) \(trimmedName)",
            province: province.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    /// Không phân biệt hoa thường và dấu; bỏ tiền tố loại hình ("chùa", "thiền viện"...).
    private static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func coreName(_ name: String) -> String {
        var core = normalize(name)
        for prefix in ["chua ", "thien vien ", "tinh xa ", "niem phat duong "] where core.hasPrefix(prefix) {
            core.removeFirst(prefix.count)
            break
        }
        return core
    }
}
