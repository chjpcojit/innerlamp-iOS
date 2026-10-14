//
//  ILTempleOptionMapper.swift
//  InnerLamp
//

import Foundation

/// `ILTempleOptionDTO` → `ILTempleOptionEntity`, field for field.
nonisolated enum ILTempleOptionMapper {

    static func toDomain(_ dto: ILTempleOptionDTO) -> ILTempleOptionEntity {
        ILTempleOptionEntity(
            id: dto.id,
            name: dto.name,
            province: dto.province,
            provinceCode: dto.provinceCode
        )
    }

    static func toDomain(_ dto: ILCatalogPageDTO<ILTempleOptionDTO>) -> ILCatalogPageEntity<ILTempleOptionEntity> {
        ILCatalogPageEntity(
            items: dto.items.map(toDomain),
            page: dto.page,
            hasMore: !dto.items.isEmpty && dto.page < dto.totalPages
        )
    }
}
