//
//  ILDeityMapper.swift
//  InnerLamp
//

import Foundation

/// Converts the bundled catalog's DTOs into Domain entities — field for field.
///
/// Also owns decoding of the raw catalog file, so the snake_case key strategy lives in one place
/// and both the data source and the tests decode it identically.
nonisolated enum ILDeityMapper {

    /// Decodes the catalog file (a top-level JSON array) and maps every row to an entity,
    /// preserving file order.
    static func decodeCatalog(from data: Data) throws -> [ILDeityEntity] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([ILDeityDTO].self, from: data).map(toDomain)
    }

    static func toDomain(_ dto: ILDeityDTO) -> ILDeityEntity {
        ILDeityEntity(
            id: dto.id,
            kind: toDomain(dto.type),
            nameVi: dto.nameVi,
            nameSanskrit: dto.nameSanskrit,
            nameChinese: dto.nameChinese,
            titleHonorific: dto.titleHonorific,
            canonicalSource: dto.canonicalSource,
            coreVirtue: dto.coreVirtue,
            pureLand: dto.pureLand,
            memorialDays: dto.lunarMemorialDays.map {
                ILDeityMemorialDayEntity(lunarDay: $0.lunarDay, lunarMonth: $0.lunarMonth, eventName: $0.eventName)
            },
            iconography: ILDeityIconographyEntity(
                posture: dto.iconography.posture,
                mountOrThrone: dto.iconography.mountOrThrone,
                sacredArtifacts: dto.iconography.sacredArtifacts,
                symbolicMeaning: dto.iconography.symbolicMeaning
            ),
            biographySummary: dto.biographySummary,
            greatVows: dto.greatVows,
            mantra: ILDeityMantraEntity(
                shortSanskrit: dto.mantras.shortMantraSanskrit,
                shortSinoVietnamese: dto.mantras.shortMantraSinoVietnamese,
                dharaniName: dto.mantras.longDharaniName,
                dharaniSnippet: dto.mantras.dharaniPhoneticSnippet
            )
        )
    }

    private static func toDomain(_ type: ILDeityTypeDTO) -> ILDeityKind {
        switch type {
        case .buddha: return .buddha
        case .bodhisattva: return .bodhisattva
        }
    }
}
