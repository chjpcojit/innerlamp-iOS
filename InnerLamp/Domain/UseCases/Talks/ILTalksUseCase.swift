//
//  ILTalksUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILTalksUseCase {
    /// Mọi bài pháp thoại trong catalog, theo thứ tự hiển thị.
    func getTalks() -> [ILTalkListItemEntity]

    /// Các bài khớp bộ lọc, giữ nguyên thứ tự catalog.
    func filter(_ talks: [ILTalkListItemEntity], by filter: ILTalkFilter) -> [ILTalkListItemEntity]
}

final class ILTalksUseCaseImpl: ILTalksUseCase {

    // TODO: khi có API danh mục pháp thoại (xem Docs/Specs/Talks/requirements.md), thay catalog mẫu
    // bên dưới bằng ILTalksRepository → networkService. Tiến độ nghe dở cũng phải đọc từ vị trí
    // nghe đã lưu thay vì giá trị mẫu.
    init() {}

    func getTalks() -> [ILTalkListItemEntity] {
        Self.makeCatalog()
    }

    func filter(_ talks: [ILTalkListItemEntity], by filter: ILTalkFilter) -> [ILTalkListItemEntity] {
        switch filter {
        case .all: return talks
        case .media(let type): return talks.filter { $0.mediaType == type }
        }
    }

    // MARK: - Catalog

    /// Catalog mẫu 8 bài, khớp `TALK_LIST` trong design handoff. Chỉ `talk.vulan.hieu` có trang
    /// chi tiết thật (xem `ILTalkUseCaseImpl`); các id còn lại mở về bài đó ở màn chi tiết.
    private static func makeCatalog() -> [ILTalkListItemEntity] {
        func item(
            _ id: String, _ type: ILTalkMediaType, season: Bool = false, speaker: String,
            minutes: Int? = nil, readMinutes: Int? = nil, progress: Double = 0
        ) -> ILTalkListItemEntity {
            ILTalkListItemEntity(
                id: id,
                mediaType: type,
                season: season ? "talks.mock.season.vulan".localized : nil,
                title: "talks.title.\(id)".localized,
                speaker: "talks.mock.speaker.\(speaker)".localized,
                durationMinutes: minutes,
                readMinutes: readMinutes,
                listenProgress: progress
            )
        }
        return [
            item("talk.vulan.hieu", .audio, season: true, speaker: "minhdao", minutes: 46, progress: 0.28),
            item("talk.mock.chanhniem", .audio, speaker: "minhdao", minutes: 41),
            item("talk.mock.anlac", .video, speaker: "nhathanh"),
            item("talk.mock.hieuhanh", .text, season: true, speaker: "minhdao", readMinutes: 8),
            item("talk.mock.buongxa", .audio, speaker: "dieunhien", minutes: 38),
            item("talk.mock.tamtu", .audio, speaker: "dieunhien", minutes: 32),
            item("talk.mock.rambaythang", .text, season: true, speaker: "minhdao", readMinutes: 6),
            item("talk.mock.nghe", .audio, speaker: "dieunhien", minutes: 29)
        ]
    }
}
