//
//  ILFamilyTreePedigreeTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILFamilyTreePedigreeTests: XCTestCase {

    private typealias Factory = ILFamilyTreeTestFactory

    /// A maternal book in which "Trần Thị Hạnh" (mother `s2` of viewer `p18`) was born.
    private func makeMaternal(motherName: String = "Trần Thị Hạnh") -> ILFamilyTreeEntity {
        ILFamilyTreeEntity(
            clanName: "Họ Trần", hometown: "Giao Thủy",
            members: [
                ILFamilyMemberEntity(
                    id: "t1", name: "Trần Văn Bảo", gender: .male, birthYear: 1920, deathYear: 1990,
                    anniversary: nil, note: nil, parentID: nil, spouseID: nil, isClanHead: false
                ),
                ILFamilyMemberEntity(
                    id: "t2", name: motherName, gender: .female, birthYear: 1950, deathYear: nil,
                    anniversary: nil, note: nil, parentID: "t1", spouseID: nil, isClanHead: false
                )
            ],
            side: .maternal
        )
    }

    func test_build_viewerNotInPaternalBook_returnsNil() {
        XCTAssertNil(ILFamilyTreePedigree.build(viewerID: "nobody", paternal: Factory.tree, maternal: nil))
    }

    func test_build_viewerIsTheRootWithNoParent() {
        let pedigree = ILFamilyTreePedigree.build(viewerID: "p18", paternal: Factory.tree, maternal: nil)

        XCTAssertEqual(pedigree?.viewerID, "n:p18")
        XCTAssertEqual(pedigree?.tree.members.first?.id, "n:p18")
        XCTAssertNil(pedigree?.tree.members.first?.parentID)
        XCTAssertEqual(pedigree?.origins["n:p18"]?.depth, 0)
        XCTAssertNil(pedigree?.origins["n:p18"]?.side)
    }

    func test_build_fatherLineFollowsParentsUpTheBook() {
        let pedigree = ILFamilyTreePedigree.build(viewerID: "p18", paternal: Factory.tree, maternal: nil)
        let graph = pedigree.map { ILFamilyTreeGraph(members: $0.tree.members) }

        // p18 → p13 → p8 → p4 → p2 → p1 (founder): six generations in the merged tree.
        XCTAssertEqual(graph?.generation(of: graph!.member(id: "n:p1")!), 6)
        XCTAssertEqual(pedigree?.origins["n:p13"]?.depth, 1)
        XCTAssertEqual(pedigree?.origins["n:p13"]?.side, .paternal)
        XCTAssertEqual(pedigree?.origins["n:p1"]?.memberID, "p1")
    }

    func test_build_motherWithoutMaternalBook_isALeaf() {
        let pedigree = ILFamilyTreePedigree.build(viewerID: "p18", paternal: Factory.tree, maternal: nil)

        // s2 stays the paternal book's spouse record, with no ancestors.
        XCTAssertEqual(pedigree?.origins["n:s2"]?.side, .maternal)
        XCTAssertNil(pedigree?.tree.members.first(where: { $0.parentID == "n:s2" }))
    }

    func test_build_motherMatchedByNameContinuesInTheMaternalBook() {
        let maternal = makeMaternal()

        let pedigree = ILFamilyTreePedigree.build(viewerID: "p18", paternal: Factory.tree, maternal: maternal)

        XCTAssertEqual(pedigree?.origins["g:t2"]?.treeID, maternal.id)
        XCTAssertEqual(pedigree?.origins["g:t2"]?.side, .maternal)
        XCTAssertEqual(pedigree?.origins["g:t1"]?.depth, 2)
        XCTAssertEqual(pedigree?.origins["g:t1"]?.side, .maternal)
        // The paternal spouse record of the mother is replaced by her own record.
        XCTAssertNil(pedigree?.origins["n:s2"])
    }

    func test_build_motherMatchIgnoresDiacriticsAndCase() {
        let maternal = makeMaternal(motherName: "TRAN THI HANH")

        let pedigree = ILFamilyTreePedigree.build(viewerID: "p18", paternal: Factory.tree, maternal: maternal)

        XCTAssertNotNil(pedigree?.origins["g:t2"])
    }

    func test_build_noMatchingWomanInTheMaternalBook_keepsThePaternalSpouse() {
        let maternal = makeMaternal(motherName: "Phạm Thị Lụa")

        let pedigree = ILFamilyTreePedigree.build(viewerID: "p18", paternal: Factory.tree, maternal: maternal)

        XCTAssertNotNil(pedigree?.origins["n:s2"])
        XCTAssertNil(pedigree?.origins["g:t2"])
    }

    func test_build_clearsClanHeadAndSpouseLinksSoTheMergedTreeHasNoCrownsOrPairs() {
        let pedigree = ILFamilyTreePedigree.build(viewerID: "p18", paternal: Factory.tree, maternal: makeMaternal())

        XCTAssertEqual(pedigree?.tree.members.contains(where: \.isClanHead), false)
        XCTAssertEqual(pedigree?.tree.members.contains(where: { $0.spouseID != nil }), false)
    }

    func test_build_idsAreTaggedSoTwoBooksMayReuseAnId() {
        let maternal = makeMaternal()
        // Same ids on both sides: "p1" exists in the paternal sample clan.
        var clash = maternal
        clash.members = clash.members.map { member in
            ILFamilyMemberEntity(
                id: member.id == "t1" ? "p1" : (member.id == "t2" ? "p2" : member.id), name: member.name,
                gender: member.gender, birthYear: member.birthYear, deathYear: member.deathYear,
                anniversary: nil, note: nil, parentID: member.parentID == "t1" ? "p1" : nil,
                spouseID: nil, isClanHead: false
            )
        }

        let pedigree = ILFamilyTreePedigree.build(viewerID: "p18", paternal: Factory.tree, maternal: clash)
        let ids = pedigree?.tree.members.map(\.id) ?? []

        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertNotNil(pedigree?.origins["n:p1"])
        XCTAssertNotNil(pedigree?.origins["g:p1"])
    }
}
