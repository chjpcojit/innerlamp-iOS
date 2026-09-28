//
//  ILPhotosUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILPhotosUseCase {
    /// Catalog ảnh chùa (12 ảnh) với bộ lọc mặc định "Tất cả" (`selectedCategory == nil`).
    func getInitialState() -> ILPhotosEntity

    /// Chọn 1 danh mục lọc. `nil` = "Tất cả". Giữ nguyên `entity` nếu giá trị không đổi.
    func selectCategory(_ category: ILPhotosCategory?, in entity: ILPhotosEntity) -> ILPhotosEntity

    /// Các ảnh khớp danh mục đang chọn (`nil` = toàn bộ).
    func filteredPhotos(in entity: ILPhotosEntity) -> [ILPhotosPhotoEntity]
}

final class ILPhotosUseCaseImpl: ILPhotosUseCase {

    // TODO: khi có API ảnh chùa thật, thay catalog mock dưới đây bằng dữ liệu từ
    // networkService (gallery "Ảnh chùa đẹp", xem README design handoff — mục "Data cần API").
    init() {}

    func getInitialState() -> ILPhotosEntity {
        ILPhotosEntity(photos: Self.makePhotoCatalog(), selectedCategory: nil)
    }

    func selectCategory(_ category: ILPhotosCategory?, in entity: ILPhotosEntity) -> ILPhotosEntity {
        guard entity.selectedCategory != category else { return entity }
        var updated = entity
        updated.selectedCategory = category
        return updated
    }

    func filteredPhotos(in entity: ILPhotosEntity) -> [ILPhotosPhotoEntity] {
        guard let category = entity.selectedCategory else { return entity.photos }
        return entity.photos.filter { $0.category == category }
    }

    // MARK: - Catalog

    /// Catalog tĩnh 12 ảnh khớp `Component.PHOTOS` trong design handoff (title/place/h theo thứ
    /// tự `pg-1` → `pg-12`). Tiêu đề/địa điểm là nội dung hiển thị nên lấy qua `.localized`,
    /// giống cách `ILHomeUseCaseImpl` dựng danh mục chùa/bài viết.
    private static func makePhotoCatalog() -> [ILPhotosPhotoEntity] {
        let items: [(id: String, category: ILPhotosCategory, height: Double)] = [
            ("pg-1", .temple, 220),
            ("pg-2", .buddhaStatue, 170),
            ("pg-3", .meditation, 150),
            ("pg-4", .temple, 180),
            ("pg-5", .buddhaStatue, 240),
            ("pg-6", .temple, 160),
            ("pg-7", .meditation, 200),
            ("pg-8", .festival, 170),
            ("pg-9", .buddhaStatue, 150),
            ("pg-10", .temple, 210),
            ("pg-11", .festival, 180),
            ("pg-12", .meditation, 160)
        ]

        return items.enumerated().map { index, item in
            ILPhotosPhotoEntity(
                id: item.id,
                category: item.category,
                title: "photos.photo.\(index).title".localized,
                place: "photos.photo.\(index).place".localized,
                imageHeight: item.height
            )
        }
    }
}
