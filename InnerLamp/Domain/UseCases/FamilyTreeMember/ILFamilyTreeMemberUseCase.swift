//
//  ILFamilyTreeMemberUseCase.swift
//  InnerLamp
//

import Foundation

/// The raw values the member edit form collects, exactly as typed. Foundation-only so the UseCase
/// can validate and rebuild the member without knowing anything about the screen.
struct ILFamilyTreeMemberDraft: Equatable {
    var name = ""
    var gender: ILFamilyGender = .male
    var birthYear = ""
    var isLiving = true
    var residence = ""
    var deathYear = ""
    /// Free text such as "15 tháng Chạp" — only used when the person has passed away.
    var anniversary = ""
    var burialPlace = ""
    var dharmaName = ""
    var tabletTemple = ""
    var note = ""
}

nonisolated enum ILFamilyTreeMemberField: Equatable, Sendable {
    case member, name, birthYear, deathYear, anniversary
}

/// The first field that failed validation, with its message already localized.
nonisolated struct ILFamilyTreeMemberIssue: Error, Equatable, Sendable {
    let field: ILFamilyTreeMemberField
    let message: String
}

struct ILFamilyTreeMemberResult: Equatable {
    let tree: ILFamilyTreeEntity
    let memberID: String
}

protocol ILFamilyTreeMemberUseCase {
    /// The form values that mirror an existing member (what the edit form opens with).
    func makeDraft(from member: ILFamilyMemberEntity) -> ILFamilyTreeMemberDraft

    /// Pure client-side validation + replacement of the member in `tree`. Returns the updated tree
    /// or the first failing field. The member's id, parent, spouse and clan-head flag never change.
    func updateMember(
        _ draft: ILFamilyTreeMemberDraft,
        memberID: String,
        in tree: ILFamilyTreeEntity,
        currentYear: Int
    ) -> Result<ILFamilyTreeMemberResult, ILFamilyTreeMemberIssue>

    /// Persists the updated tree. Needs a Repository (network or Core Data) — see TD-FamilyTreeMember-001.
    func save(_ tree: ILFamilyTreeEntity) async throws
}

final class ILFamilyTreeMemberUseCaseImpl: ILFamilyTreeMemberUseCase {

    // @ai: assumption — see Docs/Assumptions/FamilyTreeMember/AS-FamilyTreeMember-002-edit-validation-rules.md
    static let minimumYear = ILFamilyTreeAddMemberUseCaseImpl.minimumYear

    init() {}

    func makeDraft(from member: ILFamilyMemberEntity) -> ILFamilyTreeMemberDraft {
        ILFamilyTreeMemberDraft(
            name: member.name,
            gender: member.gender,
            birthYear: member.birthYear.map(String.init) ?? "",
            isLiving: member.isLiving,
            residence: member.residence ?? "",
            deathYear: member.deathYear.map(String.init) ?? "",
            anniversary: member.anniversary.map {
                String(format: "familyTreeMember.anniversary.draftFormat".localized, $0.day, "lunarCalendar.month.\($0.month)".localized)
            } ?? "",
            burialPlace: member.burialPlace ?? "",
            dharmaName: member.dharmaName ?? "",
            tabletTemple: member.tabletTemple ?? "",
            note: member.note ?? ""
        )
    }

    func updateMember(
        _ draft: ILFamilyTreeMemberDraft,
        memberID: String,
        in tree: ILFamilyTreeEntity,
        currentYear: Int
    ) -> Result<ILFamilyTreeMemberResult, ILFamilyTreeMemberIssue> {
        guard let index = tree.members.firstIndex(where: { $0.id == memberID }) else {
            return .failure(issue(.member, "familyTreeMember.error.member.missing"))
        }

        let name = trimmed(draft.name)
        if name.isEmpty { return .failure(issue(.name, "familyTreeAddMember.error.name")) }

        // The birth year may stay empty (an unknown year renders "Chưa rõ"); when typed it must be sane.
        var birth: Int?
        let birthText = trimmed(draft.birthYear)
        if !birthText.isEmpty {
            guard let year = Int(birthText), year >= Self.minimumYear, year <= currentYear else {
                let message = String(format: "familyTreeAddMember.error.birth.invalid".localized, Self.minimumYear, currentYear)
                return .failure(ILFamilyTreeMemberIssue(field: .birthYear, message: message))
            }
            birth = year
        }

        var death: Int?
        var anniversary: ILFamilyLunarDate?
        if !draft.isLiving {
            // A deceased member is defined by having a death year, so it is required here.
            let deathText = trimmed(draft.deathYear)
            guard let year = Int(deathText), year >= (birth ?? Self.minimumYear), year <= currentYear else {
                let message = deathText.isEmpty
                    ? "familyTreeAddMember.error.death.required".localized
                    : String(format: "familyTreeAddMember.error.death.invalid".localized, currentYear)
                return .failure(ILFamilyTreeMemberIssue(field: .deathYear, message: message))
            }
            death = year

            let anniversaryText = trimmed(draft.anniversary)
            if !anniversaryText.isEmpty {
                guard let date = ILFamilyLunarDateParser.parse(anniversaryText) else {
                    return .failure(issue(.anniversary, "familyTreeAddMember.error.anniversary.invalid"))
                }
                anniversary = date
            }
        }

        var member = tree.members[index]
        member.name = name
        member.gender = draft.gender
        member.birthYear = birth
        member.deathYear = death
        member.anniversary = anniversary
        member.residence = draft.isLiving ? nonEmpty(draft.residence) : nil
        member.burialPlace = draft.isLiving ? nil : nonEmpty(draft.burialPlace)
        member.dharmaName = nonEmpty(draft.dharmaName)
        member.tabletTemple = nonEmpty(draft.tabletTemple)
        member.note = nonEmpty(draft.note)

        var updated = tree
        updated.members[index] = member
        return .success(ILFamilyTreeMemberResult(tree: updated, memberID: memberID))
    }

    // Out of scope for ui-builder: no confirmed API contract / Repository yet — see
    // TD-FamilyTreeMember-001. One-line TODO only; no fabricated response.
    func save(_ tree: ILFamilyTreeEntity) async throws {
        print("TODO: implement save — network/repository call, not built by ui-builder")
    }

    // MARK: - Helpers
    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func nonEmpty(_ text: String) -> String? {
        let value = trimmed(text)
        return value.isEmpty ? nil : value
    }

    private func issue(_ field: ILFamilyTreeMemberField, _ key: String) -> ILFamilyTreeMemberIssue {
        ILFamilyTreeMemberIssue(field: field, message: key.localized)
    }
}
