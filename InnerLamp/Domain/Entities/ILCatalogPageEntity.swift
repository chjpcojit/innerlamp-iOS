//
//  ILCatalogPageEntity.swift
//  InnerLamp
//

import Foundation

/// One page of a "show all" catalog list (temples, deities) — Domain layer only.
///
/// `page` is 1-based, matching the server contract. `hasMore == false` means the caller should
/// stop requesting further pages: either the server reported `page >= total_pages`, or it returned
/// an empty page.
nonisolated struct ILCatalogPageEntity<Item: Equatable>: Equatable {
    let items: [Item]
    let page: Int
    let hasMore: Bool
}
