//
//  ILOrdinationPlaceUseCase.swift
//  InnerLamp
//

import Foundation

/// Danh sách chùa cho bộ chọn "Nơi xuất gia" của màn Đăng ký — đọc `GET /v1/temples` (endpoint
/// công khai, không cần đăng nhập) qua `ILTempleRepository`.
protocol ILOrdinationPlaceUseCase {
    /// Toàn bộ chùa của danh bạ, theo thứ tự server, đã loại trùng id.
    func loadPlaces() async throws -> [ILOrdinationPlaceEntity]
}

final class ILOrdinationPlaceUseCaseImpl: ILOrdinationPlaceUseCase {

    /// Chốt an toàn cho vòng phân trang — phòng server báo còn trang mãi.
    private static let maxPages = 50

    private let templeRepository: ILTempleRepository

    init(templeRepository: ILTempleRepository) {
        self.templeRepository = templeRepository
    }

    func loadPlaces() async throws -> [ILOrdinationPlaceEntity] {
        var temples: [ILTempleSummaryEntity] = []
        var page = 1
        while page <= Self.maxPages {
            let result = try await templeRepository.loadTemples(page: page)
            temples += result.items
            guard result.hasMore else { break }
            page += 1
        }
        var seen = Set<String>()
        return temples
            .filter { seen.insert($0.id).inserted }
            .map { ILOrdinationPlaceEntity(id: $0.id, name: $0.name, subtitle: $0.location.address) }
    }
}
