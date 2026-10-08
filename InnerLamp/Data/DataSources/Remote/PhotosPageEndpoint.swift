//
//  PhotosPageEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/gallery?page=N[&type=T]`. Returns
/// `ILCatalogPageDTO<ILPhotosSummaryDTO>` (fixed page size 20).
///
/// Public endpoint: `requiresAuth == false` — the gallery routes take no `Authorization` header.
nonisolated struct PhotosPageEndpoint: Endpoint {
    /// 1-based. The server answers `400 INVALID_PAGE` for 0 / negative values.
    let page: Int
    /// Server `type` value (`CHUA`, `TUONG_PHAT`, `THIEN`, `LE_HOI`); `nil` = all. Any other
    /// value is `400 INVALID_GALLERY_TYPE`.
    let type: String?

    var queryParameters: [String: String]? {
        var parameters = ["page": String(page)]
        if let type { parameters["type"] = type }
        return parameters
    }

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/gallery" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}
