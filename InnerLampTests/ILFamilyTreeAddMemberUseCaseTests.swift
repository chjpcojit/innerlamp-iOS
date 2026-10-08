//
//  ILFamilyTreeAddMemberUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILFamilyTreeAddMemberUseCaseTests: XCTestCase {

    private let year = 2026
    private let tree = ILFamilyTreeTestFactory.tree
    private var sut: ILFamilyTreeAddMemberUseCaseImpl!

    override func setUp() {
        super.setUp()
        sut = ILFamilyTreeAddMemberUseCaseImpl(makeID: { "new" })
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    private func draft(
        relation: ILFamilyAddRelation = .child, relative: String = "p18", gender: ILFamilyGender = .male
    ) -> ILFamilyTreeAddMemberDraft {
        ILFamilyTreeAddMemberDraft(
            relation: relation, relativeID: relative, name: " Nguyễn Hữu Bảo ", gender: gender,
            birthYear: "1998", isLiving: true, residence: "Hà Nội"
        )
    }

    private func issue(_ result: Result<ILFamilyTreeAddMemberResult, ILFamilyTreeAddMemberIssue>) -> ILFamilyTreeAddMemberIssue? {
        if case .failure(let issue) = result { return issue }
        return nil
    }

    private func added(_ result: Result<ILFamilyTreeAddMemberResult, ILFamilyTreeAddMemberIssue>) -> ILFamilyMemberEntity? {
        guard case .success(let value) = result else { return nil }
        return value.tree.members.first { $0.id == value.memberID }
    }

    // MARK: - Child
    func test_child_attachesToRelativeWithTrimmedName() {
        let result = sut.addMember(draft(), to: tree, currentYear: year)
        let member = added(result)
        XCTAssertEqual(member?.parentID, "p18")
        XCTAssertEqual(member?.name, "Nguyễn Hữu Bảo")
        XCTAssertEqual(member?.residence, "Hà Nội")
        XCTAssertNil(member?.spouseID)
        if case .success(let value) = result { XCTAssertEqual(value.tree.members.count, tree.members.count + 1) }
    }

    func test_childOfMarriedInPerson_attachesToPartner() {
        // s2 married into p13.
        let member = added(sut.addMember(draft(relative: "s2"), to: tree, currentYear: year))
        XCTAssertEqual(member?.parentID, "p13")
    }

    func test_child_pastSeventhGeneration_fails() {
        // p18 is generation 6 here, so a child is generation 7 (allowed); a grandchild is not.
        var big = tree
        let seventh = added(sut.addMember(draft(), to: big, currentYear: year))!
        big = ILFamilyTreeEntity(clanName: tree.clanName, hometown: tree.hometown, members: tree.members + [seventh])
        let result = sut.addMember(draft(relative: seventh.id), to: big, currentYear: year)
        XCTAssertEqual(issue(result)?.field, .relation)
    }

    // MARK: - Spouse
    func test_spouse_takesOppositeGenderAndPointsAtRelative() {
        let member = added(sut.addMember(draft(relation: .spouse, relative: "p18", gender: .male), to: tree, currentYear: year))
        XCTAssertEqual(member?.gender, .female)
        XCTAssertEqual(member?.spouseID, "p18")
        XCTAssertNil(member?.parentID)
    }

    func test_spouse_ofMarriedInPerson_fails() {
        XCTAssertEqual(issue(sut.addMember(draft(relation: .spouse, relative: "s2"), to: tree, currentYear: year))?.field, .relation)
    }

    func test_spouse_ofPersonWhoAlreadyHasOne_fails() {
        XCTAssertEqual(issue(sut.addMember(draft(relation: .spouse, relative: "p13"), to: tree, currentYear: year))?.field, .relation)
    }

    func test_unknownRelative_fails() {
        XCTAssertEqual(issue(sut.addMember(draft(relative: "zzz"), to: tree, currentYear: year))?.field, .relation)
    }

    // MARK: - Fields
    func test_emptyName_failsOnName() {
        var d = draft(); d.name = "  "
        XCTAssertEqual(issue(sut.addMember(d, to: tree, currentYear: year))?.field, .name)
    }

    func test_birthYear_requiredAndBounded() {
        for text in ["", "1699", "2027", "abc"] {
            var d = draft(); d.birthYear = text
            XCTAssertEqual(issue(sut.addMember(d, to: tree, currentYear: year))?.field, .birthYear, text)
        }
    }

    func test_living_requiresResidence() {
        var d = draft(); d.residence = " "
        XCTAssertEqual(issue(sut.addMember(d, to: tree, currentYear: year))?.field, .residence)
    }

    func test_deceased_requiresDeathYearNotBeforeBirth() {
        var d = draft(); d.isLiving = false; d.residence = ""
        d.deathYear = "1990"
        XCTAssertEqual(issue(sut.addMember(d, to: tree, currentYear: year))?.field, .deathYear)
        d.deathYear = ""
        XCTAssertEqual(issue(sut.addMember(d, to: tree, currentYear: year))?.field, .deathYear)
    }

    func test_deceased_parsesAnniversaryAndKeepsBurialPlace() {
        var d = draft(); d.isLiving = false; d.residence = ""
        d.deathYear = "2015"; d.anniversary = "15 tháng Chạp"; d.burialPlace = "Hành Thiện"
        let member = added(sut.addMember(d, to: tree, currentYear: year))
        XCTAssertEqual(member?.deathYear, 2015)
        XCTAssertEqual(member?.anniversary, ILFamilyLunarDate(day: 15, month: 12))
        XCTAssertEqual(member?.burialPlace, "Hành Thiện")
        XCTAssertNil(member?.residence)
    }

    func test_deceased_invalidAnniversary_fails() {
        var d = draft(); d.isLiving = false; d.deathYear = "2015"; d.anniversary = "someday"
        XCTAssertEqual(issue(sut.addMember(d, to: tree, currentYear: year))?.field, .anniversary)
    }
}
