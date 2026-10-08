//
//  ILCatalogTestSupport.swift
//  InnerLampTests
//
//  Shared fixtures for the server-backed catalog repositories (temples, deities).
//

import Foundation
@testable import InnerLamp

// MARK: - Mock NetworkService

/// Routes each request by `path` (+ `?page=N`) to a canned envelope JSON string and decodes it
/// with the same `.convertFromSnakeCase` envelope decoding `NetworkServiceImpl` uses — so the DTOs
/// are exercised against real wire shapes. An unrouted request throws `.noInternetConnection`,
/// which doubles as "the device is offline".
final class MockCatalogNetworkService: NetworkService {
    /// Canned response per route key (see `routeKey(for:)`).
    var responses: [String: Result<String, NetworkError>] = [:]
    /// Every route key requested, in order.
    private(set) var requestedRoutes: [String] = []

    func request<T: Decodable & Sendable>(endpoint: Endpoint, responseType: T.Type) async throws -> T {
        let key = Self.routeKey(for: endpoint)
        requestedRoutes.append(key)
        guard let result = responses[key] else { throw NetworkError.noInternetConnection }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let envelope = try decoder.decode(APIEnvelope<T>.self, from: Data(try result.get().utf8))
        guard let data = envelope.data else { throw NetworkError.noData }
        return data
    }

    func request(endpoint: Endpoint) async throws {
        requestedRoutes.append(Self.routeKey(for: endpoint))
    }

    static func routeKey(for endpoint: Endpoint) -> String {
        endpoint.path + (endpoint.queryParameters?["page"].map { "?page=\($0)" } ?? "")
    }
}

// MARK: - JSON fixtures

enum ILCatalogFixtures {

    static func envelope(_ data: String) -> String {
        #"{"success":true,"data":\#(data)}"#
    }

    static func apiError(_ code: String) -> NetworkError {
        .apiError(code: code, message: "server message", type: "business", details: nil)
    }

    // MARK: Temples

