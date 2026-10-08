//
//  ILFamilyTreeViewerResolver.swift
//  InnerLamp
//

import Foundation

/// Decides which member of a clan book is the signed-in user ("BẠN"). This is the single seam the
/// FamilyTree ViewModel asks — swapping the resolver is the only change needed to link the account.
protocol ILFamilyTreeViewerResolving {
    /// The id of the member that is the viewer, or `nil` when the viewer is not in the tree.
    func viewerMemberID(in tree: ILFamilyTreeEntity) -> String?
}

/// TEMPORARY resolver: pretends the clan head is the viewer so the "BẠN" UI can be exercised. A
/// book without a clan head (a freshly created one) falls back to the living blood-line member of
/// the newest generation, so the "BẠN" marker and the "Nội – ngoại" view still have someone to start from.
// @ai: assumption — see Docs/Assumptions/FamilyTree/AS-FamilyTree-009-viewer-matched-by-name-or-phone.md
// @ai: tech debt — see Docs/Tech-Debt/FamilyTree/TD-FamilyTree-010-placeholder-viewer-resolver.md
/// Replace with a resolver that matches the signed-in account's name or phone number against the
/// tree's members.
struct ILPlaceholderFamilyTreeViewerResolver: ILFamilyTreeViewerResolving {

    func viewerMemberID(in tree: ILFamilyTreeEntity) -> String? {
        if let head = tree.members.first(where: \.isClanHead) { return head.id }
        let graph = ILFamilyTreeGraph(members: tree.members)
        let newest = tree.members
            .filter { $0.isLiving && !graph.isMarriedIn($0) }
            .max { graph.generation(of: $0) < graph.generation(of: $1) }
        return newest?.id
    }
}
