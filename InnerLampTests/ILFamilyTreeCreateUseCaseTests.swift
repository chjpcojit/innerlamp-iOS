//
//  ILFamilyTreeCreateUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILFamilyTreeCreateUseCaseTests: XCTestCase {

    private var sut: ILFamilyTreeCreateUseCaseImpl!

    override func setUp() {
        super.setUp()
        sut = ILFamilyTreeCreateUseCaseImpl()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    private func draft(
        clan: String = "Trần Văn", home: String = "Hành Thiện", founder: String = "Trần Văn Khải",
        birth: String = "1820", living: Bool = false, death: String = "1890", anniversary: String = "", spouse: String = ""
    ) -> ILFamilyTreeCreateDraft {
        ILFamilyTreeCreateDraft(
            clanName: clan, hometown: home, founderName: founder, birthYear: birth,
            isFounderLiving: living, deathYear: death, anniversary: anniversary, spouseName: spouse
        )
    }

    private func issue(_ draft: ILFamilyTreeCreateDraft) -> ILFamilyTreeCreateIssue? {
        if case .failure(let issue) = sut.createTree(from: draft, currentYear: 2026) { return issue }
        return nil
    }

    private func tree(_ draft: ILFamilyTreeCreateDraft) -> ILFamilyTreeEntity? {
        if case .success(let tree) = sut.createTree(from: draft, currentYear: 2026) { return tree }
        return nil
    }

    // MARK: - Clan display name
    func test_clanDisplayName_addsPrefixOnce() {
        XCTAssertEqual(sut.clanDisplayName("Trần Văn"), "Họ Trần Văn")
        XCTAssertEqual(sut.clanDisplayName("Họ Trần Văn"), "Họ Trần Văn")
        XCTAssertEqual(sut.clanDisplayName("  họ trần  "), "họ trần")
        XCTAssertEqual(sut.clanDisplayName("   "), "")
        // "Hồ" / "Hộ" are different clans from "Họ" — only an exact prefix counts.
        XCTAssertEqual(sut.clanDisplayName("Hồ Văn"), "Họ Hồ Văn")
    }

    // MARK: - Required fields (first failing field wins, in form order)
    func test_requiredFields_reportedInFormOrder() {
        XCTAssertEqual(issue(draft(clan: " "))?.field, .clanName)
        XCTAssertEqual(issue(draft(home: ""))?.field, .hometown)
        XCTAssertEqual(issue(draft(founder: ""))?.field, .founderName)
        XCTAssertEqual(issue(draft(clan: "", home: "", founder: ""))?.field, .clanName)
    }

    // MARK: - Years
    func test_birthYear_requiredAndRanged() {
        XCTAssertEqual(issue(draft(birth: ""))?.field, .birthYear)
        XCTAssertEqual(issue(draft(birth: "1299"))?.field, .birthYear)
        XCTAssertEqual(issue(draft(birth: "2027", living: true))?.field, .birthYear)
        XCTAssertNil(issue(draft(birth: "1300", death: "1301")))
        XCTAssertNil(issue(draft(birth: "2026", living: true)))
    }

    func test_deathYear_requiredWhenDeceasedAndAfterBirth() {
        XCTAssertEqual(issue(draft(death: ""))?.field, .deathYear)
        XCTAssertEqual(issue(draft(birth: "1820", death: "1819"))?.field, .deathYear)
        XCTAssertEqual(issue(draft(death: "2027"))?.field, .deathYear)
        XCTAssertNil(issue(draft(birth: "1820", death: "1820")))
    }

    func test_deathYear_ignoredWhenLiving() {
        XCTAssertNil(issue(draft(birth: "1950", living: true, death: "")))
        XCTAssertNil(tree(draft(birth: "1950", living: true, death: "1900", anniversary: "garbage"))?.members.first?.deathYear)
    }

    // MARK: - Anniversary
    func test_anniversary_parsesNamedAndNumberedMonths() {
        let cases: [(String, ILFamilyLunarDate)] = [
            ("15 tháng Chạp", ILFamilyLunarDate(day: 15, month: 12)),
            ("3 tháng 8", ILFamilyLunarDate(day: 3, month: 8)),
            ("10/2", ILFamilyLunarDate(day: 10, month: 2)),
            ("1 tháng Giêng", ILFamilyLunarDate(day: 1, month: 1)),
            ("20 tháng Mười Một", ILFamilyLunarDate(day: 20, month: 11)),
            ("20 THÁNG MƯỜI", ILFamilyLunarDate(day: 20, month: 10))
        ]
        for (text, expected) in cases {
            XCTAssertEqual(tree(draft(anniversary: text))?.members.first?.anniversary, expected, text)
        }
    }

    func test_anniversary_rejectsUnreadableText() {
        for text in ["mùng một", "31 tháng 1", "0 tháng 1", "5 tháng 13", "15", "15 tháng"] {
            XCTAssertEqual(issue(draft(anniversary: text))?.field, .anniversary, text)
        }
    }

    func test_anniversary_emptyIsAllowed() {
        XCTAssertNil(tree(draft(anniversary: ""))?.members.first?.anniversary)
    }

    // MARK: - Built tree
    func test_createTree_buildsFounderAlone() throws {
        let result = try XCTUnwrap(tree(draft(clan: "Trần Văn", home: " Hành Thiện ", founder: " Trần Văn Khải ")))
        XCTAssertEqual(result.clanName, "Họ Trần Văn")
        XCTAssertEqual(result.hometown, "Hành Thiện")
        XCTAssertEqual(result.members.count, 1)
        let founder = try XCTUnwrap(result.members.first)
        XCTAssertEqual(founder.id, "p1")
        XCTAssertEqual(founder.name, "Trần Văn Khải")
        XCTAssertEqual(founder.gender, .male)
        XCTAssertEqual(founder.birthYear, 1820)
        XCTAssertEqual(founder.deathYear, 1890)
        XCTAssertNil(founder.parentID)
        XCTAssertFalse(founder.isClanHead)
    }

    func test_createTree_addsSpouseLinkedToFounder() throws {
        let result = try XCTUnwrap(tree(draft(spouse: " Lê Thị Hiền ")))
        XCTAssertEqual(result.members.count, 2)
        let spouse = try XCTUnwrap(result.members.last)
        XCTAssertEqual(spouse.id, "s1")
        XCTAssertEqual(spouse.name, "Lê Thị Hiền")
        XCTAssertEqual(spouse.gender, .female)
        XCTAssertEqual(spouse.spouseID, "p1")
        XCTAssertNil(spouse.parentID)
    }

    func test_createTree_livingFounderHasNoDeathData() throws {
        let founder = try XCTUnwrap(tree(draft(birth: "1950", living: true))?.members.first)
        XCTAssertTrue(founder.isLiving)
        XCTAssertNil(founder.anniversary)
    }

    // MARK: - Save (stub)
    func test_save_doesNotThrow() async throws {
        try await sut.save(.empty)
    }
}
