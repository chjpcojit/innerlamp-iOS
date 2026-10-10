//
//  ILFamilyTreeCreateUseCase.swift
//  InnerLamp
//

import Foundation

/// The raw values the "Tạo gia phả" form collects, exactly as typed. Foundation-only so the
/// UseCase can validate and build the tree without knowing anything about the screen.
struct ILFamilyTreeCreateDraft: Equatable {
    var clanName = ""
    var hometown = ""
    var founderName = ""
    var birthYear = ""
    var isFounderLiving = false
    var deathYear = ""
    /// Free text such as "15 tháng Chạp" — only used when the founder has passed away.
    var anniversary = ""
    var spouseName = ""
}

nonisolated enum ILFamilyTreeCreateField: Equatable, Sendable {
    case clanName, hometown, founderName, birthYear, deathYear, anniversary
}

/// The first field that failed validation, with its message already localized.
nonisolated struct ILFamilyTreeCreateIssue: Error, Equatable, Sendable {
    let field: ILFamilyTreeCreateField
    let message: String
}

protocol ILFamilyTreeCreateUseCase {
    /// Clan name as shown in the header and stored on the tree: always starts with "Họ ".
    func clanDisplayName(_ rawName: String) -> String

    /// Pure client-side validation + build of the new clan book (founder, and the founder's wife
    /// if one was given). Returns the first failing field instead of a tree when invalid.
    func createTree(from draft: ILFamilyTreeCreateDraft, currentYear: Int) -> Result<ILFamilyTreeEntity, ILFamilyTreeCreateIssue>

    /// Persists the new tree. Needs a Repository (network or Core Data) — see TD-FamilyTreeCreate-001.
    func save(_ tree: ILFamilyTreeEntity) async throws
}

final class ILFamilyTreeCreateUseCaseImpl: ILFamilyTreeCreateUseCase {

    static let minimumYear = 1300
    static let founderID = "p1"
    static let spouseID = "s1"

    init() {}

    func clanDisplayName(_ rawName: String) -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return "" }
        let prefix = "familyTreeCreate.clan.prefix".localized
        let hasPrefix = name.range(of: prefix + " ", options: [.anchored, .caseInsensitive]) != nil
        return hasPrefix ? name : prefix + " " + name
    }

    func createTree(from draft: ILFamilyTreeCreateDraft, currentYear: Int) -> Result<ILFamilyTreeEntity, ILFamilyTreeCreateIssue> {
        let clanName = trimmed(draft.clanName)
        let hometown = trimmed(draft.hometown)
        let founderName = trimmed(draft.founderName)

        if clanName.isEmpty { return .failure(issue(.clanName, "familyTreeCreate.error.clanName")) }
        if hometown.isEmpty { return .failure(issue(.hometown, "familyTreeCreate.error.hometown")) }
        if founderName.isEmpty { return .failure(issue(.founderName, "familyTreeCreate.error.founderName")) }

        // @ai: assumption — see Docs/Assumptions/FamilyTreeCreate/AS-FamilyTreeCreate-001-year-limits.md
        let birthText = trimmed(draft.birthYear)
        guard let birth = Int(birthText), birth >= Self.minimumYear, birth <= currentYear else {
            let message = birthText.isEmpty
                ? "familyTreeCreate.error.birth.required".localized
                : String(format: "familyTreeCreate.error.birth.invalid".localized, Self.minimumYear, currentYear)
            return .failure(ILFamilyTreeCreateIssue(field: .birthYear, message: message))
        }

        var death: Int?
        var anniversary: ILFamilyLunarDate?
        if !draft.isFounderLiving {
            let deathText = trimmed(draft.deathYear)
            guard let year = Int(deathText), year >= birth, year <= currentYear else {
                let message = deathText.isEmpty
                    ? "familyTreeCreate.error.death.required".localized
                    : String(format: "familyTreeCreate.error.death.invalid".localized, currentYear)
                return .failure(ILFamilyTreeCreateIssue(field: .deathYear, message: message))
            }
            death = year

            let anniversaryText = trimmed(draft.anniversary)
            if !anniversaryText.isEmpty {
                guard let date = parseLunarDate(anniversaryText) else {
                    return .failure(issue(.anniversary, "familyTreeCreate.error.anniversary.invalid"))
                }
                anniversary = date
            }
        }

        // @ai: assumption — see Docs/Assumptions/FamilyTreeCreate/AS-FamilyTreeCreate-003-founder-male-wife-female.md
        var members = [
            ILFamilyMemberEntity(
                id: Self.founderID, name: founderName, gender: .male, birthYear: birth, deathYear: death,
                anniversary: anniversary, note: nil, parentID: nil, spouseID: nil, isClanHead: false
            )
        ]
        let spouseName = trimmed(draft.spouseName)
        if !spouseName.isEmpty {
            members.append(ILFamilyMemberEntity(
                id: Self.spouseID, name: spouseName, gender: .female, birthYear: nil, deathYear: nil,
                anniversary: nil, note: nil, parentID: nil, spouseID: Self.founderID, isClanHead: false
            ))
        }
        return .success(ILFamilyTreeEntity(clanName: clanDisplayName(clanName), hometown: hometown, members: members))
    }

    // Out of scope for ui-builder: no confirmed API contract / Repository yet — see
    // TD-FamilyTreeCreate-001. One-line TODO only; no fabricated response.
    func save(_ tree: ILFamilyTreeEntity) async throws {
        print("TODO: implement save — network/repository call, not built by ui-builder")
    }

    // MARK: - Helpers
    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func issue(_ field: ILFamilyTreeCreateField, _ key: String) -> ILFamilyTreeCreateIssue {
        ILFamilyTreeCreateIssue(field: field, message: key.localized)
    }

    private func parseLunarDate(_ text: String) -> ILFamilyLunarDate? {
        ILFamilyLunarDateParser.parse(text)
    }
}
