//
//  ILLibraryUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILLibraryUseCase {
    func getCatalog() -> ILLibraryEntity
}

final class ILLibraryUseCaseImpl: ILLibraryUseCase {

    private let deityUseCase: ILDeityUseCase

    init(deityUseCase: ILDeityUseCase) {
        self.deityUseCase = deityUseCase
    }

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
                )
            ],
            // Carousel "Chư Phật & Bồ Tát" — cùng catalog và cùng phép map `primaryMemorialDay`
            // với carousel "Thư viện Phật & Bồ Tát" ở Trang chủ (`ILHomeUseCaseImpl`), để chạm thẻ
            // mở đúng màn chi tiết `Deity` bằng cùng id.
            deities: deityUseCase.getAllDeities().map {
                ILHomeDeityEntity(
                    id: $0.id,
                    kind: $0.kind,
                    name: $0.nameVi,
                    honorific: $0.titleHonorific,
                    virtue: $0.coreVirtue,
                    memorialDay: ILHomeUseCaseImpl.primaryMemorialDay(of: $0.memorialDays)
                )
            }
        )
    }
}
