//
//  ILFamilyTreeLayout.swift
//  InnerLamp
//

import Foundation
import CoreGraphics

/// Pure geometry for the tree canvas, in points at zoom 1.0: where each person sits, the branch
/// curves between parents and children, spouse links and decorative leaves. Generation 1 is at the
/// bottom (the founder grows from the trunk) and the newest generation is at the top.
///
/// Placement: every subtree gets a box as wide as its children (or as the person itself, whichever
/// is wider); a parent is centred over its children, so siblings never overlap.
struct ILFamilyTreeLayout: Equatable {

    struct Branch: Equatable {
        let childID: String
        let from: CGPoint
        let to: CGPoint
        let generation: Int
    }

    struct SpouseLink: Equatable {
        let from: CGPoint
        let to: CGPoint
    }

    struct Leaf: Equatable {
        let center: CGPoint
        let radiusX: CGFloat
        let radiusY: CGFloat
        /// Radians.
        let rotation: CGFloat
        /// 0…4 — index into the leaf palette.
        let tone: Int
        let alpha: CGFloat
    }

    let canvasSize: CGSize
    let centers: [String: CGPoint]
    let branches: [Branch]
    let spouseLinks: [SpouseLink]
    let leaves: [Leaf]
    /// Where the trunk meets the founder.
    let trunkTop: CGPoint

    static let empty = ILFamilyTreeLayout(
        canvasSize: .zero, centers: [:], branches: [], spouseLinks: [], leaves: [], trunkTop: .zero
    )

    // MARK: - Build
    static func make(graph: ILFamilyTreeGraph) -> ILFamilyTreeLayout {
        guard !graph.members.isEmpty else { return .empty }
        var builder = Builder(graph: graph)
        return builder.build()
    }

    private typealias Metrics = ILMetrics.FamilyTree

    private struct Builder {
        let graph: ILFamilyTreeGraph
        let generations: Int
        var centers: [String: CGPoint] = [:]
        var widthCache: [String: CGFloat] = [:]

        init(graph: ILFamilyTreeGraph) {
            self.graph = graph
            self.generations = max(graph.maxGeneration, 1)
        }

        mutating func build() -> ILFamilyTreeLayout {
            let roots = graph.roots
            let totalWidth = roots.reduce(CGFloat(0)) { $0 + subtreeWidth(of: $1) }
            var canvasWidth = max(Metrics.canvasMinWidth, totalWidth + Metrics.canvasSideInset * 2)
            var originX = (canvasWidth - totalWidth) / 2
            for root in roots {
                place(root, originX: originX)
                originX += subtreeWidth(of: root)
            }

            // The founder (the trunk) belongs in the middle of the canvas; a spouse hangs to the right.
            // Slide the whole tree there, widening the canvas if that pushes anyone past an edge.
            if let founderX = graph.founder.flatMap({ centers[$0.id]?.x }) {
                var shift = canvasWidth / 2 - founderX
                let half = Metrics.slotWidth / 2 + Metrics.canvasSideInset
                let xs = centers.values.map(\.x)
                if let low = xs.min(), let high = xs.max() {
                    let overflow = max(half - (low + shift), (high + shift + half) - canvasWidth, 0)
                    canvasWidth += overflow * 2
                    shift += overflow
                }
                centers = centers.mapValues { CGPoint(x: $0.x + shift, y: $0.y) }
            }

            let height = Metrics.canvasTopInset + CGFloat(generations - 1) * Metrics.generationGap + Metrics.canvasBottomInset
            let branches = makeBranches()
            let founderCenter = graph.founder.flatMap { centers[$0.id] } ?? .zero
            return ILFamilyTreeLayout(
                canvasSize: CGSize(width: canvasWidth, height: height),
                centers: centers,
                branches: branches,
                spouseLinks: makeSpouseLinks(),
                leaves: makeLeaves(branches: branches),
                trunkTop: founderCenter
            )
        }

        private func rowY(generation: Int) -> CGFloat {
            Metrics.canvasTopInset + CGFloat(generations - generation) * Metrics.generationGap
        }

        private func ownWidth(of member: ILFamilyMemberEntity) -> CGFloat {
            graph.spouse(of: member.id) == nil ? Metrics.slotWidth : Metrics.slotWidth + Metrics.spouseOffsetX
        }

        private mutating func subtreeWidth(of member: ILFamilyMemberEntity, visited: Set<String> = []) -> CGFloat {
            if let cached = widthCache[member.id] { return cached }
            var seen = visited
            guard seen.insert(member.id).inserted else { return 0 }
            let childrenWidth = graph.children(of: member.id).reduce(CGFloat(0)) { $0 + subtreeWidth(of: $1, visited: seen) }
            let width = max(ownWidth(of: member), childrenWidth)
            widthCache[member.id] = width
            return width
        }

        private mutating func place(_ member: ILFamilyMemberEntity, originX: CGFloat) {
            guard centers[member.id] == nil else { return }
            let width = subtreeWidth(of: member)
            let children = graph.children(of: member.id)
            let spouse = graph.spouse(of: member.id)
            let spouseExtra = spouse == nil ? 0 : Metrics.spouseOffsetX

            var x = originX + Metrics.slotWidth / 2
            if !children.isEmpty {
                let childrenWidth = children.reduce(CGFloat(0)) { $0 + subtreeWidth(of: $1) }
                var childX = originX + (width - childrenWidth) / 2
                for child in children {
                    place(child, originX: childX)
                    childX += subtreeWidth(of: child)
                }
                let placed = children.compactMap { centers[$0.id]?.x }
                if let first = placed.first, let last = placed.last {
                    let lower = originX + Metrics.slotWidth / 2
                    let upper = originX + width - Metrics.slotWidth / 2 - spouseExtra
                    x = min(max((first + last) / 2, lower), max(lower, upper))
                }
            }

            let y = rowY(generation: graph.generation(of: member))
            centers[member.id] = CGPoint(x: x, y: y)
            if let spouse {
                centers[spouse.id] = CGPoint(x: x + Metrics.spouseOffsetX, y: y + Metrics.spouseOffsetY)
            }
        }

