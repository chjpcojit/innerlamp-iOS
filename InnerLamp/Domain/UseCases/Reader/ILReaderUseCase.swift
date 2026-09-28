//
//  ILReaderUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILReaderUseCase {
    /// Catalog các bộ kinh với bộ `sutraID` được chọn làm bộ kinh hiện tại.
    func getInitialState(sutraID: String) -> ILReaderEntity

    /// Bộ kinh đang mở theo `currentSutraID` (`nil` nếu id không có trong catalog).
    func currentSutra(in entity: ILReaderEntity) -> ILReaderSutraEntity?

    /// Kệ đang hiển thị theo `currentVerseIndex` (`nil` nếu vượt ngoài danh sách kệ).
    func currentVerse(in entity: ILReaderEntity) -> ILReaderVerseEntity?

    /// Kệ kế tiếp (bản xem trước mờ) — `nil` nếu không còn kệ sau.
    func nextVerse(in entity: ILReaderEntity) -> ILReaderVerseEntity?

    /// Bật/tắt trạng thái phát — thuần in-memory (chưa có audio thật, xem TODO dưới).
    func togglePlayPause(_ entity: ILReaderEntity) -> ILReaderEntity
}

final class ILReaderUseCaseImpl: ILReaderUseCase {

    // TODO: khi có API danh mục kinh + nội dung kệ thật (xem "Data cần API" ở README design
    // handoff), thay catalog mock dưới đây bằng ILReaderRepository → networkService. Tương tự,
    // `togglePlayPause` hiện chỉ đảo cờ `isPlaying` in-memory; khi có audio thật (file tụng mẫu)
    // cần nối với `ILPracticeSoundPlayer`/AVAudioPlayer để thực sự phát và dừng.
    init() {}

    func getInitialState(sutraID: String) -> ILReaderEntity {
        var entity = ILReaderEntity(
            sutras: Self.makeSutraCatalog(),
            currentSutraID: sutraID,
            currentVerseIndex: 0,
            readingProgress: 0.34,
            elapsedSeconds: 724,
            playbackSpeed: 1.0,
            isPlaying: false
        )
        // Nếu id truyền vào chưa có trong catalog mock, rơi về bộ kinh đầu tiên (Kinh Pháp Cú) —
        // cùng cách catalog mock của Library/Article xử lý dữ liệu chưa đầy đủ.
        if !entity.sutras.contains(where: { $0.id == sutraID }), let first = entity.sutras.first {
            entity.currentSutraID = first.id
        }
        return entity
    }

    func currentSutra(in entity: ILReaderEntity) -> ILReaderSutraEntity? {
        entity.sutras.first { $0.id == entity.currentSutraID }
    }

    func currentVerse(in entity: ILReaderEntity) -> ILReaderVerseEntity? {
        guard let sutra = currentSutra(in: entity),
              sutra.verses.indices.contains(entity.currentVerseIndex) else {
            return nil
        }
        return sutra.verses[entity.currentVerseIndex]
    }

    func nextVerse(in entity: ILReaderEntity) -> ILReaderVerseEntity? {
        guard let sutra = currentSutra(in: entity),
              sutra.verses.indices.contains(entity.currentVerseIndex + 1) else {
            return nil
        }
        return sutra.verses[entity.currentVerseIndex + 1]
    }

    func togglePlayPause(_ entity: ILReaderEntity) -> ILReaderEntity {
        var updated = entity
        updated.isPlaying.toggle()
        return updated
    }

    // MARK: - Catalog

    /// Catalog mock 1 bộ kinh (Kinh Pháp Cú) khớp `isReader` trong design handoff — nội dung kệ
    /// lấy qua `.localized`, giống cách `ILArticleUseCaseImpl` dựng catalog bài viết. Các bộ kinh
    /// khác trong Thư viện (Vu Lan, A Di Đà, Chú Đại Bi) chưa có dữ liệu kệ nên tạm chưa đưa vào.
    private static func makeSutraCatalog() -> [ILReaderSutraEntity] {
        let prefix = "reader.sutra.phapcu"
        let verses = (0..<2).map { index in
            ILReaderVerseEntity(
                vietnamese: "\(prefix).verse.\(index).vietnamese".localized,
                english: "\(prefix).verse.\(index).english".localized
            )
        }
        return [
            ILReaderSutraEntity(
                id: "sutra.phapcu",
                title: "\(prefix).title".localized,
                subtitle: "\(prefix).subtitle".localized,
                narrator: "\(prefix).narrator".localized,
                totalDurationSeconds: 2130,
                verses: verses
            )
        ]
    }
}
