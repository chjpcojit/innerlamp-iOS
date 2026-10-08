//
//  ILTempleCatalogLabels.swift
//  InnerLamp
//

import Foundation

/// Display labels for the server temple catalog's enum-like fields — shared by the Home "Chùa Việt
/// Nam" carousel and the Temple detail screen so both show the same wording.
enum ILTempleCatalogLabels {

    /// Administrative prefixes dropped from the province/city shown on a temple card.
    private static let provincePrefixes = ["Tỉnh ", "Thành phố "]

    /// One-line place for a temple card — the last address component (province / city), without
    /// its "Tỉnh " / "Thành phố " prefix: "Xã Ninh Hải, Huyện Hoa Lư, Tỉnh Ninh Bình" → "Ninh Bình".
    static func shortPlace(from address: String) -> String {
        guard let last = addressComponents(of: address).last else { return "" }
        for prefix in provincePrefixes where last.hasPrefix(prefix) {
            return String(last.dropFirst(prefix.count))
        }
        return last
    }

    /// The comma-separated parts of a server address, trimmed, empty parts dropped.
    static func addressComponents(of address: String) -> [String] {
        address
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Region badge — "Miền Bắc" / "Miền Trung" / "Miền Nam"; an unknown server value is shown raw.
    static func regionLabel(_ region: ILTempleRegion) -> String {
        switch region {
        case .north: return "temple.region.north".localized
        case .central: return "temple.region.central".localized
        case .south: return "temple.region.south".localized
        case .other(let raw): return raw
        }
    }

    /// Heritage rank label, or `nil` when the temple is unranked or the value is unknown.
    static func heritageRankLabel(_ rank: ILTempleHeritageRank) -> String? {
        switch rank {
        case .worldHeritage: return "temple.rank.worldHeritage".localized
        case .specialNationalRelic: return "temple.rank.specialNationalRelic".localized
        case .nationalTouristArea: return "temple.rank.nationalTouristArea".localized
        case .nationalRelic: return "temple.rank.nationalRelic".localized
        case .scenicLandscape: return "temple.rank.scenicLandscape".localized
        case .provincialRelic: return "temple.rank.provincialRelic".localized
        case .cityRelic: return "temple.rank.cityRelic".localized
        case .unranked, .other: return nil
        }
    }

    /// Sect label for the server's raw `sect` string (not an enum in the contract; seen values:
    /// "BẮC_TÔNG", "NAM_TONG_KHMER", "HOA_TONG", "TRUC_LAM_YEN_TU", "TIN_NGUONG_DANG_GIAN" — the
    /// server mixes accented and unaccented spellings, so matching ignores diacritics). An unknown
    /// value falls back to the raw string with "_" as spaces, sentence-cased ("BẮC_TÔNG" →
    /// "Bắc tông").
    static func sectLabel(_ raw: String) -> String {
        let normalized = raw
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi"))
            .replacingOccurrences(of: "đ", with: "d")
            .uppercased()
        switch normalized {
        case "BAC_TONG": return "temple.sect.bacTong".localized
        case "NAM_TONG": return "temple.sect.namTong".localized
        case "NAM_TONG_KHMER": return "temple.sect.namTongKhmer".localized
        case "HOA_TONG": return "temple.sect.hoaTong".localized
        case "KHAT_SI": return "temple.sect.khatSi".localized
        case "TRUC_LAM_YEN_TU": return "temple.sect.trucLam".localized
        case "TIN_NGUONG_DANG_GIAN": return "temple.sect.folk".localized
        default:
            let spaced = raw.replacingOccurrences(of: "_", with: " ").lowercased()
            return spaced.prefix(1).uppercased() + spaced.dropFirst()
        }
    }
}
