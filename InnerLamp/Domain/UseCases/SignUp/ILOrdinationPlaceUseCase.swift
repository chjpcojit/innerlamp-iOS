//
//  ILOrdinationPlaceUseCase.swift
//  InnerLamp
//

import Foundation

/// Danh sách chùa cho bộ chọn "Nơi xuất gia" của màn Đăng ký — đọc `GET /v1/temples/options`
/// (endpoint công khai, không cần đăng nhập) qua `ILTempleOptionRepository`, từng trang một.
protocol ILOrdinationPlaceUseCase {
    /// Một trang (bắt đầu từ 1) theo thứ tự server. `query` rỗng = không lọc; có từ khoá thì server
    /// tìm theo tên chùa (không phân biệt hoa thường và dấu).
    func loadPlaces(query: String, page: Int) async throws -> ILCatalogPageEntity<ILOrdinationPlaceEntity>
}

final class ILOrdinationPlaceUseCaseImpl: ILOrdinationPlaceUseCase {

    private let templeOptionRepository: ILTempleOptionRepository

    init(templeOptionRepository: ILTempleOptionRepository) {
        self.templeOptionRepository = templeOptionRepository
    }

    func loadPlaces(query: String, page: Int) async throws -> ILCatalogPageEntity<ILOrdinationPlaceEntity> {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = try await templeOptionRepository.loadTempleOptions(
            query: trimmed.isEmpty ? nil : trimmed,
            page: page
        )
        var seen = Set<String>()
        let places = result.items
            .filter { seen.insert($0.id).inserted }
            .map { ILOrdinationPlaceEntity(id: $0.id, name: $0.name, subtitle: $0.province) }
        return ILCatalogPageEntity(items: places, page: result.page, hasMore: result.hasMore)
    }
}
