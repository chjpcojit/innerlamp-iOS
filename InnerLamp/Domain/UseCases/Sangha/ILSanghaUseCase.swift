//
//  ILSanghaUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILSanghaUseCase {
    func getSangha() -> ILSanghaEntity
}

final class ILSanghaUseCaseImpl: ILSanghaUseCase {

    init() {}

    func getSangha() -> ILSanghaEntity {
        // TODO: chưa có API đạo tràng được xác nhận (số người đang ngồi thiền, đạo tràng của tôi,
        // bài chia sẻ) — thay dữ liệu mẫu bên dưới bằng ILSanghaRepository → networkService khi có
        // contract (dùng il-data-layer-builder).
        ILSanghaEntity(
            liveSession: ILSanghaLiveSessionEntity(participantCount: 312, sessionMinutes: 20),
            community: ILSanghaCommunityEntity(
                id: "sangha.tuquang",
                name: "sangha.mock.community.name".localized,
                memberCount: 184,
                district: "sangha.mock.community.district".localized,
                announcement: "sangha.mock.community.announcement".localized
            ),
            posts: [
                ILSanghaPostEntity(
                    id: "post.dieuhanh.1",
                    authorName: "sangha.mock.post.author".localized,
                    postedAt: Date().addingTimeInterval(-2 * 60 * 60),
                    authorStreakDays: 41,
                    body: "sangha.mock.post.body".localized,
                    likeCount: 24,
                    replyCount: 6
                )
            ]
        )
    }
}
