//
//  ILSutraRepositoryTests.swift
//  InnerLampTests
//
//  Covers `ILSutraRepositoryImpl` below the Domain boundary: endpoint construction, DTO decoding of
//  the real wire shapes (snake_case envelope), mapping, and `NetworkError` → `ILCatalogError`.
//

import XCTest
@testable import InnerLamp

@MainActor
final class ILSutraRepositoryTests: XCTestCase {

    private var network: MockCatalogNetworkService!
    private var repository: ILSutraRepository!

    override func setUp() {
        super.setUp()
        network = MockCatalogNetworkService()
        repository = ILSutraRepositoryImpl(networkService: network)
    }

    override func tearDown() {
        repository = nil
        network = nil
        super.tearDown()
    }

    // MARK: - Fixtures (shapes captured from the dev server, 2026-10-07)

    private let listItem = #"""
    {"id":"kinh-hanh-phuc","tradition":"THERAVADA","kind":"VERSE","collection":"Tiểu Bộ","reference":"Snp 2.4","titles":{"en":"True Blessings","pli":"Maṅgalasutta","vi":"Kinh Hạnh Phúc"},"daily_chant":true,"purposes":["CAU_AN","SOMETHING_NEW"],"duration_minutes":4,"deities":[{"deity_id":"buddha_shakyamuni","role":"SPEAKER","name_vi":"Thích Ca Mâu Ni Phật","thumbnail_url":"http://host/t.webp"}],"translations":[{"key":"pli-translation","lang":"pli","variant":"translation","translator":"Mahāsaṅgīti","license":"CC0","line_count":10},{"key":"vi-translation","lang":"vi","variant":"translation","translator":"Thích Minh Châu","license":"unknown","line_count":55}]}
    """#

    private func detailJSON(sourceURL: String = "https://suttacentral.net/snp1.8", sections: String = "[]") -> String {
        #"""
        {"id":"kinh-tu-bi","tradition":"THERAVADA","kind":"VERSE","collection":"Tiểu Bộ","reference":"Snp 1.8","titles":{"en":"The Discourse on Love","pli":"Karaṇīyamettasutta","vi":"Kinh Từ Bi"},"daily_chant":true,"purposes":["CAU_AN"],"duration_minutes":null,"deities":[],"review_status":"UNREVIEWED","translations":[{"key":"en-translation","lang":"en","variant":"translation","translator":"Sujato","license":"CC0","line_count":60,"source_name":"SuttaCentral EN","source_url":"https://x.test/en","note":"","sections":[]},{"key":"vi-translation","lang":"vi","variant":"translation","translator":"Thích Minh Châu","license":"unknown (...)","line_count":73,"source_name":"SuttaCentral","source_url":"\#(sourceURL)","note":"","sections":\#(sections)}]}
        """#
    }

    private func pageJSON(page: Int, total: Int, totalPages: Int, items: [String]) -> String {
        ILCatalogFixtures.envelope(
            #"{"items":[\#(items.joined(separator: ","))],"page":\#(page),"page_size":20,"total":\#(total),"total_pages":\#(totalPages)}"#
        )
    }

    // MARK: - Endpoint

    func test_pageEndpoint_sendsOnlyPageForDefaultFilter() {
        let endpoint = SutrasPageEndpoint(page: 3, filter: ILSutraFilter())

        XCTAssertEqual(endpoint.path, "/v1/sutras")
        XCTAssertEqual(endpoint.queryParameters, ["page": "3"])
        XCTAssertFalse(endpoint.requiresAuth)
    }

    func test_pageEndpoint_mapsEveryCategoryToItsServerParameter() {
        func query(_ category: ILSutraCategory, _ length: ILSutraLengthFilter = .any) -> [String: String]? {
            SutrasPageEndpoint(page: 1, filter: ILSutraFilter(category: category, length: length)).queryParameters
        }

        XCTAssertEqual(query(.dailyChant), ["page": "1", "daily": "true"])
        XCTAssertEqual(query(.tradition(.vajrayana)), ["page": "1", "tradition": "VAJRAYANA"])
        XCTAssertEqual(query(.purpose(.refugePrecepts), .upTo15), ["page": "1", "purpose": "QUY_Y_THO_GIOI", "max_minutes": "15"])
        XCTAssertEqual(
            SutrasPageEndpoint(page: 2, filter: ILSutraFilter(category: .dailyChant, query: "đại bi")).queryParameters,
            ["page": "2", "daily": "true", "q": "đại bi"],
            "The keyword combines with the other filters"
        )
        let purposes = ILSutraPurpose.allCases.map { query(.purpose($0))?["purpose"] }
        XCTAssertEqual(
            purposes,
            ["CAU_AN", "CAU_SIEU", "TRI_CHU", "SAM_HOI", "HOI_HUONG", "PHAT_NGUYEN", "BAO_HIEU", "THIEN_DINH", "HOC_GIAO_LY", "QUY_Y_THO_GIOI"]
        )
    }

    func test_detailEndpoint_encodesTheIdAsOnePathSegment() {
        XCTAssertEqual(SutraDetailEndpoint(id: "kinh-tu-bi").path, "/v1/sutras/kinh-tu-bi")
        XCTAssertEqual(SutraDetailEndpoint(id: "a/b").path, "/v1/sutras/a%2Fb")
    }

    // MARK: - List

    func test_loadSutras_mapsRealListShape() async throws {
        network.responses["/v1/sutras?page=1"] = .success(pageJSON(page: 1, total: 153, totalPages: 8, items: [listItem]))

        let page = try await repository.loadSutras(page: 1, filter: ILSutraFilter())

        XCTAssertEqual(page.totalCount, 153)
        XCTAssertTrue(page.hasMore)
        let sutra = try XCTUnwrap(page.items.first)
        XCTAssertEqual(sutra.id, "kinh-hanh-phuc")
        XCTAssertEqual(sutra.title, "Kinh Hạnh Phúc")
        XCTAssertEqual(sutra.originalTitle, "Maṅgalasutta")
        XCTAssertEqual(sutra.kind, .verse)
        XCTAssertEqual(sutra.tradition, .theravada)
        XCTAssertEqual(sutra.collection, "Tiểu Bộ")
        XCTAssertTrue(sutra.isDailyChant)
        XCTAssertEqual(sutra.purposes, [.blessing], "An unknown purpose from a newer server is dropped, not fatal")
        XCTAssertEqual(sutra.durationMinutes, 4)
        XCTAssertEqual(sutra.translator, "Thích Minh Châu", "The Vietnamese translation wins over the first listed")
    }

    func test_loadSutras_mapsAudioUrl_emptyOrMissingMeansNoAudio() async throws {
        let withAudio = #"{"id":"a","titles":{"vi":"A"},"daily_chant":false,"purposes":[],"translations":[],"audio_url":"https://cdn.test/a.mp3"}"#
        let emptyAudio = #"{"id":"b","titles":{"vi":"B"},"daily_chant":false,"purposes":[],"translations":[],"audio_url":""}"#
        let missingAudio = #"{"id":"c","titles":{"vi":"C"},"daily_chant":false,"purposes":[],"translations":[]}"#
        network.responses["/v1/sutras?page=1"] = .success(pageJSON(page: 1, total: 3, totalPages: 1, items: [withAudio, emptyAudio, missingAudio]))

        let page = try await repository.loadSutras(page: 1, filter: ILSutraFilter())

        XCTAssertEqual(page.items.map(\.audioURL), ["https://cdn.test/a.mp3", "", ""])
        XCTAssertEqual(page.items.map(\.hasAudio), [true, false, false])
    }

    func test_loadSutras_lastPage_hasNoMore() async throws {
        network.responses["/v1/sutras?page=8"] = .success(pageJSON(page: 8, total: 153, totalPages: 8, items: [listItem]))

        let page = try await repository.loadSutras(page: 8, filter: ILSutraFilter())

        XCTAssertFalse(page.hasMore)
    }

    func test_loadSutras_pastTheEnd_isEmptyAndHasNoMore() async throws {
        network.responses["/v1/sutras?page=9"] = .success(pageJSON(page: 9, total: 153, totalPages: 8, items: []))

        let page = try await repository.loadSutras(page: 9, filter: ILSutraFilter())

        XCTAssertEqual(page.items, [])
        XCTAssertFalse(page.hasMore)
    }

    func test_loadSutras_pageBelowOne_throwsInvalidPageWithoutRequest() async {
        do {
            _ = try await repository.loadSutras(page: 0, filter: ILSutraFilter())
            XCTFail("Expected invalidPage")
        } catch {
            guard case ILCatalogError.invalidPage = error else { return XCTFail("Unexpected error: \(error)") }
            XCTAssertEqual(network.requestedRoutes, [])
        }
    }

    func test_loadSutras_offline_mapsToOffline() async {
        do {
            _ = try await repository.loadSutras(page: 1, filter: ILSutraFilter())
            XCTFail("Expected offline")
        } catch {
            guard case ILCatalogError.offline = error else { return XCTFail("Unexpected error: \(error)") }
        }
    }

    func test_title_fallsBackThroughEnglishPaliThenSlug() async throws {
        let onlyEnglish = #"{"id":"a","titles":{"en":"Only English"},"daily_chant":false,"purposes":[],"translations":[]}"#
        let onlyKorean = #"{"id":"b","titles":{"ko":"한국어"},"daily_chant":false,"purposes":[],"translations":[]}"#
        let none = #"{"id":"c","titles":{},"daily_chant":false,"purposes":[],"translations":[]}"#
        network.responses["/v1/sutras?page=1"] = .success(pageJSON(page: 1, total: 3, totalPages: 1, items: [onlyEnglish, onlyKorean, none]))

        let items = try await repository.loadSutras(page: 1, filter: ILSutraFilter()).items

        XCTAssertEqual(items.map(\.title), ["Only English", "한국어", "c"])
        XCTAssertEqual(items.map(\.originalTitle), ["", "", ""])
        XCTAssertEqual(items.map(\.translator), ["", "", ""])
        XCTAssertEqual(items.map(\.tradition), [nil, nil, nil])
    }

    // MARK: - Detail

    func test_loadSutra_mapsDetailFromTheVietnameseTranslation() async throws {
        network.responses["/v1/sutras/kinh-tu-bi"] = .success(ILCatalogFixtures.envelope(detailJSON()))

        let sutra = try await repository.loadSutra(id: "kinh-tu-bi")

        XCTAssertEqual(sutra.title, "Kinh Từ Bi")
        XCTAssertEqual(sutra.originalTitle, "Karaṇīyamettasutta")
        XCTAssertNil(sutra.durationMinutes)
        XCTAssertEqual(sutra.translator, "Thích Minh Châu")
        XCTAssertEqual(sutra.sourceName, "SuttaCentral")
        XCTAssertEqual(sutra.sourceURL, "https://suttacentral.net/snp1.8")
        XCTAssertEqual(sutra.license, "unknown (...)")
        XCTAssertEqual(sutra.lineCount, 73)
        XCTAssertEqual(sutra.chapters, [])
    }

    func test_loadSutra_mapsSectionsInOrder() async throws {
        let sections = #"[{"name":"Phẩm Một","start_n":1,"line_count":30},{"name":"Phẩm Hai","start_n":31,"line_count":43}]"#
        network.responses["/v1/sutras/kinh-tu-bi"] = .success(ILCatalogFixtures.envelope(detailJSON(sections: sections)))

        let sutra = try await repository.loadSutra(id: "kinh-tu-bi")

        XCTAssertEqual(
            sutra.chapters,
            [
                ILSutraDetailChapterEntity(id: "section.1", number: "1", title: "Phẩm Một", lineCount: 30),
                ILSutraDetailChapterEntity(id: "section.2", number: "2", title: "Phẩm Hai", lineCount: 43)
            ]
        )
    }

    /// Shape captured from the dev server (`GET /v1/sutras/kim-quang-minh`, 2026-10-11), shortened.
    func test_loadSutra_mapsEveryDetailOnlyField() async throws {
        let json = #"""
        {"id":"kim-quang-minh","tradition":"MAHAYANA","kind":"SUTRA","collection":"Hộ quốc","reference":"Taishō T0665","titles":{"en":"Golden Light Sutra","sa":"Suvarṇaprabhāsottama Sūtra","vi":"Kinh Kim Quang Minh","zh":"金光明最勝王經","xx":"Other"},"daily_chant":false,"purposes":["HOC_GIAO_LY"],"duration_minutes":900,"audio_url":"","summary":"Kinh Đại thừa dài.","deities":[{"deity_id":"buddha_shakyamuni","role":"SPEAKER","name_vi":"Thích Ca Mâu Ni Phật","thumbnail_url":"http://h/t.webp"},{"deity_id":"x","role":"NEW_ROLE","name_vi":"","thumbnail_url":""}],"review_status":"UNREVIEWED","original_title":"Kim Quang Minh Tối Thắng Vương Kinh","author":"","han_translator":"Nghĩa Tịnh","han_translation_year":703,"reference_note":"Ghi chú","translations":[{"key":"vi-translation","lang":"vi","variant":"chant","translator":"Thích Trí Quang","license":"UNKNOWN","line_count":6450,"source_name":"Quảng Đức","source_url":"http://q.test/k","license_url":"https://l.test/c","license_note":"no license statement","note":"Gộp 31 trang","sections":[]}]}
        """#
        network.responses["/v1/sutras/kim-quang-minh"] = .success(ILCatalogFixtures.envelope(json))

        let sutra = try await repository.loadSutra(id: "kim-quang-minh")

        XCTAssertEqual(sutra.summary, "Kinh Đại thừa dài.")
        XCTAssertEqual(sutra.originalTitle, "Kim Quang Minh Tối Thắng Vương Kinh")
        XCTAssertEqual(sutra.author, "")
        XCTAssertEqual(sutra.hanTranslator, "Nghĩa Tịnh")
        XCTAssertEqual(sutra.hanTranslationYear, 703)
        XCTAssertEqual(sutra.referenceNote, "Ghi chú")
        XCTAssertEqual(
            sutra.deities,
            [
                ILSutraDetailDeityEntity(id: "buddha_shakyamuni", name: "Thích Ca Mâu Ni Phật", role: .speaker),
                ILSutraDetailDeityEntity(id: "x", name: "x", role: nil)
            ]
        )
        XCTAssertEqual(
            sutra.alternateTitles,
            [
                ILSutraDetailAlternateTitleEntity(language: "sa", text: "Suvarṇaprabhāsottama Sūtra"),
                ILSutraDetailAlternateTitleEntity(language: "zh", text: "金光明最勝王經"),
                ILSutraDetailAlternateTitleEntity(language: "en", text: "Golden Light Sutra"),
                ILSutraDetailAlternateTitleEntity(language: "xx", text: "Other")
            ]
        )
        XCTAssertTrue(sutra.isUnreviewed)
        XCTAssertEqual(sutra.variant, .chant)
        XCTAssertEqual(sutra.licenseURL, "https://l.test/c")
        XCTAssertEqual(sutra.licenseNote, "no license statement")
        XCTAssertEqual(sutra.note, "Gộp 31 trang")
    }

    func test_loadSutra_missingDetailOnlyFields_fallBackToEmpty() async throws {
        network.responses["/v1/sutras/kinh-tu-bi"] = .success(ILCatalogFixtures.envelope(
            #"{"id":"kinh-tu-bi","titles":{"vi":"Kinh Từ Bi"},"daily_chant":false,"purposes":[],"translations":[]}"#
        ))

        let sutra = try await repository.loadSutra(id: "kinh-tu-bi")

        XCTAssertEqual(sutra.summary, "")
        XCTAssertEqual(sutra.deities, [])
        XCTAssertNil(sutra.hanTranslationYear)
        XCTAssertFalse(sutra.isUnreviewed)
        XCTAssertNil(sutra.licenseURL)
    }

    func test_loadSutra_dropsNonHTTPSourceLink() async throws {
        network.responses["/v1/sutras/kinh-tu-bi"] = .success(ILCatalogFixtures.envelope(detailJSON(sourceURL: "javascript:alert(1)")))

        let sutra = try await repository.loadSutra(id: "kinh-tu-bi")

        XCTAssertNil(sutra.sourceURL)
    }

    func test_loadSutra_unknownId_mapsToNotFound() async {
        network.responses["/v1/sutras/zzz"] = .failure(ILCatalogFixtures.apiError("SUTRA_NOT_FOUND"))

        do {
            _ = try await repository.loadSutra(id: "zzz")
            XCTFail("Expected notFound")
        } catch {
            guard case ILCatalogError.notFound = error else { return XCTFail("Unexpected error: \(error)") }
        }
    }
}
