//
//  ILPhotosMapper.swift
//  InnerLamp
//

import Foundation

/// Converts gallery DTOs into Domain entities, and categories into the server's `type` value.
nonisolated enum ILPhotosMapper {

    /// An item whose `type` is not one of the four known values is dropped (`nil`) rather than
    /// failing the whole page.
    static func toDomain(_ dto: ILPhotosSummaryDTO) -> ILPhotosPhotoEntity? {
        guard let category = category(fromType: dto.type) else { return nil }
        return ILPhotosPhotoEntity(
            id: dto.id,
            category: category,
            title: dto.title,
            place: dto.location,
            thumbnailURL: nonEmpty(dto.thumbnailUrl),
            imageURL: nonEmpty(dto.imageUrl)
        )
    }

    static func type(for category: ILPhotosCategory) -> String {
        switch category {
        case .temple: return "CHUA"
        case .buddhaStatue: return "TUONG_PHAT"
        case .meditation: return "THIEN"
        case .festival: return "LE_HOI"
        }
    }

    private static func category(fromType type: String) -> ILPhotosCategory? {
        ILPhotosCategory.allCases.first { Self.type(for: $0) == type }
    }

    private static func nonEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
