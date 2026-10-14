//
//  ILAdministrativeUnitMapper.swift
//  InnerLamp
//

import Foundation

nonisolated enum ILAdministrativeUnitMapper {

    static func toDomain(_ dto: ILProvinceDTO) -> ILProvinceEntity {
        let kind: ILProvinceEntity.Kind
        switch dto.type {
        case "province": kind = .province
        case "city": kind = .city
        default: kind = .other
        }
        return ILProvinceEntity(code: dto.code, name: dto.name, fullName: dto.fullName, kind: kind)
    }

    static func toDomain(_ dto: ILWardDTO) -> ILWardEntity {
        let kind: ILWardEntity.Kind
        switch dto.type {
        case "ward": kind = .ward
        case "commune": kind = .commune
        case "special_zone": kind = .specialZone
        default: kind = .other
        }
        return ILWardEntity(
            code: dto.code,
            name: dto.name,
            fullName: dto.fullName,
            kind: kind,
            provinceCode: dto.provinceCode
        )
    }
}
