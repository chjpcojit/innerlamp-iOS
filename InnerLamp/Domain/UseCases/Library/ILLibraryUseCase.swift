//
//  ILLibraryUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILLibraryUseCase {
    func getCatalog() -> ILLibraryEntity
    /// Carousel "Chư Phật & Bồ Tát" — same server source as Home (`/v1/deities/top`, cached offline).
    func loadTopDeities() async throws -> [ILHomeDeityEntity]
}

final class ILLibraryUseCaseImpl: ILLibraryUseCase {

    private let deityCatalogRepository: ILDeityCatalogRepository

    init(deityCatalogRepository: ILDeityCatalogRepository) {
        self.deityCatalogRepository = deityCatalogRepository
    }

    func loadTopDeities() async throws -> [ILHomeDeityEntity] {
        try await deityCatalogRepository.loadTopDeities().map(ILHomeUseCaseImpl.makeDeity(from:))
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
                    id: "vu-lan", kind: .sutra,
                    title: "library.mock.vulan.title".localized,
                    subtitle: "library.mock.vulan.subtitle".localized,
                    durationMinutes: 38, tone: .rose
                ),
                ILLibraryItemEntity(
                    id: "a-di-da", kind: .sutra,
                    title: "library.mock.amida.title".localized,
                    subtitle: "library.mock.amida.subtitle".localized,
                    durationMinutes: 26, tone: .green
                ),
                ILLibraryItemEntity(
                    id: "chu-dai-bi", kind: .sutra,
                    title: "library.mock.daibi.title".localized,
                    subtitle: "library.mock.daibi.subtitle".localized,
                    durationMinutes: 9, tone: .ink
                )
            ],
            // Filled asynchronously by `loadTopDeities()` once the server answers.
            deities: []
        )
    }
}
