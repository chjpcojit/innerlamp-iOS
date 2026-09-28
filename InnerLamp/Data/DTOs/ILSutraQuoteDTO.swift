//
//  ILSutraQuoteDTO.swift
//  InnerLamp
//

import Foundation

/// One record of the bundled `sutra_quotes_300.json` catalog — field names match the JSON keys.
nonisolated struct ILSutraQuoteDTO: Decodable, Equatable {
    let stt: Int
    let kinh: String
    let dichGia: String
    let phamSo: String
    let phamTen: String
    let keSo: Int
    let noiDung: String

    enum CodingKeys: String, CodingKey {
        case stt
        case kinh
        case dichGia = "dich_gia"
        case phamSo = "pham_so"
        case phamTen = "pham_ten"
        case keSo = "ke_so"
        case noiDung = "noi_dung"
    }
}
