//
//  ILFamilyTreeAddMemberUseCase.swift
//  InnerLamp
//

import Foundation

/// How the new person relates to the chosen relative.
enum ILFamilyAddRelation: Equatable {
    /// Child of the relative (or of the relative's partner's blood line — see `addMember`).
    case child
    /// Husband / wife of the relative.
    case spouse
}

/// The raw values the "Thêm người vào gia phả" form collects, exactly as typed. Foundation-only so
/// the UseCase can validate and build the member without knowing anything about the screen.
struct ILFamilyTreeAddMemberDraft: Equatable {
    var relation: ILFamilyAddRelation = .child
    var relativeID = ""
    var name = ""
    /// Ignored for `.spouse`: the gender follows the relative's.
    var gender: ILFamilyGender = .male
    var birthYear = ""
    var isLiving = true
    var deathYear = ""
    /// Free text such as "15 tháng Chạp" — only used when the person has passed away.
    var anniversary = ""
    var residence = ""
    var burialPlace = ""
    var note = ""
}

nonisolated enum ILFamilyTreeAddMemberField: Equatable, Sendable {
    case relation, name, birthYear, deathYear, anniversary, residence
}

/// The first field that failed validation, with its message already localized.
nonisolated struct ILFamilyTreeAddMemberIssue: Error, Equatable, Sendable {
    let field: ILFamilyTreeAddMemberField
    let message: String
}

struct ILFamilyTreeAddMemberResult: Equatable {
    let tree: ILFamilyTreeEntity
    let memberID: String
}

protocol ILFamilyTreeAddMemberUseCase {
    /// Pure client-side validation + placement of the new person in `tree`. Returns the updated
    /// tree and the new member's id, or the first failing field.
    func addMember(
        _ draft: ILFamilyTreeAddMemberDraft,
        to tree: ILFamilyTreeEntity,
        currentYear: Int
    ) -> Result<ILFamilyTreeAddMemberResult, ILFamilyTreeAddMemberIssue>

    /// Persists the updated tree. Needs a Repository (network or Core Data) — see TD-FamilyTreeAddMember-001.
    func save(_ tree: ILFamilyTreeEntity) async throws
}

final class ILFamilyTreeAddMemberUseCaseImpl: ILFamilyTreeAddMemberUseCase {

    // @ai: assumption — see Docs/Assumptions/FamilyTreeAddMember/AS-FamilyTreeAddMember-001-year-and-generation-limits.md
    static let minimumYear = 1700
    static let maximumGeneration = 7

    private let makeID: () -> String

    init(makeID: @escaping () -> String = { "n" + UUID().uuidString }) {
        self.makeID = makeID
    }

    func addMember(
        _ draft: ILFamilyTreeAddMemberDraft,
        to tree: ILFamilyTreeEntity,
        currentYear: Int
    ) -> Result<ILFamilyTreeAddMemberResult, ILFamilyTreeAddMemberIssue> {
        let graph = ILFamilyTreeGraph(members: tree.members)
        guard let relative = graph.member(id: draft.relativeID) else {
            return .failure(issue(.relation, "familyTreeAddMember.error.relative.missing"))
        }

        let name = trimmed(draft.name)
        if name.isEmpty { return .failure(issue(.name, "familyTreeAddMember.error.name")) }

        let birthText = trimmed(draft.birthYear)
        guard let birth = Int(birthText), birth >= Self.minimumYear, birth <= currentYear else {
            let message = birthText.isEmpty
                ? "familyTreeAddMember.error.birth.required".localized
                : String(format: "familyTreeAddMember.error.birth.invalid".localized, Self.minimumYear, currentYear)
            return .failure(ILFamilyTreeAddMemberIssue(field: .birthYear, message: message))
        }

        var death: Int?
        var anniversary: ILFamilyLunarDate?
        if !draft.isLiving {
            let deathText = trimmed(draft.deathYear)
            guard let year = Int(deathText), year >= birth, year <= currentYear else {
                let message = deathText.isEmpty
                    ? "familyTreeAddMember.error.death.required".localized
                    : String(format: "familyTreeAddMember.error.death.invalid".localized, currentYear)
                return .failure(ILFamilyTreeAddMemberIssue(field: .deathYear, message: message))
            }
            death = year

            let anniversaryText = trimmed(draft.anniversary)
            if !anniversaryText.isEmpty {
                guard let date = ILFamilyLunarDateParser.parse(anniversaryText) else {
                    return .failure(issue(.anniversary, "familyTreeAddMember.error.anniversary.invalid"))
                }
                anniversary = date
            }
        } else if trimmed(draft.residence).isEmpty {
            return .failure(issue(.residence, "familyTreeAddMember.error.residence"))
        }

        let parentID: String?
        let spouseID: String?
        let gender: ILFamilyGender
        switch draft.relation {
        case .child:
            // A child of a married-in person belongs to the partner's blood line.
            let parent = graph.isMarriedIn(relative)
                ? (relative.spouseID.flatMap { graph.member(id: $0) } ?? relative)
                : relative
            guard graph.generation(of: parent) + 1 <= Self.maximumGeneration else {
                return .failure(issue(.relation, "familyTreeAddMember.error.generation.max"))
            }
            parentID = parent.id
            spouseID = nil
            gender = draft.gender
        case .spouse:
            if graph.isMarriedIn(relative) {
                let key = relative.gender == .female
                    ? "familyTreeAddMember.error.spouse.marriedIn.daughter"
                    : "familyTreeAddMember.error.spouse.marriedIn.son"
                return .failure(ILFamilyTreeAddMemberIssue(field: .relation, message: String(format: key.localized, relative.name)))
            }
            if graph.spouse(of: relative.id) != nil {
                let key = relative.gender == .female
                    ? "familyTreeAddMember.error.spouse.taken.husband"
                    : "familyTreeAddMember.error.spouse.taken.wife"
                return .failure(ILFamilyTreeAddMemberIssue(field: .relation, message: String(format: key.localized, relative.name)))
            }
            parentID = nil
            spouseID = relative.id
            gender = relative.gender == .male ? .female : .male
        }

        let note = trimmed(draft.note)
        let member = ILFamilyMemberEntity(
            id: makeID(), name: name, gender: gender, birthYear: birth, deathYear: death,
            anniversary: anniversary, note: note.isEmpty ? nil : note, parentID: parentID, spouseID: spouseID,
            isClanHead: false,
            residence: draft.isLiving ? nonEmpty(draft.residence) : nil,
            burialPlace: draft.isLiving ? nil : nonEmpty(draft.burialPlace)
        )
        var updated = tree
        updated.members.append(member)
        return .success(ILFamilyTreeAddMemberResult(tree: updated, memberID: member.id))
    }

    // Out of scope for il-screen-builder: no confirmed API contract / Repository yet — see
    // TD-FamilyTreeAddMember-001. One-line TODO only; no fabricated response.
    func save(_ tree: ILFamilyTreeEntity) async throws {
        print("TODO: implement save — network/repository call, not built by il-screen-builder")
    }

    // MARK: - Helpers
    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func nonEmpty(_ text: String) -> String? {
        let value = trimmed(text)
        return value.isEmpty ? nil : value
    }

    private func issue(_ field: ILFamilyTreeAddMemberField, _ key: String) -> ILFamilyTreeAddMemberIssue {
        ILFamilyTreeAddMemberIssue(field: field, message: key.localized)
    }
}