        // MARK: Decorations
        private func makeBranches() -> [Branch] {
            graph.members.compactMap { member in
                guard let parent = graph.parent(of: member),
                      let from = centers[parent.id], let to = centers[member.id] else { return nil }
                return Branch(childID: member.id, from: from, to: to, generation: graph.generation(of: member))
            }
        }

        private func makeSpouseLinks() -> [SpouseLink] {
            graph.members.compactMap { member in
                guard graph.isMarriedIn(member),
                      let partnerID = member.spouseID,
                      let from = centers[partnerID], let to = centers[member.id] else { return nil }
                return SpouseLink(from: from, to: to)
            }
        }

        private func makeLeaves(branches: [Branch]) -> [Leaf] {
            var leaves: [Leaf] = []
            func add(_ x: CGFloat, _ y: CGFloat, rotation: CGFloat, scale: CGFloat) {
                let index = leaves.count
                leaves.append(Leaf(
                    center: CGPoint(x: x, y: y),
                    radiusX: Metrics.leafRadiusX * scale,
                    radiusY: Metrics.leafRadiusY * scale,
                    rotation: rotation,
                    tone: index % 5,
                    alpha: 0.55 + CGFloat(index % 4) * 0.1
                ))
            }

            // Along each branch.
            for (branchIndex, branch) in branches.enumerated() {
                let curve = Self.curve(for: branch)
                let width = ILFamilyTreeLayout.branchWidth(generation: branch.generation)
                for (step, t) in [0.3, 0.48, 0.64, 0.8].enumerated() {
                    let point = curve.point(at: CGFloat(t))
                    let tangent = curve.tangent(at: CGFloat(t))
                    let length = hypot(tangent.x, tangent.y)
                    let normal = length == 0 ? CGPoint(x: 0, y: 1) : CGPoint(x: -tangent.y / length, y: tangent.x / length)
                    let side: CGFloat = (step + branchIndex) % 2 == 1 ? 1 : -1
                    let offset = width / 2 + 7
                    add(
                        point.x + normal.x * offset * side,
                        point.y + normal.y * offset * side,
                        rotation: atan2(tangent.y, tangent.x) + side * 38 * .pi / 180,
                        scale: 0.9 + CGFloat(branch.generation) / 10
                    )
                }
            }

            // Crown of leaves around each blood-line member with no children.
            let tips = graph.members.filter { graph.children(of: $0.id).isEmpty && !graph.isMarriedIn($0) }
            for (i, member) in tips.enumerated() {
                guard let center = centers[member.id] else { continue }
                for (j, degrees) in [-150.0, -115, -70, -30, 20].enumerated() {
                    let radius = 44 + CGFloat(j % 2) * 8
                    let angle = CGFloat(degrees) * .pi / 180
                    let tilt: CGFloat = (i + j) % 2 == 1 ? 25 : -25
                    add(
                        center.x + cos(angle) * radius,
                        center.y + sin(angle) * radius,
                        rotation: angle + (90 + tilt) * .pi / 180,
                        scale: 1.25
                    )
                }
            }
            return leaves
        }

        private static func curve(for branch: Branch) -> Bezier {
            ILFamilyTreeLayout.curve(from: branch.from, to: branch.to)
        }
    }

    // MARK: - Curves
    /// Cubic Bézier from a parent up to a child — shared by the leaf placement and the canvas drawing.
    struct Bezier: Equatable {
        let p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint

        func point(at t: CGFloat) -> CGPoint {
            let u = 1 - t
            return CGPoint(
                x: u * u * u * p0.x + 3 * u * u * t * p1.x + 3 * u * t * t * p2.x + t * t * t * p3.x,
                y: u * u * u * p0.y + 3 * u * u * t * p1.y + 3 * u * t * t * p2.y + t * t * t * p3.y
            )
        }

        func tangent(at t: CGFloat) -> CGPoint {
            let u = 1 - t
            return CGPoint(
                x: 3 * u * u * (p1.x - p0.x) + 6 * u * t * (p2.x - p1.x) + 3 * t * t * (p3.x - p2.x),
                y: 3 * u * u * (p1.y - p0.y) + 6 * u * t * (p2.y - p1.y) + 3 * t * t * (p3.y - p2.y)
            )
        }
    }

    static func curve(from: CGPoint, to: CGPoint) -> Bezier {
        let dy = from.y - to.y
        return Bezier(
            p0: from,
            p1: CGPoint(x: from.x, y: from.y - dy * 0.55),
            p2: CGPoint(x: to.x, y: to.y + dy * 0.55),
            p3: to
        )
    }

    /// Stroke width of the branch that leads into a member of `generation` (thicker near the root).
    static func branchWidth(generation: Int) -> CGFloat {
        let widths = Metrics.branchWidths
        return widths[min(max(generation - 2, 0), widths.count - 1)]
    }
}
