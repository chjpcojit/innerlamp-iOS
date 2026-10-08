//
//  ILFamilyTreeLayoutTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILFamilyTreeLayoutTests: XCTestCase {

    private typealias Metrics = ILMetrics.FamilyTree

    private let graph = ILFamilyTreeTestFactory.graph
    private lazy var layout = ILFamilyTreeLayout.make(graph: graph)

    func test_emptyGraph_givesEmptyLayout() {
        XCTAssertEqual(ILFamilyTreeLayout.make(graph: ILFamilyTreeGraph(members: [])), .empty)
    }

    func test_everyMember_hasACenterInsideTheCanvas() {
        for member in ILFamilyTreeTestFactory.members {
            guard let center = layout.centers[member.id] else {
                XCTFail("no center for \(member.id)")
                continue
            }
            XCTAssertTrue(CGRect(origin: .zero, size: layout.canvasSize).contains(center), "\(member.id) outside canvas")
        }
    }

    func test_founderIsOnTheBottomRow_newestGenerationOnTop() {
        let founderY = layout.centers["p1"]?.y ?? 0
        let youngestY = layout.centers["p18"]?.y ?? .infinity
        XCTAssertEqual(founderY, Metrics.canvasTopInset + 5 * Metrics.generationGap, accuracy: 0.01)
        XCTAssertEqual(youngestY, Metrics.canvasTopInset, accuracy: 0.01)
    }

    func test_children_sitAboveTheirParent() {
        for branch in layout.branches {
            XCTAssertLessThan(branch.to.y, branch.from.y, "child \(branch.childID) not above its parent")
        }
    }

    func test_oneBranchPerBloodChild() {
        let bloodChildren = ILFamilyTreeTestFactory.members.filter { $0.parentID != nil }.count
        XCTAssertEqual(layout.branches.count, bloodChildren)
    }

    func test_members_ofTheSameGeneration_neverOverlap() {
        var rows: [Int: [CGFloat]] = [:]
        for member in ILFamilyTreeTestFactory.members {
            guard let x = layout.centers[member.id]?.x else { continue }
            rows[graph.generation(of: member), default: []].append(x)
        }
        for (generation, xs) in rows {
            let sorted = xs.sorted()
            for (a, b) in zip(sorted, sorted.dropFirst()) {
                XCTAssertGreaterThanOrEqual(b - a, Metrics.nodeWidth, "generation \(generation) overlaps")
            }
        }
    }

    func test_parent_isCenteredOverItsChildren() {
        // p11 has two children (p16, p17): centred between them unless clamped by its own slot.
        guard let p16 = layout.centers["p16"], let p17 = layout.centers["p17"], let p11 = layout.centers["p11"] else {
            return XCTFail("missing centers")
        }
        XCTAssertEqual(p11.x, (p16.x + p17.x) / 2, accuracy: 0.01)
    }

    func test_spouse_sitsRightOfPartner_andIsLinked() {
        guard let partner = layout.centers["p13"], let spouse = layout.centers["s2"] else {
            return XCTFail("missing centers")
        }
        XCTAssertEqual(spouse.x - partner.x, Metrics.spouseOffsetX, accuracy: 0.01)
        XCTAssertEqual(spouse.y - partner.y, Metrics.spouseOffsetY, accuracy: 0.01)
        XCTAssertEqual(layout.spouseLinks.count, 2)
    }

    func test_smallTree_isStillAtLeastMinWidth() {
        let solo = ILFamilyTreeGraph(members: [ILFamilyTreeTestFactory.members[0]])
        let soloLayout = ILFamilyTreeLayout.make(graph: solo)
        XCTAssertGreaterThanOrEqual(soloLayout.canvasSize.width, Metrics.canvasMinWidth)
        XCTAssertEqual(soloLayout.centers["p1"]?.x ?? 0, soloLayout.canvasSize.width / 2, accuracy: 0.01)
    }

    func test_founderWithSpouse_staysInTheMiddleAndSpouseHangsRight() {
        let members = Array(ILFamilyTreeTestFactory.members.prefix(3)) // p1, s1 (spouse), p2 (child)
        let small = ILFamilyTreeLayout.make(graph: ILFamilyTreeGraph(members: members))
        XCTAssertEqual(small.centers["p1"]?.x ?? 0, small.canvasSize.width / 2, accuracy: 0.01)
        XCTAssertEqual(small.trunkTop.x, small.canvasSize.width / 2, accuracy: 0.01)
        XCTAssertGreaterThan(small.centers["s1"]?.x ?? 0, small.centers["p1"]?.x ?? .infinity)
    }

    func test_branchWidth_thinsOutWithGeneration_andClamps() {
        XCTAssertEqual(ILFamilyTreeLayout.branchWidth(generation: 2), Metrics.branchWidths.first)
        XCTAssertEqual(ILFamilyTreeLayout.branchWidth(generation: 99), Metrics.branchWidths.last)
        XCTAssertEqual(ILFamilyTreeLayout.branchWidth(generation: 7), 2.6)
        XCTAssertEqual(ILFamilyTreeLayout.branchWidth(generation: 8), 2.6)
        XCTAssertGreaterThan(ILFamilyTreeLayout.branchWidth(generation: 2), ILFamilyTreeLayout.branchWidth(generation: 4))
    }

    func test_leaves_existForBranchesAndTips() {
        // 4 per branch + 5 around each childless blood member.
        XCTAssertGreaterThanOrEqual(layout.leaves.count, layout.branches.count * 4)
    }
}
