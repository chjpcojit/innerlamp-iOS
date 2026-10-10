//
//  ILTalkUseCase.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import Foundation

protocol ILTalkUseCase {
    /// Catalog bài pháp thoại với bài khớp `talkID` được chọn làm bài đang phát.
    func getInitialState(talkID: String) -> ILTalkEntity

    /// Bài pháp thoại đang phát (`nil` nếu id không có trong catalog).
    func currentTalk(in entity: ILTalkEntity) -> ILTalkTrackEntity?

    /// Bật/tắt play/pause — cờ trong bộ nhớ (chưa có audio thật, xem TODO bên dưới).
    func togglePlayPause(_ entity: ILTalkEntity) -> ILTalkEntity

    /// Tua lùi 15 giây (clamp về 0).
    func rewind(_ entity: ILTalkEntity) -> ILTalkEntity

    /// Tua tới 30 giây (clamp tới tổng thời lượng bài).
    func forward(_ entity: ILTalkEntity) -> ILTalkEntity
}

final class ILTalkUseCaseImpl: ILTalkUseCase {

    /// Số giây lùi khi chạm "15s".
    static let rewindSeconds = 15
    /// Số giây tới khi chạm "30s".
    static let forwardSeconds = 30

    // TODO: khi có API danh mục pháp thoại (xem "Data cần API" trong design-handoff README), thay
    // catalog mẫu bên dưới bằng ILTalkRepository → networkService. Tương tự
    // `togglePlayPause`/`rewind`/`forward` hiện chỉ đổi trạng thái trong bộ nhớ; khi có audio thật
    // phải điều khiển trình phát thực (AVAudioPlayer / audio service dùng chung). Phần này nằm
    // ngoài scope của ui-builder — xem `references/data_layer_boundaries.md`.
    init() {}

    func getInitialState(talkID: String) -> ILTalkEntity {
        var entity = ILTalkEntity(
            talks: Self.makeTalkCatalog(),
            currentTalkID: talkID,
            elapsedSeconds: 768, // 12:48 — khớp trạng thái mẫu trong design handoff
            isPlaying: false
        )
        // Fall back về bài đầu khi id không có trong catalog mẫu (cùng cách các mock catalog của
        // Reader/Article/Player xử lý dữ liệu chưa đầy đủ).
        if !entity.talks.contains(where: { $0.id == talkID }), let first = entity.talks.first {
            entity.currentTalkID = first.id
        }
        return entity
    }

    func currentTalk(in entity: ILTalkEntity) -> ILTalkTrackEntity? {
        entity.talks.first { $0.id == entity.currentTalkID }
    }

    func togglePlayPause(_ entity: ILTalkEntity) -> ILTalkEntity {
        var updated = entity
        updated.isPlaying.toggle()
        return updated
    }

    func rewind(_ entity: ILTalkEntity) -> ILTalkEntity {
        var updated = entity
        updated.elapsedSeconds = max(0, entity.elapsedSeconds - Self.rewindSeconds)
        return updated
    }

    func forward(_ entity: ILTalkEntity) -> ILTalkEntity {
        var updated = entity
        let total = currentTalk(in: entity)?.totalDurationSeconds ?? entity.elapsedSeconds
        updated.elapsedSeconds = min(total, entity.elapsedSeconds + Self.forwardSeconds)
        return updated
    }

    // MARK: - Catalog

    /// Catalog mẫu với 1 bài pháp thoại mùa Vu Lan, khớp `talk` trong design handoff. Nội dung
    /// resolve qua `.localized` (cùng cách `ILReaderUseCaseImpl`/`ILArticleUseCaseImpl` build mock
    /// catalog). Các bài pháp thoại khác trong Thư viện chưa có dữ liệu nên cố ý bỏ trống.
    private static func makeTalkCatalog() -> [ILTalkTrackEntity] {
        [
            ILTalkTrackEntity(
                id: "talk.vulan.hieu",
                eyebrow: "talk.mock.eyebrow".localized,
                title: "talk.mock.title".localized,
                narrator: "talk.mock.narrator".localized,
                narratorInitial: "talk.mock.initial".localized,
                durationMinutes: 46,
                listenCount: 2400,
                totalDurationSeconds: 2760, // 46:00 → khớp "12:48" / "-33:12"
                description: "talk.mock.description".localized,
                chapters: [
                    ILTalkChapterEntity(
                        id: "talk.vulan.hieu.ch0",
                        timestampSeconds: 0,
                        title: "talk.mock.chapter.0.title".localized
                    ),
                    ILTalkChapterEntity(
                        id: "talk.vulan.hieu.ch1",
                        timestampSeconds: 680, // 11:20
                        title: "talk.mock.chapter.1.title".localized
                    ),
                    ILTalkChapterEntity(
                        id: "talk.vulan.hieu.ch2",
                        timestampSeconds: 2320, // 38:40
                        title: "talk.mock.chapter.2.title".localized
                    )
                ]
            )
        ]
    }
}
