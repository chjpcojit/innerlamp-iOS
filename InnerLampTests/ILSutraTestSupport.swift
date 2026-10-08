//
//  ILSutraTestSupport.swift
//  InnerLampTests
//
//  Shared fixtures + mock repository for the sutra catalog tests.
//

import Foundation
@testable import InnerLamp

// MARK: - Entity builders

enum ILSutraFixtures {

    static func sutra(
        id: String,
        title: String? = nil,
        originalTitle: String = "",
        tradition: ILSutraTradition? = .theravada,
        isDailyChant: Bool = false,
        purposes: [ILSutraPurpose] = [],
        durationMinutes: Int? = 5,
        translator: String = "Thích Minh Châu",
        audioURL: String = ""
    ) -> ILSutraEntity {
        ILSutraEntity(
            id: id,
            title: title ?? "Kinh \(id)",
            originalTitle: originalTitle,
            kind: .sutra,
            tradition: tradition,
            collection: "Tiểu Bộ",
            reference: "Snp 1.8",
            isDailyChant: isDailyChant,
            purposes: purposes,
            durationMinutes: durationMinutes,
            translator: translator,
            audioURL: audioURL
        )
    }

    static func detail(
        id: String = "kinh-tu-bi",
        chapters: [ILSutraDetailChapterEntity] = []
    ) -> ILSutraDetailSutraEntity {
        ILSutraDetailSutraEntity(
            id: id,
            title: "Kinh Từ Bi",
            originalTitle: "Karaṇīyamettasutta",
            kind: .verse,
            tradition: .theravada,
            collection: "Tiểu Bộ",
            reference: "Snp 1.8",
            isDailyChant: true,
            purposes: [.blessing],
            durationMinutes: 130,
            translator: "Thích Minh Châu",
            sourceName: "SuttaCentral",
            sourceURL: "https://suttacentral.net/snp1.8",
            license: "CC0 1.0",
            lineCount: 73,
            chapters: chapters
        )
    }

    /// Page `page` of a `total`-row list with page size `pageSize`; ids are `s<position>`.
    static func page(_ page: Int, total: Int, pageSize: Int = 2) -> ILSutraPageEntity {
        let lower = (page - 1) * pageSize
        let ids = lower < total ? Array(lower..<min(lower + pageSize, total)) : []
        return ILSutraPageEntity(
            items: ids.map { sutra(id: "s\($0)") },
            page: page,
            totalCount: total,
            hasMore: !ids.isEmpty && lower + ids.count < total
        )
    }
}

// MARK: - Mock repository

/// Records every call and answers from canned values. `onLoadSutras` lets a test replace the
/// answer (e.g. to suspend a request) for a specific call.
final class MockILSutraRepository: ILSutraRepository, @unchecked Sendable {
    var total = 4
    var pageSize = 2
    var listError: Error?
    var detail: ILSutraDetailSutraEntity = ILSutraFixtures.detail()
    var detailError: Error?
    var onLoadSutras: ((Int, ILSutraFilter) async throws -> ILSutraPageEntity)?

    private(set) var listCalls: [(page: Int, filter: ILSutraFilter)] = []
    private(set) var detailCalls: [String] = []

    func loadSutras(page: Int, filter: ILSutraFilter) async throws -> ILSutraPageEntity {
        listCalls.append((page, filter))
        if let onLoadSutras { return try await onLoadSutras(page, filter) }
        if let listError { throw listError }
        return ILSutraFixtures.page(page, total: total, pageSize: pageSize)
    }

    func loadSutra(id: String) async throws -> ILSutraDetailSutraEntity {
        detailCalls.append(id)
        if let detailError { throw detailError }
        return detail
    }
}
