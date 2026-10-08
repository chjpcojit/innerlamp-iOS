//
//  ILFamilyTreeGraph.swift
//  InnerLamp
//

import Foundation

/// How a person is related to the one selected in the detail sheet.
enum ILFamilyRelationKind: Equatable {
    case father, mother, husband, wife
    case brother, sister
    case son, daughter
}

struct ILFamilyRelation: Equatable {
    let kind: ILFamilyRelationKind
    let member: ILFamilyMemberEntity
}

/// How a person is related to the viewer, derived from the tree alone (blood line and spouses).
enum ILFamilyKinship: Equatable {
    case me
    /// 1 = parent, 2 = grandparent, 3 = great-grandparent...
    case ancestor(generations: Int, gender: ILFamilyGender)
    /// 1 = child, 2 = grandchild...
    case descendant(generations: Int)
    /// `isOlder` is `nil` when birth years are missing or equal.
    case sibling(gender: ILFamilyGender, isOlder: Bool?)
    case spouse(gender: ILFamilyGender)
}

/// Which branch ("chi") of the clan a person belongs to.
enum ILFamilyBranch: Equatable {
    case founder
    /// Descends from the founder's first child.
    case eldest(ancestor: ILFamilyMemberEntity)
    /// Descends from any later child of the founder.
    case younger(ancestor: ILFamilyMemberEntity)
}

/// Read-only index over a flat member list: generations, children, spouses, lineage, relations and
/// search. Pure in-memory computation — no I/O — so it lives in Domain and is unit-tested directly.
struct ILFamilyTreeGraph {

    let members: [ILFamilyMemberEntity]
    private let byID: [String: ILFamilyMemberEntity]
    private let childrenByParent: [String: [ILFamilyMemberEntity]]
    private let spouseByPartner: [String: ILFamilyMemberEntity]

    init(members: [ILFamilyMemberEntity]) {
        self.members = members
        var byID: [String: ILFamilyMemberEntity] = [:]
        var children: [String: [ILFamilyMemberEntity]] = [:]
        var spouses: [String: ILFamilyMemberEntity] = [:]
        for member in members { byID[member.id] = member }
        for member in members {
            if let parentID = member.parentID, byID[parentID] != nil {
                children[parentID, default: []].append(member)
            }
            if let partnerID = member.spouseID, byID[partnerID] != nil {
                spouses[partnerID] = member
                spouses[member.id] = byID[partnerID]
            }
        }
        self.byID = byID
        self.childrenByParent = children
        self.spouseByPartner = spouses
    }

    // MARK: - Lookup
    func member(id: String) -> ILFamilyMemberEntity? { byID[id] }

    func children(of id: String) -> [ILFamilyMemberEntity] { childrenByParent[id] ?? [] }

    func spouse(of id: String) -> ILFamilyMemberEntity? { spouseByPartner[id] }

    func parent(of member: ILFamilyMemberEntity) -> ILFamilyMemberEntity? {
        member.parentID.flatMap { byID[$0] }
    }

    /// A member who married in: has a partner in the tree and no parents in the tree.
    func isMarriedIn(_ member: ILFamilyMemberEntity) -> Bool {
        guard let partnerID = member.spouseID else { return false }
        return byID[partnerID] != nil && parent(of: member) == nil
    }

    /// Blood-line members with no parent in the tree (the founder, or several if the data has gaps).
    var roots: [ILFamilyMemberEntity] {
        members.filter { parent(of: $0) == nil && !isMarriedIn($0) }
    }

    var founder: ILFamilyMemberEntity? { roots.first }

    // MARK: - Generations
    /// 1-based generation. A married-in spouse shares their partner's generation.
    func generation(of member: ILFamilyMemberEntity) -> Int {
        let core = isMarriedIn(member) ? (member.spouseID.flatMap { byID[$0] } ?? member) : member
        var depth = 1
        var current = core
        var visited: Set<String> = [core.id]
        while let up = parent(of: current), visited.insert(up.id).inserted {
            depth += 1
            current = up
        }
        return depth
    }

    var maxGeneration: Int {
        members.map { generation(of: $0) }.max() ?? 0
    }

    // MARK: - Lineage
    /// Founder → … → the person (or, for a married-in spouse, their partner, then the spouse).
    func lineage(of member: ILFamilyMemberEntity) -> [ILFamilyMemberEntity] {
        let core = isMarriedIn(member) ? (member.spouseID.flatMap { byID[$0] } ?? member) : member
        var chain: [ILFamilyMemberEntity] = []
        var current: ILFamilyMemberEntity? = core
        var visited: Set<String> = []
        while let node = current, visited.insert(node.id).inserted {
            chain.insert(node, at: 0)
            current = parent(of: node)
        }
        return core.id == member.id ? chain : chain + [member]
    }

