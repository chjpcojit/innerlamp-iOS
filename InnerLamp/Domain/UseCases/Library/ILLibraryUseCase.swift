//
//  ILLibraryUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILLibraryUseCase {
    func getCatalog() -> ILLibraryEntity

    /// Lọc theo nhóm ngay trong bộ nhớ — không gọi mạng. Giữ nguyên thứ tự gốc của catalog.
    func items(in catalog: ILLibraryEntity, category: ILLibraryCategory) -> [ILLibraryItemEntity]
}

final class ILLibraryUseCaseImpl: ILLibraryUseCase {

    init() {}

    func getCatalog() -> ILLibraryEntity {
        // TODO: khi API danh mục thư viện được xác nhận (xem Docs/Specs/Library/requirements.md),
        // thay dữ liệu mẫu bên dưới bằng ILLibraryRepository → networkService (Phase 3 của tasks.md).
        ILLibraryEntity(
            featured: ILLibraryFeaturedEntity(
                id: "talk.vulan.hieu",
                eyebrow: "library.featured.eyebrow".localized,
                title: "library.featured.title".localized,
                durationMinutes: 46
            ),
            items: [
                ILLibraryItemEntity(
                    id: "sutra.phapcu", kind: .sutra,
                    title: "library.mock.phapcu.title".localized,
                    subtitle: "library.mock.phapcu.subtitle".localized,
                    durationMinutes: 130, tone: .gold
                ),
                ILLibraryItemEntity(
                    id: "sutra.vulan", kind: .sutra,
                    title: "library.mock.vulan.title".localized,
                    subtitle: "library.mock.vulan.subtitle".localized,
                    durationMinutes: 38, tone: .rose
                ),
                ILLibraryItemEntity(
                    id: "sutra.amida", kind: .sutra,
                    title: "library.mock.amida.title".localized,
                    subtitle: "library.mock.amida.subtitle".localized,
                    durationMinutes: 26, tone: .green
                ),
                ILLibraryItemEntity(
                    id: "sutra.daibi", kind: .sutra,
                    title: "library.mock.daibi.title".localized,
                    subtitle: "library.mock.daibi.subtitle".localized,
                    durationMinutes: 9, tone: .ink
                ),
                ILLibraryItemEntity(
                    id: "meditation.breathing", kind: .meditation,
                    title: "library.mock.breathing.title".localized,
                    subtitle: "library.mock.breathing.subtitle".localized,
                    durationMinutes: 10, tone: .green
                ),
                ILLibraryItemEntity(
                    id: "meditation.bodyscan", kind: .meditation,
                    title: "library.mock.bodyscan.title".localized,
                    subtitle: "library.mock.bodyscan.subtitle".localized,
                    durationMinutes: 20, tone: .gold
                ),
                ILLibraryItemEntity(
                    id: "talk.hieu", kind: .talk,
                    title: "library.mock.talkHieu.title".localized,
                    subtitle: "library.mock.talkHieu.subtitle".localized,
                    durationMinutes: 46, tone: .rose
                ),
                ILLibraryItemEntity(
                    id: "talk.tamtinh", kind: .talk,
                    title: "library.mock.talkTamTinh.title".localized,
                    subtitle: "library.mock.talkTamTinh.subtitle".localized,
                    durationMinutes: 62, tone: .ink
                )
            ]
        )
    }

    func items(in catalog: ILLibraryEntity, category: ILLibraryCategory) -> [ILLibraryItemEntity] {
        guard let kind = category.kind else { return catalog.items }
        return catalog.items.filter { $0.kind == kind }
    }
}
