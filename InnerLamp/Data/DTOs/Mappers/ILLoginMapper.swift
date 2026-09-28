//
//  ILLoginMapper.swift
//  InnerLamp
//

import Foundation

/// Converts between `ILLoginEntity` (Domain, pure business), the login request's wire shape, and
/// the response's `ILAuthSessionEntity` — field for field.
///
/// Never touches `ILLoginStateModel`: Entity ↔ StateModel mapping is presentation-specific and
/// lives in the ViewModel.
nonisolated enum ILLoginMapper {

    static func toDTO(_ entity: ILLoginEntity, device: ILLoginDeviceDTO) -> ILLoginRequestDTO {
        ILLoginRequestDTO(
            phoneNumber: entity.phone,
            password: entity.password,
            device: device
        )
    }

    static func toDomain(_ dto: ILLoginResponseDTO) -> ILAuthSessionEntity {
        ILAuthSessionEntity(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
            user: ILUserEntity(
                id: dto.user.id,
                email: dto.user.email,
                phoneNumber: dto.user.phoneNumber,
                dharmaName: dto.user.dharmaName ?? "",
                ordinationPlace: dto.user.ordinationPlace ?? ""
            )
        )
    }
}
