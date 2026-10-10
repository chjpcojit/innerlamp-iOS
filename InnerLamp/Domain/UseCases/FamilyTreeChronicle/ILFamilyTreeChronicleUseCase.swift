//
//  ILFamilyTreeChronicleUseCase.swift
//  InnerLamp
//

import Foundation

/// One milestone row of the edit form, exactly as typed. `year` is raw text (may be empty).
struct ILFamilyTreeChronicleMilestoneDraft: Equatable, Identifiable {
    let id: String
    var year: String
    var text: String
}

/// The raw values the "Phả ký" edit form collects. Foundation-only so the UseCase can validate
/// and apply them without knowing anything about the screen.
struct ILFamilyTreeChronicleDraft: Equatable {
    /// "Quê gốc" — stored on the tree (`hometown`), not on the chronicle.
    var hometown = ""
    var origin = ""
    var milestones: [ILFamilyTreeChronicleMilestoneDraft] = []
    var shrineName = ""
    var shrineAddress = ""
    var annualGathering = ""
    var plaqueHan = ""
    var plaqueMeaning = ""
    var coupletUpper = ""
    var coupletLower = ""
    var teachings = ""
}

nonisolated enum ILFamilyTreeChronicleField: Equatable, Sendable {
    /// The year of the milestone with this id.
    case milestoneYear(String)
}

/// The first field that failed validation, with its message already localized.
nonisolated struct ILFamilyTreeChronicleIssue: Error, Equatable, Sendable {
    let field: ILFamilyTreeChronicleField
    let message: String
}

protocol ILFamilyTreeChronicleUseCase {
    /// Current values of `tree` as raw form text.
    func makeDraft(from tree: ILFamilyTreeEntity) -> ILFamilyTreeChronicleDraft

    /// Pure client-side validation + applying the draft to `tree` (hometown and chronicle).
    func apply(
        _ draft: ILFamilyTreeChronicleDraft,
        to tree: ILFamilyTreeEntity,
        currentYear: Int
    ) -> Result<ILFamilyTreeEntity, ILFamilyTreeChronicleIssue>

    /// Who may become the new clan head: living men of the blood line below the founder, oldest
    /// generation first.
    func clanHeadCandidates(in tree: ILFamilyTreeEntity) -> [ILFamilyMemberEntity]

    /// `tree` with `isClanHead` set on `memberID` only. Unknown ids leave the tree unchanged.
    func changeClanHead(to memberID: String, in tree: ILFamilyTreeEntity) -> ILFamilyTreeEntity

    /// Persists the updated books. Needs a Repository (network or Core Data) — see TD-FamilyTreeChronicle-001.
    func save(_ trees: [ILFamilyTreeEntity]) async throws
}

final class ILFamilyTreeChronicleUseCaseImpl: ILFamilyTreeChronicleUseCase {

    init() {}

    func makeDraft(from tree: ILFamilyTreeEntity) -> ILFamilyTreeChronicleDraft {
        let chronicle = tree.chronicle
        return ILFamilyTreeChronicleDraft(
            hometown: tree.hometown,
            origin: chronicle.origin,
            milestones: chronicle.milestones.map {
                ILFamilyTreeChronicleMilestoneDraft(id: $0.id, year: $0.year.map(String.init) ?? "", text: $0.text)
            },
            shrineName: chronicle.shrineName,
            shrineAddress: chronicle.shrineAddress,
            annualGathering: chronicle.annualGathering,
            plaqueHan: chronicle.plaqueHan,
            plaqueMeaning: chronicle.plaqueMeaning,
            coupletUpper: chronicle.coupletUpper,
            coupletLower: chronicle.coupletLower,
            teachings: chronicle.teachings
        )
    }

    func apply(
        _ draft: ILFamilyTreeChronicleDraft,
        to tree: ILFamilyTreeEntity,
        currentYear: Int
    ) -> Result<ILFamilyTreeEntity, ILFamilyTreeChronicleIssue> {
        var milestones: [ILFamilyMilestoneEntity] = []
        for row in draft.milestones {
            let yearText = trimmed(row.year)
            let text = trimmed(row.text)
            if yearText.isEmpty && text.isEmpty { continue }
            var year: Int?
            if !yearText.isEmpty {
                // @ai: assumption — see Docs/Assumptions/FamilyTreeChronicle/AS-FamilyTreeChronicle-003-milestone-year-rules.md
                guard yearText.count <= 4, let value = Int(yearText), value > 0, value <= currentYear else {
                    let message = String(format: "familyTreeChronicle.error.year.invalid".localized, currentYear)
                    return .failure(ILFamilyTreeChronicleIssue(field: .milestoneYear(row.id), message: message))
                }
                year = value
            }
            milestones.append(ILFamilyMilestoneEntity(id: row.id, year: year, text: text))
        }

        var updated = tree
        updated.hometown = trimmed(draft.hometown)
        updated.chronicle = ILFamilyChronicleEntity(
            origin: trimmed(draft.origin),
            milestones: milestones,
            shrineName: trimmed(draft.shrineName),
            shrineAddress: trimmed(draft.shrineAddress),
            annualGathering: trimmed(draft.annualGathering),
            plaqueHan: trimmed(draft.plaqueHan),
            plaqueMeaning: trimmed(draft.plaqueMeaning),
            coupletUpper: trimmed(draft.coupletUpper),
            coupletLower: trimmed(draft.coupletLower),
            teachings: trimmed(draft.teachings)
        )
        return .success(updated)
    }

    func clanHeadCandidates(in tree: ILFamilyTreeEntity) -> [ILFamilyMemberEntity] {
        // @ai: assumption — see Docs/Assumptions/FamilyTreeChronicle/AS-FamilyTreeChronicle-001-clan-head-candidates.md
        let graph = ILFamilyTreeGraph(members: tree.members)
        return tree.members
            .filter { $0.isLiving && $0.gender == .male && !graph.isMarriedIn($0) && graph.generation(of: $0) > 1 }
            .sorted { lhs, rhs in
                let left = graph.generation(of: lhs), right = graph.generation(of: rhs)
                if left != right { return left < right }
                let leftYear = lhs.birthYear ?? Int.max, rightYear = rhs.birthYear ?? Int.max
                if leftYear != rightYear { return leftYear < rightYear }
                return lhs.name < rhs.name
            }
    }

    func changeClanHead(to memberID: String, in tree: ILFamilyTreeEntity) -> ILFamilyTreeEntity {
        guard tree.members.contains(where: { $0.id == memberID }) else { return tree }
        var updated = tree
        updated.members = tree.members.map { member in
            var copy = member
            copy.isClanHead = member.id == memberID
            return copy
        }
        return updated
    }

    // Out of scope for ui-builder: no confirmed API contract / Repository yet — see
    // TD-FamilyTreeChronicle-001. One-line TODO only; no fabricated response.
    func save(_ trees: [ILFamilyTreeEntity]) async throws {
        print("TODO: implement save — network/repository call, not built by ui-builder")
    }

    // MARK: - Helpers
    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
