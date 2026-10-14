//
//  ILTemplesUseCase.swift
//  InnerLamp
//

import Foundation

/// Màn "Tất cả chùa": đọc toàn bộ danh bạ chùa (`/v1/temples`).
protocol ILTemplesUseCase {
    /// Mọi chùa của danh bạ, theo thứ tự server, đã loại trùng id.
    func loadTemples() async throws -> [ILTempleSummaryEntity]
}

final class ILTemplesUseCaseImpl: ILTemplesUseCase {

    /// Chốt an toàn cho vòng phân trang — phòng server báo còn trang mãi.
    private static let maxPages = 50

    private let templeRepository: ILTempleRepository

    init(templeRepository: ILTempleRepository) {
        self.templeRepository = templeRepository
    }

    func loadTemples() async throws -> [ILTempleSummaryEntity] {
        var temples: [ILTempleSummaryEntity] = []
        var page = 1
        while page <= Self.maxPages {
            let result = try await templeRepository.loadTemples(page: page)
            temples += result.items
            guard result.hasMore else { break }
            page += 1
        }
        // Server chèn dòng có thể làm lệch ranh giới trang — giữ lần xuất hiện đầu của mỗi id.
        var seen = Set<String>()
        return temples.filter { seen.insert($0.id).inserted }
    }
}
