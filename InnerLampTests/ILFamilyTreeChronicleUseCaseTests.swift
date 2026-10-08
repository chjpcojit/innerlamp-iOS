//
//  ILFamilyTreeChronicleUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILFamilyTreeChronicleUseCaseTests: XCTestCase {

    private let year = 2026
    private let tree = ILFamilyTreeTestFactory.tree
    private var sut: ILFamilyTreeChronicleUseCaseImpl!

    override func setUp() {
        super.setUp()
        sut = ILFamilyTreeChronicleUseCaseImpl()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    private var writtenTree: ILFamilyTreeEntity {
        var written = tree
        written.chronicle = ILFamilyChronicleEntity(
            origin: "Gốc ở Hành Thiện.",
            milestones: [ILFamilyMilestoneEntity(id: "a", year: 1812, text: "Lập ấp"), ILFamilyMilestoneEntity(id: "b", year: nil, text: "Dựng từ đường")],
            shrineName: "Nhà thờ tổ", shrineAddress: "Hành Thiện", annualGathering: "20 tháng Chạp",
            plaqueHan: "祖德流光", plaqueMeaning: "Tổ đức lưu quang", coupletUpper: "Trên", coupletLower: "Dưới", teachings: "Hiếu nghĩa"
        )
        return written
    }

    private func issue(_ result: Result<ILFamilyTreeEntity, ILFamilyTreeChronicleIssue>) -> ILFamilyTreeChronicleIssue? {
        if case .failure(let issue) = result { return issue }
        return nil
    }

    private func applied(_ result: Result<ILFamilyTreeEntity, ILFamilyTreeChronicleIssue>) -> ILFamilyTreeEntity? {
        guard case .success(let value) = result else { return nil }
        return value
    }

    // MARK: - makeDraft
    func test_makeDraft_mirrorsHometownAndChronicleAsText() {
        let draft = sut.makeDraft(from: writtenTree)
        XCTAssertEqual(draft.hometown, "Hành Thiện")
        XCTAssertEqual(draft.origin, "Gốc ở Hành Thiện.")
        XCTAssertEqual(draft.milestones.map(\.year), ["1812", ""])
        XCTAssertEqual(draft.milestones.map(\.id), ["a", "b"])
        XCTAssertEqual(draft.plaqueHan, "祖德流光")
        XCTAssertEqual(draft.coupletLower, "Dưới")
    }

    func test_makeDraft_ofEmptyChronicle_isBlank() {
        let draft = sut.makeDraft(from: tree)
        XCTAssertEqual(draft.origin, "")
        XCTAssertTrue(draft.milestones.isEmpty)
    }

    // MARK: - apply
    func test_apply_trimsTextAndWritesHometownAndChronicle() {
        var draft = sut.makeDraft(from: tree)
        draft.hometown = "  Giao Thủy "
        draft.origin = "  Thủy tổ lập nghiệp. \n"
        draft.shrineName = " Nhà thờ họ "
        let result = applied(sut.apply(draft, to: tree, currentYear: year))
        XCTAssertEqual(result?.hometown, "Giao Thủy")
        XCTAssertEqual(result?.chronicle.origin, "Thủy tổ lập nghiệp.")
        XCTAssertEqual(result?.chronicle.shrineName, "Nhà thờ họ")
        XCTAssertEqual(result?.members, tree.members)
        XCTAssertEqual(result?.id, tree.id)
    }

    func test_apply_dropsFullyEmptyMilestonesAndParsesYears() {
        var draft = sut.makeDraft(from: tree)
        draft.milestones = [
            .init(id: "1", year: "1900", text: " Dựng nhà thờ "),
            .init(id: "2", year: "", text: ""),
            .init(id: "3", year: "", text: "Không rõ năm")
        ]
        let milestones = applied(sut.apply(draft, to: tree, currentYear: year))?.chronicle.milestones
        XCTAssertEqual(milestones, [
            ILFamilyMilestoneEntity(id: "1", year: 1900, text: "Dựng nhà thờ"),
            ILFamilyMilestoneEntity(id: "3", year: nil, text: "Không rõ năm")
        ])
    }

    func test_apply_futureYear_failsOnThatMilestone() {
        var draft = sut.makeDraft(from: tree)
        draft.milestones = [.init(id: "x", year: "2027", text: "Tương lai")]
        XCTAssertEqual(issue(sut.apply(draft, to: tree, currentYear: year))?.field, .milestoneYear("x"))
    }

    func test_apply_nonNumericYear_fails() {
        var draft = sut.makeDraft(from: tree)
        draft.milestones = [.init(id: "x", year: "abc", text: "Sai")]
        XCTAssertEqual(issue(sut.apply(draft, to: tree, currentYear: year))?.field, .milestoneYear("x"))
    }

    func test_apply_blankDraft_clearsChronicle() {
        let result = applied(sut.apply(ILFamilyTreeChronicleDraft(), to: writtenTree, currentYear: year))
        XCTAssertEqual(result?.chronicle, .empty)
    }

    // MARK: - Clan head
    func test_clanHeadCandidates_areLivingBloodMenBelowFounder_oldestGenerationFirst() {
        let ids = sut.clanHeadCandidates(in: tree).map(\.id)
        XCTAssertEqual(ids, ["p13", "p21", "p20", "p22", "p18"])
    }

    func test_clanHeadCandidates_excludeWomenDeceasedFounderAndSpouses() {
        let ids = Set(sut.clanHeadCandidates(in: tree).map(\.id))
        XCTAssertTrue(ids.isDisjoint(with: ["p1", "s1", "s2", "p19", "p14"]))
    }

    func test_changeClanHead_movesTheFlagToTheNewHeadOnly() {
        let updated = sut.changeClanHead(to: "p18", in: tree)
        XCTAssertEqual(updated.members.filter(\.isClanHead).map(\.id), ["p18"])
        XCTAssertEqual(updated.members.count, tree.members.count)
    }

    func test_changeClanHead_unknownId_leavesTreeUnchanged() {
        XCTAssertEqual(sut.changeClanHead(to: "nope", in: tree), tree)
    }
}
