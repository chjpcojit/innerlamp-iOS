//
//  ILTempleFinderUseCase.swift
//  InnerLamp
//

import Foundation

/// Màn "Chọn chùa tu tập": đọc toàn bộ danh bạ chùa (`/v1/temples`) và đặt 1 chùa làm chùa tu tập.
/// Gửi đề xuất chùa mới chưa có ở đây — chưa có API (xem TD-TempleFinder-001).
protocol ILTempleFinderUseCase {
    /// Mọi chùa của danh bạ, theo thứ tự server, đã loại trùng id.
    func loadTemples() async throws -> [ILTempleSummaryEntity]
    /// Chùa tu tập hiện tại; `nil` khi chưa chọn.
    func loadMyTemple() -> (id: String, name: String)?
    func selectMyTemple(_ temple: ILTempleSummaryEntity)
}

final class ILTempleFinderUseCaseImpl: ILTempleFinderUseCase {

    /// Chốt an toàn cho vòng phân trang — phòng server báo còn trang mãi.
    private static let maxPages = 50

    private let templeRepository: ILTempleRepository
    private let sanghaUseCase: ILSanghaUseCase

    init(templeRepository: ILTempleRepository, sanghaUseCase: ILSanghaUseCase) {
        self.templeRepository = templeRepository
        self.sanghaUseCase = sanghaUseCase
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

    func loadMyTemple() -> (id: String, name: String)? {
        sanghaUseCase.loadMyTemple().map { ($0.temple.id, $0.temple.name) }
    }

    func selectMyTemple(_ temple: ILTempleSummaryEntity) {
        sanghaUseCase.selectMyTemple(temple)
    }
}