    func branch(of member: ILFamilyMemberEntity) -> ILFamilyBranch {
        let chain = lineage(of: member)
        guard let first = chain.first, chain.count > 1 else { return .founder }
        // A founder's own spouse is the only married-in member whose chain is [founder, spouse].
        if chain.count == 2, isMarriedIn(member), first.id == member.spouseID { return .founder }
        let ancestor = chain[1]
        let eldest = children(of: first.id).first?.id == ancestor.id
        return eldest ? .eldest(ancestor: ancestor) : .younger(ancestor: ancestor)
    }

    // MARK: - Relations
    func relations(of member: ILFamilyMemberEntity) -> [ILFamilyRelation] {
        var result: [ILFamilyRelation] = []

        if isMarriedIn(member) {
            guard let partner = member.spouseID.flatMap({ byID[$0] }) else { return result }
            result.append(.init(kind: Self.spouseKind(of: partner), member: partner))
            result += children(of: partner.id).map { Self.childRelation($0) }
            return result
        }

        if let parent = parent(of: member) {
            result.append(.init(kind: Self.parentKind(of: parent), member: parent))
            if let other = spouse(of: parent.id) {
                result.append(.init(kind: Self.parentKind(of: other), member: other))
            }
        }
        if let partner = spouse(of: member.id) {
            result.append(.init(kind: Self.spouseKind(of: partner), member: partner))
        }
        if let parent = parent(of: member) {
            result += children(of: parent.id)
                .filter { $0.id != member.id }
                .map { .init(kind: $0.gender == .female ? .sister : .brother, member: $0) }
        }
        result += children(of: member.id).map { Self.childRelation($0) }
        return result
    }

    private static func parentKind(of member: ILFamilyMemberEntity) -> ILFamilyRelationKind {
        member.gender == .female ? .mother : .father
    }

    private static func spouseKind(of member: ILFamilyMemberEntity) -> ILFamilyRelationKind {
        member.gender == .female ? .wife : .husband
    }

    private static func childRelation(_ member: ILFamilyMemberEntity) -> ILFamilyRelation {
        .init(kind: member.gender == .female ? .daughter : .son, member: member)
    }

    // MARK: - Kinship
    /// How `targetID` is related to `viewerID`, or `nil` when it cannot be derived from direct
    /// ancestors, descendants, siblings or spouse (uncles, cousins... are not covered yet).
    func kinship(of targetID: String, relativeTo viewerID: String) -> ILFamilyKinship? {
        guard let viewer = byID[viewerID], let target = byID[targetID] else { return nil }
        if target.id == viewer.id { return .me }
        if viewer.spouseID == target.id || target.spouseID == viewer.id { return .spouse(gender: target.gender) }
        if isMarriedIn(viewer) { return nil }

        // A married-in spouse of one of the viewer's ancestors counts as that ancestor's generation.
        let anchorID = isMarriedIn(target) ? target.spouseID : target.id
        if let anchorID, let depth = ancestorDepth(of: anchorID, from: viewer) {
            return .ancestor(generations: depth, gender: target.gender)
        }
        if !isMarriedIn(target), let depth = ancestorDepth(of: viewer.id, from: target) {
            return .descendant(generations: depth)
        }
        if !isMarriedIn(target), let parentID = viewer.parentID, parentID == target.parentID {
            let isOlder: Bool? = {
                guard let mine = viewer.birthYear, let theirs = target.birthYear, mine != theirs else { return nil }
                return theirs < mine
            }()
            return .sibling(gender: target.gender, isOlder: isOlder)
        }
        return nil
    }

    /// Steps up from `member` to the ancestor `ancestorID`; `nil` when it is not an ancestor.
    private func ancestorDepth(of ancestorID: String, from member: ILFamilyMemberEntity) -> Int? {
        var depth = 0
        var current = member
        var visited: Set<String> = [member.id]
        while let up = parent(of: current), visited.insert(up.id).inserted {
            depth += 1
            if up.id == ancestorID { return depth }
            current = up
        }
        return nil
    }

    // MARK: - Search
    /// Ids whose name contains `query`, ignoring case and Vietnamese diacritics ("duc" finds "Đức").
    func search(_ query: String) -> [String] {
        let needle = Self.normalize(query)
        guard !needle.isEmpty else { return [] }
        return members.filter { Self.normalize($0.name).contains(needle) }.map(\.id)
    }

    static func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi"))
            .replacingOccurrences(of: "đ", with: "d")
    }
}
