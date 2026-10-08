//
//  ILFamilyTreeGraphTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILFamilyTreeGraphTests: XCTestCase {

    private let graph = ILFamilyTreeTestFactory.graph

    private func member(_ id: String) -> ILFamilyMemberEntity {
        guard let member = graph.member(id: id) else {
            XCTFail("missing member \(id)")
            return ILFamilyTreeTestFactory.members[0]
        }
        return member
    }

    func test_roots_andFounder_areTheBloodLineRoot() {
        XCTAssertEqual(graph.roots.map(\.id), ["p1"])
        XCTAssertEqual(graph.founder?.id, "p1")
    }

    func test_generation_countsUpFromFounder_andSpouseSharesPartnersGeneration() {
        XCTAssertEqual(graph.generation(of: member("p1")), 1)
        XCTAssertEqual(graph.generation(of: member("s1")), 1)
        XCTAssertEqual(graph.generation(of: member("p13")), 5)
        XCTAssertEqual(graph.generation(of: member("s2")), 5)
        XCTAssertEqual(graph.generation(of: member("p18")), 6)
        XCTAssertEqual(graph.maxGeneration, 6)
    }

    func test_isMarriedIn_onlyForSpouseEntries() {
        XCTAssertTrue(graph.isMarriedIn(member("s1")))
        XCTAssertFalse(graph.isMarriedIn(member("p1")))
        XCTAssertFalse(graph.isMarriedIn(member("p13")))
    }

    func test_spouse_isSymmetric() {
        XCTAssertEqual(graph.spouse(of: "p13")?.id, "s2")
        XCTAssertEqual(graph.spouse(of: "s2")?.id, "p13")
        XCTAssertNil(graph.spouse(of: "p2"))
    }

    func test_lineage_runsFromFounderToPerson() {
        XCTAssertEqual(graph.lineage(of: member("p13")).map(\.id), ["p1", "p2", "p4", "p8", "p13"])
    }

    func test_lineage_ofMarriedInSpouse_endsWithThePartnerThenTheSpouse() {
        XCTAssertEqual(graph.lineage(of: member("s2")).map(\.id), ["p1", "p2", "p4", "p8", "p13", "s2"])
    }

    func test_branch_founderAndSpouse_isFounder() {
        XCTAssertEqual(graph.branch(of: member("p1")), .founder)
        XCTAssertEqual(graph.branch(of: member("s1")), .founder)
    }

    func test_branch_firstChildLine_isEldest_laterChildLine_isYounger() {
        XCTAssertEqual(graph.branch(of: member("p13")), .eldest(ancestor: member("p2")))
        XCTAssertEqual(graph.branch(of: member("s2")), .eldest(ancestor: member("p2")))
        XCTAssertEqual(graph.branch(of: member("p6")), .younger(ancestor: member("p3")))
    }

    func test_relations_ofBloodMember_listParentSpouseSiblingsAndChildren() {
        let relations = graph.relations(of: member("p13"))
        XCTAssertEqual(relations.map(\.kind), [.father, .wife, .son, .daughter])
        XCTAssertEqual(relations.map(\.member.id), ["p8", "s2", "p18", "p19"])
    }

    func test_relations_includeSiblingsAndMotherWhenPresent() {
        // p6 and p7 are siblings (children of p3); p7 is a daughter.
        let relations = graph.relations(of: member("p6"))
        XCTAssertTrue(relations.contains(.init(kind: .father, member: member("p3"))))
        XCTAssertTrue(relations.contains(.init(kind: .sister, member: member("p7"))))
        XCTAssertTrue(relations.contains(.init(kind: .son, member: member("p11"))))

        // p2 has a mother (s1 is the founder's spouse): p2's relations show her.
        let ofP2 = graph.relations(of: member("p2"))
        XCTAssertTrue(ofP2.contains(.init(kind: .father, member: member("p1"))))
        XCTAssertTrue(ofP2.contains(.init(kind: .mother, member: member("s1"))))
        XCTAssertTrue(ofP2.contains(.init(kind: .brother, member: member("p3"))))
    }

    func test_relations_ofMarriedInSpouse_listHusbandAndHerChildren() {
        let relations = graph.relations(of: member("s2"))
        XCTAssertEqual(relations.map(\.kind), [.husband, .son, .daughter])
        XCTAssertEqual(relations.map(\.member.id), ["p13", "p18", "p19"])
    }

    func test_search_ignoresDiacriticsAndCase() {
        XCTAssertEqual(graph.search("duc"), ["p5"])
        XCTAssertEqual(graph.search("ĐỨC"), ["p5"])
        XCTAssertEqual(graph.search("  minh "), ["p13"])
    }

    func test_search_emptyQuery_findsNothing() {
        XCTAssertEqual(graph.search(""), [])
        XCTAssertEqual(graph.search("   "), [])
    }

    func test_cyclicParentData_doesNotHang() {
        let a = ILFamilyMemberEntity(id: "a", name: "A", gender: .male, birthYear: nil, deathYear: nil,
                                     anniversary: nil, note: nil, parentID: "b", spouseID: nil, isClanHead: false)
        let b = ILFamilyMemberEntity(id: "b", name: "B", gender: .male, birthYear: nil, deathYear: nil,
                                     anniversary: nil, note: nil, parentID: "a", spouseID: nil, isClanHead: false)
        let cyclic = ILFamilyTreeGraph(members: [a, b])
        XCTAssertGreaterThanOrEqual(cyclic.generation(of: a), 1)
        XCTAssertEqual(cyclic.lineage(of: a).count, 2)
    }

    // MARK: - Kinship
    func test_kinship_ancestors_followGenerationDepthAndGender() {
        XCTAssertEqual(graph.kinship(of: "p13", relativeTo: "p18"), .ancestor(generations: 1, gender: .male))
        XCTAssertEqual(graph.kinship(of: "p8", relativeTo: "p18"), .ancestor(generations: 2, gender: .male))
        XCTAssertEqual(graph.kinship(of: "p1", relativeTo: "p18"), .ancestor(generations: 5, gender: .male))
    }

    func test_kinship_marriedInSpouseOfAnAncestor_takesTheAncestorGeneration() {
        XCTAssertEqual(graph.kinship(of: "s2", relativeTo: "p18"), .ancestor(generations: 1, gender: .female))
    }

    func test_kinship_descendantsSiblingsSpouseAndSelf() {
        XCTAssertEqual(graph.kinship(of: "p18", relativeTo: "p13"), .descendant(generations: 1))
        XCTAssertEqual(graph.kinship(of: "p18", relativeTo: "p8"), .descendant(generations: 2))
        XCTAssertEqual(graph.kinship(of: "p19", relativeTo: "p18"), .sibling(gender: .female, isOlder: false))
        XCTAssertEqual(graph.kinship(of: "p18", relativeTo: "p19"), .sibling(gender: .male, isOlder: true))
        XCTAssertEqual(graph.kinship(of: "s2", relativeTo: "p13"), .spouse(gender: .female))
        XCTAssertEqual(graph.kinship(of: "p13", relativeTo: "p13"), .me)
    }

    func test_kinship_unrelatedByDirectLine_isNil() {
        XCTAssertNil(graph.kinship(of: "p14", relativeTo: "p18"))
        XCTAssertNil(graph.kinship(of: "nobody", relativeTo: "p18"))
        XCTAssertNil(graph.kinship(of: "p18", relativeTo: "nobody"))
    }
}
