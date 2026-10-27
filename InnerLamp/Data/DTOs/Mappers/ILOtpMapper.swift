//
//  ILOtpMapper.swift
//  InnerLamp
//

import Foundation

/// Converts the OTP feature's response DTOs into Domain entities — field for field.
///
/// Never touches `ILOtpStateModel` (Entity ↔ StateModel mapping belongs to the ViewModel) and
/// never lets a DTO escape upward past the Repository.
nonisolated enum ILOtpMapper {

    static func toDomain(_ dto: ILOtpVerifyResponseDTO) -> ILAuthSessionEntity {
        ILAuthSessionEntity(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
            user: ILUserEntity(
                id: dto.user.id,
                email: dto.user.email,
                phoneNumber: dto.user.phoneNumber,
                dharmaName: dto.user.dharmaName ?? "",
                ordinationTempleID: dto.user.ordinationTempleId ?? ""
            )
        )
    }

    static func toDomain(_ dto: ILOtpResendResponseDTO) -> ILOtpTimingEntity {
        ILOtpTimingEntity(
            expiresInSeconds: dto.expiresInSeconds,
            resendAfterSeconds: dto.resendAfterSeconds
        )
    }
}
