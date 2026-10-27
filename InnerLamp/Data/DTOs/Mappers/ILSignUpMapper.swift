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
            fullName: entity.fullName,
            // EN: An empty dharma name is omitted from the body rather than sent as "".
            // VI: Pháp danh rỗng thì bỏ khỏi body thay vì gửi chuỗi rỗng.
            dharmaName: entity.displayName.isEmpty ? nil : entity.displayName,
            ordinationTempleId: entity.ordinationTempleID,
            phoneCountry: entity.phoneCountry,
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