    static func templeSummary(id: String, type: String = "CHUA", rank: String = "DI_TICH_QUOC_GIA") -> String {
        #"""
        {"id":"\#(id)","name":"Chùa \#(id)","type":"\#(type)","region":"north","thumbnail_url":null,"image_url":null,"sect":"BẮC_TÔNG","heritage_rank":"\#(rank)","established_year":1428,"location":{"lat":20.2185,"lng":105.9177,"address":"Ninh Bình"}}
        """#
    }

    /// Page `page` of a `total`-row list with page size 20; ids are `t<position>`.
    static func templesPage(_ page: Int, total: Int, pageSize: Int = 20) -> String {
        let lower = (page - 1) * pageSize
        let ids = lower < total ? Array(lower..<min(lower + pageSize, total)) : []
        let items = ids.map { templeSummary(id: "t\($0)") }.joined(separator: ",")
        let totalPages = (total + pageSize - 1) / pageSize
        return envelope(#"{"items":[\#(items)],"page":\#(page),"page_size":\#(pageSize),"total":\#(total),"total_pages":\#(totalPages)}"#)
    }

    static func topTemples(ids: [String]) -> String {
        envelope(#"{"items":[\#(ids.map { templeSummary(id: $0) }.joined(separator: ","))]}"#)
    }

    /// Contract v1.0 shape, captured from `GET /v1/temples/temple_north_011` on the dev server
    /// (2026-09-29) — no editorial fields. Kept to prove a pre-v1.1 payload still decodes.
    static let templeDetailV1_0 = envelope(#"""
    {"id":"temple_north_011","name":"Chùa Bích Động","type":"CHUA","region":"north","thumbnail_url":null,"image_url":null,"sect":"BẮC_TÔNG","heritage_rank":"DI_SAN_THE_GIOI","established_year":1428,"location":{"lat":20.2185,"lng":105.9177,"address":"Xã Ninh Hải, Huyện Hoa Lư, Tỉnh Ninh Bình"},"aliases":["Bạch Ngọc Thạch Sơn Động"],"founder":"Hai nhà sư Trí Kiên và Trí Thể","current_abbot":"Thích Đức Lợi","operating_hours":"07:00 - 18:00","amenities":{"parking_car":true,"parking_motorcycle":true,"vegetarian_meals":false,"summer_retreat":false}}
    """#)

    /// Contract v1.1 shape (v1.0 + `introduction` / `architecture_heritage` / `visiting_notes`);
    /// editorial text shortened. Includes a whitespace-only note the mapper must drop.
    static let templeDetail = envelope(#"""
    {"id":"temple_north_011","name":"Chùa Bích Động","type":"CHUA","region":"north","thumbnail_url":null,"image_url":null,"sect":"BẮC_TÔNG","heritage_rank":"DI_SAN_THE_GIOI","established_year":1428,"location":{"lat":20.2185,"lng":105.9177,"address":"Xã Ninh Hải, Huyện Hoa Lư, Tỉnh Ninh Bình"},"aliases":["Bạch Ngọc Thạch Sơn Động"],"founder":"Hai nhà sư Trí Kiên và Trí Thể","current_abbot":"Thích Đức Lợi","operating_hours":"07:00 - 18:00","amenities":{"parking_car":true,"parking_motorcycle":true,"vegetarian_meals":false,"summer_retreat":false},"introduction":"Chùa Bích Động nằm ở Ninh Bình.","architecture_heritage":"Chùa gồm ba ngôi Hạ, Trung, Thượng.","visiting_notes":["Đường lên chùa có nhiều bậc đá."," ","Trang phục kín đáo."]}
    """#)

    // MARK: Deities

    static func deitySummary(id: String, type: String = "BODHISATTVA") -> String {
        #"""
        {"id":"\#(id)","type":"\#(type)","name_vi":"Vị \#(id)","name_sanskrit":"S","name_chinese":"C","title_honorific":"T","thumbnail_url":"assets/images/buddhas/thumbnails/\#(id).webp","image_url":"https://cdn.yourapp.com/images/buddhas/full/\#(id).webp","core_virtue":"V","pure_land":"P"}
        """#
    }

    /// `/v1/deities?page=N` — ids starting with `buddha_` are typed BUDDHA, the rest BODHISATTVA.
    static func deitiesPage(_ page: Int, ids: [String], total: Int, pageSize: Int = 20) -> String {
        let items = ids.map { deitySummary(id: $0, type: $0.hasPrefix("buddha_") ? "BUDDHA" : "BODHISATTVA") }
            .joined(separator: ",")
        let totalPages = (total + pageSize - 1) / pageSize
        return envelope(#"{"items":[\#(items)],"page":\#(page),"page_size":\#(pageSize),"total":\#(total),"total_pages":\#(totalPages)}"#)
    }

    static func topDeities(ids: [String]) -> String {
        envelope(#"{"items":[\#(ids.map { deitySummary(id: $0, type: "BUDDHA") }.joined(separator: ","))]}"#)
    }

    /// Captured from `GET /v1/deities/buddha_amitabha` on the dev server (2026-09-29).
    static let deityDetail = envelope(#"""
    {"id":"buddha_amitabha","type":"BUDDHA","name_vi":"A Di Đà Phật","name_sanskrit":"Amitābha Buddha / Amitāyus","name_chinese":"阿彌陀佛","title_honorific":"Nam Mô Tiếp Dẫn Đạo Sư A Di Đà Phật","thumbnail_url":"assets/images/buddhas/thumbnails/buddha_amitabha.webp","image_url":"https://cdn.yourapp.com/images/buddhas/full/buddha_amitabha.webp","core_virtue":"Từ Bi Tiếp Dẫn (Ánh sáng vô lượng, Thọ mạng vô lượng)","pure_land":"Tây Phương Cực Lạc (Sukhāvatī)","canonical_source":"Kinh Vô Lượng Thọ, Kinh A Di Đà, Kinh Quán Vô Lượng Thọ","lunar_memorial_days":[{"lunar_day":17,"lunar_month":11,"event_name":"Ngày Vía Đức Phật A Di Đà"}],"iconography":{"posture":"Đứng tiếp dẫn hoặc ngồi kiết già, mắt nhìn xuống cõi thế gian","mount_or_throne":"Đài sen báu nâng đỡ","sacred_artifacts":["Đài sen báu trên tay trái","Tay phải duỗi xuống kết ấn Tiếp Dẫn"],"symbolic_meaning":"Tượng trưng cho sự đón rước chúng sinh vãng sanh về cõi Cực Lạc giải thoát."},"biography_summary":"Tiền thân là Tỳ-kheo Pháp Tạng.","great_vows":["Bốn mươi tám đại nguyện.","Tiếp dẫn hương linh."],"mantras":{"short_mantra_sanskrit":"Oṃ Amṛta Teje Hara Hūṃ","short_mantra_sino_vietnamese":"Án A Mật Rị Đa Tế Già Đê Hạ Lăng Hồng","long_dharani_name":"Chú Vãng Sanh","dharani_phonetic_snippet":"Nam mô a di đa bà dạ..."}}
    """#)
}
