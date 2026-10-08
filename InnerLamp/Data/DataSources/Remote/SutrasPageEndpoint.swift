//
//  SutrasPageEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `GET /v1/sutras?page=N[&daily=true|purpose=…|tradition=…][&max_minutes=…][&q=…]`.
/// Returns `ILCatalogPageDTO<ILSutraDTO>` (fixed page size 20; filters combine with AND).
///
/// Public endpoint: `requiresAuth == false` — the catalog routes take no `Authorization` header.
nonisolated struct SutrasPageEndpoint: Endpoint {
    /// 1-based. The server answers `400 INVALID_PAGE` for 0 / negative values.
    let page: Int
    let filter: ILSutraFilter

    var queryParameters: [String: String]? {
        var parameters = ["page": String(page)]
        switch filter.category {
        case .all: break
        case .dailyChant: parameters["daily"] = "true"
        case .purpose(let purpose): parameters["purpose"] = purpose.wireValue
        case .tradition(let tradition): parameters["tradition"] = tradition.wireValue
        }
        if let maxMinutes = filter.length.maxMinutes {
            parameters["max_minutes"] = String(maxMinutes)
        }
        // The server answers `400 INVALID_FILTER` for a blank or over-long `q`, so it is only sent
        // when the ViewModel produced a usable keyword.
        if !filter.query.isEmpty {
            parameters["q"] = filter.query
        }
        return parameters
    }

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/sutras" }
    var method: HTTPMethod { .get }
    var requiresAuth: Bool { false }
}

// MARK: - Wire values

nonisolated extension ILSutraPurpose {
    private static let wireValues: [(ILSutraPurpose, String)] = [
        (.blessing, "CAU_AN"), (.requiem, "CAU_SIEU"), (.mantra, "TRI_CHU"),
        (.repentance, "SAM_HOI"), (.dedication, "HOI_HUONG"), (.vow, "PHAT_NGUYEN"),
        (.karmicReward, "BAO_HIEU"), (.meditation, "THIEN_DINH"), (.study, "HOC_GIAO_LY"),
        (.refugePrecepts, "QUY_Y_THO_GIOI")
    ]

    var wireValue: String { Self.wireValues.first { $0.0 == self }?.1 ?? "" }

    init?(wireValue: String) {
        guard let match = Self.wireValues.first(where: { $0.1 == wireValue }) else { return nil }
        self = match.0
    }
}

nonisolated extension ILSutraTradition {
    var wireValue: String {
        switch self {
        case .theravada: return "THERAVADA"
        case .mahayana: return "MAHAYANA"
        case .vajrayana: return "VAJRAYANA"
        }
    }

    init?(wireValue: String) {
        guard let match = Self.allCases.first(where: { $0.wireValue == wireValue }) else { return nil }
        self = match
    }
}

nonisolated extension ILSutraKind {
    init?(wireValue: String) {
        switch wireValue {
        case "SUTRA": self = .sutra
        case "VERSE": self = .verse
        case "DHARANI": self = .dharani
        default: return nil
        }
    }
}
