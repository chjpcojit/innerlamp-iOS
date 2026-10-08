//
//  ILFamilyTreeUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILFamilyTreeUseCase {
    /// Loads the user's clan books (paternal and/or maternal). Needs a Repository (network or
    /// Core Data) — see TD-FamilyTree-001.
    func loadTrees() async throws -> [ILFamilyTreeEntity]

    /// Pure in-memory index used for generations, lineage, relations and search.
    func makeGraph(for tree: ILFamilyTreeEntity) -> ILFamilyTreeGraph

    /// The "Nội – ngoại của bạn" view, or `nil` when the viewer is not in the paternal book.
    func makePedigree(
        viewerID: String, paternal: ILFamilyTreeEntity, maternal: ILFamilyTreeEntity?
    ) -> ILFamilyTreePedigree?
}

final class ILFamilyTreeUseCaseImpl: ILFamilyTreeUseCase {

    init() {}

    // Out of scope for il-screen-builder: no confirmed API contract / Repository yet. The body is
    // the one-line TODO plus the only value that compiles without inventing data (no books, so
    // the screen shows its empty state).
    func loadTrees() async throws -> [ILFamilyTreeEntity] {
        print("TODO: implement loadTrees — network/repository call, not built by il-screen-builder")
        return []
    }

    func makeGraph(for tree: ILFamilyTreeEntity) -> ILFamilyTreeGraph {
        ILFamilyTreeGraph(members: tree.members)
    }

    func makePedigree(
        viewerID: String, paternal: ILFamilyTreeEntity, maternal: ILFamilyTreeEntity?
    ) -> ILFamilyTreePedigree? {
        ILFamilyTreePedigree.build(viewerID: viewerID, paternal: paternal, maternal: maternal)
    }
}
