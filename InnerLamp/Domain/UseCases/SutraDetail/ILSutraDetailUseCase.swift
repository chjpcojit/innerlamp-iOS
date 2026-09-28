//
//  ILSutraDetailUseCase.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation

protocol ILSutraDetailUseCase {
    /// Catalog các bộ kinh với bộ `sutraID` được chọn làm bộ kinh hiện tại.
    func getInitialState(sutraID: String) -> ILSutraDetailEntity

    /// Bộ kinh đang mở theo `currentSutraID` (`nil` nếu id không có trong catalog).
    func currentSutra(in entity: ILSutraDetailEntity) -> ILSutraDetailSutraEntity?
}

final class ILSutraDetailUseCaseImpl: ILSutraDetailUseCase {

    // TODO: khi có API danh mục kinh thật (xem "Data cần API" ở README design handoff), thay
    // catalog mock dưới đây bằng ILSutraDetailRepository → networkService.
    init() {}

    func getInitialState(sutraID: String) -> ILSutraDetailEntity {
        var entity = ILSutraDetailEntity(
            sutras: Self.makeSutraCatalog(),
            currentSutraID: sutraID,
            currentChapterID: "chapter.1",
            readingProgress: 0.34
        )
        // Nếu id truyền vào chưa có trong catalog mock, rơi về bộ kinh đầu tiên (Kinh Pháp Cú) —
        // cùng cách catalog mock của Library/Article/Reader xử lý dữ liệu chưa đầy đủ.
        if !entity.sutras.contains(where: { $0.id == sutraID }), let first = entity.sutras.first {
            entity.currentSutraID = first.id
        }
        return entity
    }

    func currentSutra(in entity: ILSutraDetailEntity) -> ILSutraDetailSutraEntity? {
        entity.sutras.first { $0.id == entity.currentSutraID }
    }

    // MARK: - Catalog

    /// Catalog mock 1 bộ kinh (Kinh Pháp Cú) khớp `isDetail` trong design handoff — nội dung lấy
    /// qua `.localized`, giống cách `ILArticleUseCaseImpl` dựng catalog bài viết. Các bộ kinh khác
    /// trong Thư viện (Vu Lan, A Di Đà, Chú Đại Bi) chưa có dữ liệu phẩm nên tạm chưa đưa vào.
    private static func makeSutraCatalog() -> [ILSutraDetailSutraEntity] {
        let prefix = "sutraDetail.mock.phapcu"
        let chapters = (0..<Self.chapterVerseStarts.count).map { index in
            ILSutraDetailChapterEntity(
                id: "chapter.\(index + 1)",
                number: Self.romanNumerals[index],
                title: "\(prefix).chapter.\(index).title".localized,
                verseStart: Self.chapterVerseStarts[index],
                verseEnd: Self.chapterVerseEnds[index],
                durationMinutes: Self.chapterDurations[index]
            )
        }
        return [
            ILSutraDetailSutraEntity(
                id: "sutra.phapcu",
                kicker: "sutraDetail.kicker".localized,
                title: "\(prefix).title".localized,
                narrator: "\(prefix).narrator".localized,
                numberOfChapters: 26,
                numberOfVerses: 423,
                durationMinutes: 130,
                description: "\(prefix).description".localized,
                tags: [.daily, .phonetic],
                chapters: chapters
            )
        ]
    }

    /// Số La Mã của 5 phẩm mock (khớp `chapters` trong design handoff).
    private static let romanNumerals = ["I", "II", "III", "IV", "V"]

    /// Kệ đầu / cuối của từng phẩm mock (khớp "Kệ 1 – 20", "Kệ 21 – 32", ...).
    private static let chapterVerseStarts = [1, 21, 33, 44, 60]
    private static let chapterVerseEnds = [20, 32, 43, 59, 75]

    /// Thời lượng tụng (phút) của từng phẩm mock.
    private static let chapterDurations = [9, 7, 6, 8, 8]
}
