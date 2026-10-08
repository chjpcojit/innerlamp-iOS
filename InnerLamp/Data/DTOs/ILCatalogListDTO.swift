//
//  ILCatalogListDTO.swift
//  InnerLamp
//

import Foundation

/// `data` of the catalog "top" endpoints (`/v1/temples/top`, `/v1/deities/top`) — Data layer.
/// Keys are decoded by `NetworkServiceImpl`'s `.convertFromSnakeCase` strategy.
nonisolated struct ILCatalogTopListDTO<Item: Decodable & Sendable>: Decodable, Sendable {
    let items: [Item]
}

/// `data` of the paged catalog endpoints (`/v1/temples?page=N`, `/v1/deities?page=N`).
///
/// Page-number based, 1-based. The page size is fixed by the server (no client `limit`); a page
/// past the end is `200` with `items: []`. `total` / `totalPages` are always present.
nonisolated struct ILCatalogPageDTO<Item: Decodable & Sendable>: Decodable, Sendable {
    let items: [Item]
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPages: Int
}
