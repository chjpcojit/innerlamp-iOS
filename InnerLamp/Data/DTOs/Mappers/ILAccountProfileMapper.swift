//
//  ILAccountProfileMapper.swift
//  InnerLamp
//

import Foundation

nonisolated enum ILAccountProfileMapper {

    static func toDomain(_ dto: ILUserMeDTO) -> ILAccountProfileEntity {
        ILAccountProfileEntity(
            email: dto.email,
            isEmailVerified: dto.emailVerified,
            phoneNumber: dto.phoneNumber,
            fullName: dto.fullName ?? "",
            dharmaName: dto.dharmaName ?? "",
            ordinationTemple: dto.ordinationTemple.map {
                ILAccountProfileEntity.Temple(id: $0.id, name: $0.name)
            },
            avatarURL: dto.avatarUrl.flatMap { URL(string: $0) },
            avatarURLExpiresAt: dto.avatarUrlExpiresAt.flatMap { ISO8601DateFormatter().date(from: $0) }
        )
    }
}
