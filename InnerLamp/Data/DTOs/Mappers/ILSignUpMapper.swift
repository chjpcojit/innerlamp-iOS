//
//  ILSignUpMapper.swift
//  InnerLamp
//

import Foundation

/// Converts between `ILSignUpEntity` (Domain, pure business), the registration request's wire
/// shape, and the request-otp response's `ILSignUpOTPEntity` — field for field.
///
/// Never touches `ILSignUpStateModel`: Entity ↔ StateModel mapping is presentation-specific and
/// lives in the ViewModel.
nonisolated enum ILSignUpMapper {
    static func toDTO(_ entity: ILSignUpEntity) -> ILSignUpRequestOTPRequestDTO {
        ILSignUpRequestOTPRequestDTO(
            dharmaName: entity.displayName,
            ordinationPlace: entity.ordinationPlace,
            phoneNumber: entity.phoneNumber,
            email: entity.email,
            password: entity.password
        )
    }

    static func toDomain(_ dto: ILSignUpRequestOTPResponseDTO) -> ILSignUpOTPEntity {
        ILSignUpOTPEntity(
            message: dto.message,
            expiresInSeconds: dto.expiresInSeconds,
            resendAfterSeconds: dto.resendAfterSeconds
        )
    }
}
