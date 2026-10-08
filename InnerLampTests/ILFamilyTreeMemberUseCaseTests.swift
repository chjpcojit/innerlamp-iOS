//
//  ILFamilyTreeMemberUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILFamilyTreeMemberUseCaseTests: XCTestCase {

    private let year = 2026
    private let tree = ILFamilyTreeTestFactory.tree
    private var sut: ILFamilyTreeMemberUseCaseImpl!

    override func setUp() {
        super.setUp()
        sut = ILFamilyTreeMemberUseCaseImpl()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    private func member(_ id: String) -> ILFamilyMemberEntity {
        guard let member = tree.members.first(where: { $0.id == id }) else {
            preconditionFailure("missing test member \(id)")
        }
        return member
    }

    private func livingDraft() -> ILFamilyTreeMemberDraft {
        sut.makeDraft(from: member("p13"))
    }

    private func deceasedDraft() -> ILFamilyTreeMemberDraft {
        sut.makeDraft(from: member("p14"))
    }

    private func update(
        _ draft: ILFamilyTreeMemberDraft, id: String
    ) -> Result<ILFamilyTreeMemberResult, ILFamilyTreeMemberIssue> {
        sut.updateMember(draft, memberID: id, in: tree, currentYear: year)
    }

    private func issue(_ result: Result<ILFamilyTreeMemberResult, ILFamilyTreeMemberIssue>) -> ILFamilyTreeMemberIssue? {
        if case .failure(let issue) = result { return issue }
        return nil
    }

    private func updated(_ result: Result<ILFamilyTreeMemberResult, ILFamilyTreeMemberIssue>) -> ILFamilyMemberEntity? {
        guard case .success(let value) = result else { return nil }
        return value.tree.members.first { $0.id == value.memberID }
    }

    // MARK: - makeDraft
    func test_makeDraft_mirrorsLivingMember() {
        var living = member("p13")
        living.residence = "Hà Nội"
        living.dharmaName = "Phúc Thiện"
        let draft = sut.makeDraft(from: living)
        XCTAssertEqual(draft.name, "Nguyễn Hữu Minh")
        XCTAssertEqual(draft.gender, .male)
        XCTAssertEqual(draft.birthYear, "1946")
        XCTAssertTrue(draft.isLiving)
        XCTAssertEqual(draft.residence, "Hà Nội")
        XCTAssertEqual(draft.dharmaName, "Phúc Thiện")
        XCTAssertEqual(draft.note, "Giữ nhà thờ tổ.")
        XCTAssertEqual(draft.deathYear, "")
    }

    func test_makeDraft_writesAnniversaryAsReadableText() {
        let draft = sut.makeDraft(from: member("p1"))
        XCTAssertFalse(draft.isLiving)
        XCTAssertEqual(draft.deathYear, "1879")
        XCTAssertEqual(ILFamilyLunarDateParser.parse(draft.anniversary), ILFamilyLunarDate(day: 15, month: 12))
    }

    // MARK: - updateMember
    func test_update_trimsAndKeepsIdentity() {
        var draft = livingDraft()
        draft.name = "  Nguyễn Hữu Trí  "
        draft.note = "  Giữ nhà thờ.  "
        let result = update(draft, id: "p13")
        let member = updated(result)
        XCTAssertEqual(member?.name, "Nguyễn Hữu Trí")
        XCTAssertEqual(member?.note, "Giữ nhà thờ.")
        XCTAssertEqual(member?.id, "p13")
        XCTAssertEqual(member?.parentID, "p8")
        XCTAssertEqual(member?.isClanHead, true)
        if case .success(let value) = result {
            XCTAssertEqual(value.tree.members.count, tree.members.count)
            XCTAssertEqual(value.tree.id, tree.id)
        }
    }

    func test_update_emptyOptionalFieldsBecomeNil() {
        var draft = livingDraft()
        draft.note = "   "
        draft.residence = ""
        draft.dharmaName = " "
        draft.tabletTemple = ""
        let member = updated(update(draft, id: "p13"))
        XCTAssertNil(member?.note)
        XCTAssertNil(member?.residence)
        XCTAssertNil(member?.dharmaName)
        XCTAssertNil(member?.tabletTemple)
    }

    func test_update_unknownMember_failsOnMember() {
        XCTAssertEqual(issue(update(livingDraft(), id: "nope"))?.field, .member)
    }

    func test_update_emptyName_failsOnName() {
        var draft = livingDraft()
        draft.name = "  "
        XCTAssertEqual(issue(update(draft, id: "p13"))?.field, .name)
    }

    func test_update_birthYearOutOfRange_failsOnBirthYear() {
        var draft = livingDraft()
        draft.birthYear = "1500"
        XCTAssertEqual(issue(update(draft, id: "p13"))?.field, .birthYear)
        draft.birthYear = "2027"
        XCTAssertEqual(issue(update(draft, id: "p13"))?.field, .birthYear)
    }

    func test_update_emptyBirthYear_isAllowed() {
        var draft = livingDraft()
        draft.birthYear = ""
        XCTAssertNil(updated(update(draft, id: "p13"))?.birthYear)
    }

    func test_update_deceasedWithoutDeathYear_failsOnDeathYear() {
        var draft = deceasedDraft()
        draft.deathYear = ""
        XCTAssertEqual(issue(update(draft, id: "p14"))?.field, .deathYear)
    }

    func test_update_deathBeforeBirthOrInFuture_failsOnDeathYear() {
        var draft = deceasedDraft()
        draft.deathYear = "1900"
        XCTAssertEqual(issue(update(draft, id: "p14"))?.field, .deathYear)
        draft.deathYear = "2027"
        XCTAssertEqual(issue(update(draft, id: "p14"))?.field, .deathYear)
    }

    func test_update_unreadableAnniversary_failsOnAnniversary() {
        var draft = deceasedDraft()
        draft.anniversary = "hôm nào đó"
        XCTAssertEqual(issue(update(draft, id: "p14"))?.field, .anniversary)
    }

    func test_update_readableAnniversary_isParsed() {
        var draft = deceasedDraft()
        draft.anniversary = "3/8"
        XCTAssertEqual(updated(update(draft, id: "p14"))?.anniversary, ILFamilyLunarDate(day: 3, month: 8))
    }

    func test_update_markingLiving_clearsDeathAnniversaryAndBurial() {
        var draft = sut.makeDraft(from: member("p1"))
        draft.isLiving = true
        draft.residence = "Nam Định"
        let member = updated(update(draft, id: "p1"))
        XCTAssertNil(member?.deathYear)
        XCTAssertNil(member?.anniversary)
        XCTAssertNil(member?.burialPlace)
        XCTAssertEqual(member?.residence, "Nam Định")
    }

    func test_update_markingDeceased_clearsResidenceAndKeepsBurial() {
        var draft = livingDraft()
        draft.isLiving = false
        draft.deathYear = "2020"
        draft.residence = "Hà Nội"
        draft.burialPlace = "Hành Thiện"
        let member = updated(update(draft, id: "p13"))
        XCTAssertEqual(member?.deathYear, 2020)
        XCTAssertNil(member?.residence)
        XCTAssertEqual(member?.burialPlace, "Hành Thiện")
    }

    func test_update_storesSpiritualFields() {
        var draft = livingDraft()
        draft.dharmaName = "Phúc Thiện"
        draft.tabletTemple = "Chùa Keo"
        let member = updated(update(draft, id: "p13"))
        XCTAssertEqual(member?.dharmaName, "Phúc Thiện")
        XCTAssertEqual(member?.tabletTemple, "Chùa Keo")
    }

    func test_save_doesNotThrow() async throws {
        try await sut.save(tree)
    }
}
