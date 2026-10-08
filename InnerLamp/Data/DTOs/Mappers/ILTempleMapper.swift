//
//  ILTempleMapper.swift
//  InnerLamp
//

import Foundation

/// Converts temple DTOs into Domain entities. Used for both fresh server responses and rows read
/// back from the Core Data cache (the cache stores the raw wire values), so there is a single
/// mapping path.
nonisolated enum ILTempleMapper {

    static func toDomain(_ dto: ILTempleSummaryDTO) -> ILTempleSummaryEntity {
        ILTempleSummaryEntity(
            id: dto.id,
            name: dto.name,
            type: type(from: dto.type),
            region: region(from: dto.region),
            thumbnailURL: dto.thumbnailUrl,
            imageURL: dto.imageUrl,
            sect: dto.sect,
            heritageRank: heritageRank(from: dto.heritageRank),
            establishedYear: dto.establishedYear,
            location: ILTempleLocationEntity(
                latitude: dto.location.lat,
                longitude: dto.location.lng,
                address: dto.location.address
            )
        )
    }

    static func toDomain(_ dto: ILTempleDetailDTO) -> ILTempleDetailEntity {
        ILTempleDetailEntity(
            summary: toDomain(dto.summary),
            aliases: dto.aliases,
            founder: dto.founder,
            currentAbbot: dto.currentAbbot,
            operatingHours: dto.operatingHours,
            facilities: ILTempleFacilitiesEntity(
                hasCarParking: dto.amenities.parkingCar,
                hasMotorbikeParking: dto.amenities.parkingMotorcycle,
                servesVegetarianMeals: dto.amenities.vegetarianMeals,
                hasSummerRetreat: dto.amenities.summerRetreat
            ),
            introduction: trimmed(dto.introduction),
            architectureHeritage: trimmed(dto.architectureHeritage),
            visitingNotes: (dto.visitingNotes ?? []).map { trimmed($0) }.filter { !$0.isEmpty }
        )
    }

    /// Whitespace-only editorial text counts as missing, so Presentation can test `isEmpty`.
    private static func trimmed(_ text: String?) -> String {
        (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Open enums

    static func type(from raw: String) -> ILTempleType {
        switch raw {
        case "CHUA": return .chua
        case "THIEN_VIEN": return .thienVien
        case "DAO_TRANG": return .daoTrang
        case "TINH_XA": return .tinhXa
        case "THIEN_XA": return .thienXa
        default: return .other(raw)
        }
    }

    static func region(from raw: String) -> ILTempleRegion {
        switch raw {
        case "north": return .north
        case "central": return .central
        case "south": return .south
        default: return .other(raw)
        }
    }

    static func heritageRank(from raw: String) -> ILTempleHeritageRank {
        switch raw {
        case "DI_SAN_THE_GIOI": return .worldHeritage
        case "DI_TICH_QUOC_GIA_DAC_BIET": return .specialNationalRelic
        case "KHU_DU_LICH_QUOC_GIA": return .nationalTouristArea
        case "DI_TICH_QUOC_GIA": return .nationalRelic
        case "DANH_LAM_THANG_CANH": return .scenicLandscape
        case "DI_TICH_CAP_TINH": return .provincialRelic
        case "DI_TICH_CAP_THANH_PHO": return .cityRelic
        case "CHUA_XEP_HANG": return .unranked
        default: return .other(raw)
        }
    }
}
