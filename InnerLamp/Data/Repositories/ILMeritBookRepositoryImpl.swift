//
//  ILMeritBookRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// In-memory sample data matching the design handoff (`DN_HIST`, `DN_BUILD`). There is no donation
/// API contract yet, so nothing is persisted: the monthly-support stop only lives for this session.
// @ai: assumption — see Docs/Assumptions/MeritBook/AS-MeritBook-001-merit-book-data-is-sample-data.md
final class ILMeritBookRepositoryImpl: ILMeritBookRepository {

    private var monthlySupport: ILMeritMonthlySupportEntity? = ILMeritMonthlySupportEntity(
        amount: 100_000,
        templeName: "meritBook.mock.temple.tuQuang".localized
    )

    func fetchMeritBook() async throws -> ILMeritBookEntity {
        // TODO: replace with the donation-history / financial-disclosure API when a contract
        // exists (use data-builder); see Docs/Tech-Debt/MeritBook/TD-MeritBook-001.
        ILMeritBookEntity(
            offerings: Self.sampleOfferings(),
            letter: ILMeritLetterEntity(
                body: "meritBook.mock.letter.body".localized,
                signerName: "meritBook.mock.letter.signerName".localized,
                signerTitle: "meritBook.mock.letter.signerTitle".localized
            ),
            monthlySupport: monthlySupport,
            buildProject: Self.sampleBuildProject()
        )
    }

    func stopMonthlySupport() async throws {
        monthlySupport = nil
    }

    // MARK: - Sample data
    private static func sampleOfferings() -> [ILMeritOfferingEntity] {
        let tuQuang = "meritBook.mock.temple.tuQuang".localized
        let trucLam = "meritBook.mock.temple.trucLam".localized
        let vinhNghiem = "meritBook.mock.temple.vinhNghiem".localized
        return [
            offering("2026-09-02", .threeJewels, tuQuang, 200_000),
            offering("2026-08-15", .templeLamp, tuQuang, 100_000),
            offering("2026-07-28", .monkMeal, trucLam, 500_000),
            offering("2026-07-10", .construction, tuQuang, 300_000),
            offering("2025-11-12", .charityKitchen, vinhNghiem, 200_000)
        ]
    }

    private static func offering(
        _ day: String,
        _ purpose: ILMeritPurpose,
        _ temple: String,
        _ amount: Int
    ) -> ILMeritOfferingEntity {
        ILMeritOfferingEntity(
            id: "\(day)-\(temple)",
            date: date(day),
            purpose: purpose,
            templeName: temple,
            amount: amount,
            isConfirmedByTemple: true
        )
    }

    private static func sampleBuildProject() -> ILMeritBuildProjectEntity {
        ILMeritBuildProjectEntity(
            name: "meritBook.mock.build.name".localized,
            subtitle: "meritBook.mock.build.subtitle".localized,
            raisedMillions: 412,
            goalMillions: 600,
            updatedAt: date("2026-10-01"),
            expenses: [
                .init(label: "meritBook.mock.build.expense.tiles".localized, amount: 128_000_000),
                .init(label: "meritBook.mock.build.expense.timber".localized, amount: 96_000_000),
                .init(label: "meritBook.mock.build.expense.labor".localized, amount: 54_000_000)
            ]
        )
    }

    private static func date(_ iso: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: iso) ?? Date(timeIntervalSince1970: 0)
    }
}
