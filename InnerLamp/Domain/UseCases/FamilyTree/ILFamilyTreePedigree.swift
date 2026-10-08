//
//  ILFamilyTreePedigree.swift
//  InnerLamp
//

import Foundation

/// The "Nội – ngoại của bạn" view: the viewer's ancestors on both sides, joined into one tree.
///
/// It is built as an ordinary `ILFamilyTreeEntity` turned upside down — the viewer is the root
/// ("founder") and each person's father and mother are that person's two "children" — so the
/// existing graph, layout and canvas draw it without any special case. Ids are rewritten
/// (`"<tag>:<id>"`) because two books may reuse an id; `origins` maps them back.
///
/// The father's line comes from the paternal book. The viewer's mother is a married-in spouse
/// there, so her own family is looked up in the maternal book by name (same normalised name,
/// female, born into the book) — see AS-FamilyTree-010.
struct ILFamilyTreePedigree: Equatable {

    struct Origin: Equatable {
        let treeID: String
        let memberID: String
        /// `nil` for the viewer.
        let side: ILFamilyTreeSide?
        /// 0 = the viewer, 1 = parents, 2 = grandparents...
        let depth: Int
    }

    /// The synthetic tree (never persisted). `members.first` is the viewer.
    let tree: ILFamilyTreeEntity
    let viewerID: String
    let origins: [String: Origin]

    /// Deepest ancestor row drawn, matching the prototype's cap.
    static let maxDepth = 8

    // MARK: - Build
    /// `nil` when the viewer is not a member of `paternal`.
    static func build(
        viewerID: String,
        paternal: ILFamilyTreeEntity,
        maternal: ILFamilyTreeEntity?
    ) -> ILFamilyTreePedigree? {
        var builder = Builder(
            paternal: (paternal, ILFamilyTreeGraph(members: paternal.members)),
            maternal: maternal.map { ($0, ILFamilyTreeGraph(members: $0.members)) }
        )
        return builder.build(viewerID: viewerID)
    }

    private struct Book {
        let tree: ILFamilyTreeEntity
        let graph: ILFamilyTreeGraph
        let tag: String

        init(_ pair: (ILFamilyTreeEntity, ILFamilyTreeGraph), tag: String) {
            self.tree = pair.0
            self.graph = pair.1
            self.tag = tag
        }
    }

    private struct Builder {
        let paternal: Book
        let maternal: Book?
        var members: [ILFamilyMemberEntity] = []
        var origins: [String: Origin] = [:]

        init(paternal: (ILFamilyTreeEntity, ILFamilyTreeGraph), maternal: (ILFamilyTreeEntity, ILFamilyTreeGraph)?) {
            self.paternal = Book(paternal, tag: "n")
            self.maternal = maternal.map { Book($0, tag: "g") }
        }

        mutating func build(viewerID: String) -> ILFamilyTreePedigree? {
            guard let me = paternal.graph.member(id: viewerID) else { return nil }
            let rootID = add(me, from: paternal, parent: nil, side: nil, depth: 0)
            walk(me, in: paternal, syntheticID: rootID, side: nil, depth: 0)
            let tree = ILFamilyTreeEntity(
                clanName: "", hometown: "", members: members, id: "pedigree", side: .paternal
            )
            return ILFamilyTreePedigree(tree: tree, viewerID: rootID, origins: origins)
        }

        /// Adds `member`'s father and mother under `syntheticID`, then climbs further.
        private mutating func walk(
            _ member: ILFamilyMemberEntity, in book: Book, syntheticID: String, side: ILFamilyTreeSide?, depth: Int
        ) {
            guard depth < ILFamilyTreePedigree.maxDepth,
                  let father = book.graph.parent(of: member) else { return }
            let fatherSide = side ?? .paternal
            let fatherID = add(father, from: book, parent: syntheticID, side: fatherSide, depth: depth + 1)
            walk(father, in: book, syntheticID: fatherID, side: fatherSide, depth: depth + 1)

            guard let mother = book.graph.spouse(of: father.id) else { return }
            let motherSide = side ?? .maternal
            // The viewer's own mother married into the paternal book: continue in her own family.
            if depth == 0, let born = bornMember(matching: mother) {
                let motherID = add(born.member, from: born.book, parent: syntheticID, side: motherSide, depth: 1)
                walk(born.member, in: born.book, syntheticID: motherID, side: motherSide, depth: 1)
            } else {
                _ = add(mother, from: book, parent: syntheticID, side: motherSide, depth: depth + 1)
            }
        }

        /// The maternal book's record of a woman who married into the paternal book, matched by name.
        private func bornMember(matching spouse: ILFamilyMemberEntity) -> (member: ILFamilyMemberEntity, book: Book)? {
            guard let maternal else { return nil }
            let key = ILFamilyTreeGraph.normalize(spouse.name)
            guard let match = maternal.tree.members.first(where: {
                $0.gender == .female
                    && ILFamilyTreeGraph.normalize($0.name) == key
                    && !maternal.graph.isMarriedIn($0)
            }) else { return nil }
            return (match, maternal)
        }

        private mutating func add(
            _ member: ILFamilyMemberEntity, from book: Book, parent: String?, side: ILFamilyTreeSide?, depth: Int
        ) -> String {
            let id = "\(book.tag):\(member.id)"
            members.append(ILFamilyMemberEntity(
                id: id, name: member.name, gender: member.gender,
                birthYear: member.birthYear, deathYear: member.deathYear, anniversary: member.anniversary,
                note: member.note, parentID: parent, spouseID: nil, isClanHead: false,
                residence: member.residence, burialPlace: member.burialPlace,
                dharmaName: member.dharmaName, tabletTemple: member.tabletTemple
            ))
            origins[id] = Origin(treeID: book.tree.id, memberID: member.id, side: side, depth: depth)
            return id
        }
    }
}
