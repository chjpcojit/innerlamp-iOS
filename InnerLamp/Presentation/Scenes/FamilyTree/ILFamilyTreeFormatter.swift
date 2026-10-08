//
//  ILFamilyTreeFormatter.swift
//  InnerLamp
//

import Foundation

/// Display text for the FamilyTree screen. `Entity -> text` is presentation-only (copy, ordering),
/// so it lives here rather than in Domain.
enum ILFamilyTreeFormatter {

    // MARK: - Header
    static func subtitle(hometown: String, generations: Int, people: Int) -> String {
        hometown.isEmpty
            ? String(format: "familyTree.subtitle.noHometown".localized, generations, people)
            : String(format: "familyTree.subtitle.format".localized, hometown, generations, people)
    }

    static func chipTitle(generation: Int) -> String {
        generation == 0 ? "familyTree.generation.all".localized : generationLabel(generation)
    }

    static func searchCount(_ count: Int) -> String {
        String(format: "familyTree.search.count".localized, count)
    }

    // MARK: - Node
    /// Founders and the "full names" setting show the whole name, everyone else the last two words
    /// ("Nguyễn Hữu Minh" → "Hữu Minh").
    static func nodeName(_ member: ILFamilyMemberEntity, isFounder: Bool) -> String {
        guard !isFounder else { return member.name }
        return member.name.split(separator: " ").suffix(2).joined(separator: " ")
    }

    static func nodeMeta(
        _ member: ILFamilyMemberEntity, generation: Int, isFounder: Bool, isMarriedIn: Bool
    ) -> String {
        let key: String
        if isFounder {
            key = "familyTree.node.founder"
        } else if member.isClanHead {
            key = "familyTree.node.head"
        } else if isMarriedIn {
            key = member.gender == .female ? "familyTree.node.daughterInLaw" : "familyTree.node.sonInLaw"
        } else {
            key = "familyTree.node.generation"
        }
        return String(format: key.localized, generation)
    }

    // MARK: - Detail
    static func generationLabel(_ generation: Int) -> String {
        String(format: "familyTree.generation.format".localized, generation)
    }

    static func detailMeta(_ member: ILFamilyMemberEntity, generation: Int, isMarriedIn: Bool) -> String {
        var parts = [generationLabel(generation)]
        if isMarriedIn {
            parts.append((member.gender == .female ? "familyTree.role.daughterInLaw" : "familyTree.role.sonInLaw").localized)
        }
        parts.append((member.gender == .female ? "familyTree.gender.female" : "familyTree.gender.male").localized)
        return parts.joined(separator: " · ")
    }

    static func status(_ member: ILFamilyMemberEntity) -> String {
        (member.isLiving ? "familyTree.status.living" : "familyTree.status.deceased").localized
    }

    static func role(_ member: ILFamilyMemberEntity, isFounder: Bool) -> String? {
        if isFounder { return "familyTree.role.founder".localized }
        return member.isClanHead ? "familyTree.role.head".localized : nil
    }

    static func years(_ member: ILFamilyMemberEntity, currentYear: Int) -> String {
        switch (member.birthYear, member.deathYear) {
        case let (birth?, death?):
            return String(format: "familyTree.years.deceased".localized, birth, death, max(death - birth + 1, 0))
        case let (birth?, nil):
            return String(format: "familyTree.years.living".localized, birth, max(currentYear - birth, 0))
        case let (nil, death?):
            return String(format: "familyTree.years.diedOnly".localized, death)
        case (nil, nil):
            return "familyTree.years.unknown".localized
        }
    }

    static func anniversary(_ member: ILFamilyMemberEntity) -> String? {
        guard let date = member.anniversary else { return nil }
        return String(
            format: "familyTree.anniversary.format".localized,
            date.day, "lunarCalendar.month.\(date.month)".localized
        )
    }

    /// A branch end reads "Dứt nhánh · không có hậu duệ" instead of the Chi trưởng / Chi thứ text.
    static func branch(_ branch: ILFamilyBranch, isBranchEnd: Bool = false) -> String {
        if isBranchEnd { return "familyTree.branch.ended".localized }
        switch branch {
        case .founder:
            return "familyTree.branch.founder".localized
        case .eldest(let ancestor):
            return String(format: "familyTree.branch.eldest".localized, givenName(ancestor.name))
        case .younger(let ancestor):
            return String(format: "familyTree.branch.younger".localized, givenName(ancestor.name))
        }
    }

    // MARK: - Memorial ("TƯỞNG NIỆM")
    static func memorial(_ member: ILFamilyMemberEntity, now: Date) -> ILFamilyTreeMemorialModel {
        let currentYear = Calendar.current.component(.year, from: now)
        guard let date = member.anniversary else {
            return ILFamilyTreeMemorialModel(
                title: "familyTree.memorial.unknownTitle".localized,
                subtitle: "familyTree.memorial.unknownSubtitle".localized,
                buttonTitle: "familyTree.memorial.addDate".localized,
                isButtonFilled: false
            )
        }
        let ordinal = max(1, currentYear - (member.deathYear ?? currentYear))
        let subtitle = (memorialCountdown(date, now: now) ?? "")
            + String(format: "familyTree.memorial.subtitleFormat".localized, ordinal)
        return ILFamilyTreeMemorialModel(
            title: String(format: "familyTree.memorial.titleFormat".localized, date.day, "lunarCalendar.month.\(date.month)".localized),
            subtitle: subtitle,
            buttonTitle: "familyTree.memorial.remind".localized,
            isButtonFilled: true
        )
    }

    /// "Còn 12 ngày · 02/11 dương lịch · " for the next occurrence of the lunar anniversary, or
    /// `nil` when the solar date cannot be resolved.
    static func memorialCountdown(_ date: ILFamilyLunarDate, now: Date) -> String? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let today = calendar.startOfDay(for: now)
        let lunarYear = ILLunarCalendar.solarToLunar(date: now, calendar: calendar).year
        for year in [lunarYear, lunarYear + 1] {
            guard let solar = ILLunarCalendar.lunarToSolar(day: date.day, month: date.month, year: year),
                  let target = calendar.date(from: DateComponents(year: solar.year, month: solar.month, day: solar.day)),
                  let days = calendar.dateComponents([.day], from: today, to: target).day,
                  days >= 0 else { continue }
            let lead: String
            switch days {
            case 0: lead = "familyTree.memorial.today".localized
            case 1: lead = "familyTree.memorial.tomorrow".localized
            default: lead = String(format: "familyTree.memorial.daysLeft".localized, days)
            }
            return String(format: "familyTree.memorial.countdownFormat".localized,
                          lead, String(format: "%02d/%02d", solar.day, solar.month))
        }
        return nil
    }

    static func contextualAction(_ member: ILFamilyMemberEntity) -> String {
        (member.isLiving ? "familyTree.cta.addDescendant" : "familyTree.cta.remindAnniversary").localized
    }

    /// "Với bạn" text: "Chính bạn", "Cha", "Ông", "Cụ bà", "Con", "Anh trai"...
    static func kinship(_ kinship: ILFamilyKinship) -> String {
        let key: String
        switch kinship {
        case .me:
            key = "familyTree.kin.me"
        case .ancestor(let generations, let gender):
            let isMale = gender == .male
            switch generations {
            case 1: key = isMale ? "familyTree.relation.father" : "familyTree.relation.mother"
            case 2: key = isMale ? "familyTree.kin.grandfather" : "familyTree.kin.grandmother"
            case 3: key = isMale ? "familyTree.kin.greatGrandfather" : "familyTree.kin.greatGrandmother"
            case 4: key = isMale ? "familyTree.kin.kyMale" : "familyTree.kin.kyFemale"
            default: key = isMale ? "familyTree.kin.toMale" : "familyTree.kin.toFemale"
            }
        case .descendant(let generations):
            switch generations {
            case 1: key = "familyTree.kin.child"
            case 2: key = "familyTree.kin.grandchild"
            case 3: key = "familyTree.kin.greatGrandchild"
            case 4: key = "familyTree.kin.chut"
            default: key = "familyTree.kin.chit"
            }
        case .sibling(let gender, let isOlder):
            let isMale = gender == .male
            switch isOlder {
            case .some(true): key = isMale ? "familyTree.kin.olderBrother" : "familyTree.kin.olderSister"
            case .some(false): key = isMale ? "familyTree.kin.youngerBrother" : "familyTree.kin.youngerSister"
            case .none: key = isMale ? "familyTree.relation.brother" : "familyTree.relation.sister"
            }
        case .spouse(let gender):
            key = gender == .female ? "familyTree.relation.wife" : "familyTree.relation.husband"
        }
        return key.localized
    }

    static func relation(_ kind: ILFamilyRelationKind) -> String {
        let key: String
        switch kind {
        case .father: key = "familyTree.relation.father"
        case .mother: key = "familyTree.relation.mother"
        case .husband: key = "familyTree.relation.husband"
        case .wife: key = "familyTree.relation.wife"
        case .brother: key = "familyTree.relation.brother"
        case .sister: key = "familyTree.relation.sister"
        case .son: key = "familyTree.relation.son"
        case .daughter: key = "familyTree.relation.daughter"
        }
        return key.localized
    }

    // MARK: - Book switcher & merged "Nội – ngoại" view
    /// "Bên nội · Hành Thiện · 6 đời · 24 người".
    static func switcherSubtitle(side: ILFamilyTreeSide, hometown: String, generations: Int, people: Int) -> String {
        let sideText = (side == .paternal ? "familyTree.switcher.side.paternal" : "familyTree.switcher.side.maternal").localized
        return hometown.isEmpty
            ? String(format: "familyTree.switcher.subtitle.noHometown".localized, sideText, generations, people)
            : String(format: "familyTree.switcher.subtitle.format".localized, sideText, hometown, generations, people)
    }

    /// "Họ Trần" → "họ Trần", for "Mở trong họ Trần".
    static func bookReference(_ clanName: String) -> String {
        clanName.hasPrefix("Họ") ? "họ" + clanName.dropFirst(2) : clanName
    }

    /// Kin label of someone `depth` generations above the viewer: "Chính bạn", "Cha", "Ông nội", "Bà ngoại"...
    static func mergedKin(depth: Int, gender: ILFamilyGender, side: ILFamilyTreeSide?) -> String {
        guard depth > 0 else { return "familyTree.kin.me".localized }
        let base = kinship(.ancestor(generations: depth, gender: gender))
        guard depth >= 2, let side else { return base }
        return base + " " + (side == .paternal ? "familyTree.merged.side.paternal" : "familyTree.merged.side.maternal").localized
    }

    /// "Bạn", "Cha mẹ", "Ông bà", "Cụ", "Kỵ", "Tổ" — the row names of the merged tree.
    static func mergedLevel(depth: Int) -> String {
        "familyTree.merged.level.\(min(max(depth, 0), 5))".localized
    }

    /// Chip title in the merged view: row `generation` (1 = the viewer).
    static func mergedChipTitle(generation: Int) -> String {
        generation == 0 ? "familyTree.generation.all".localized : mergedLevel(depth: generation - 1)
    }

    /// "Ông bà · nội · Nam".
    static func mergedDetailMeta(depth: Int, gender: ILFamilyGender, side: ILFamilyTreeSide?) -> String {
        var parts = [mergedLevel(depth: depth)]
        if let side {
            parts.append((side == .paternal ? "familyTree.merged.side.paternal" : "familyTree.merged.side.maternal").localized)
        }
        parts.append((gender == .female ? "familyTree.gender.female" : "familyTree.gender.male").localized)
        return parts.joined(separator: " · ")
    }

    static func mergedBranch(side: ILFamilyTreeSide?) -> String {
        switch side {
        case .none: return "familyTree.merged.branch.root".localized
        case .some(.paternal): return "familyTree.merged.branch.paternal".localized
        case .some(.maternal): return "familyTree.merged.branch.maternal".localized
        }
    }

    /// "Nguyễn Hữu Lộc" → "Lộc".
    private static func givenName(_ fullName: String) -> String {
        fullName.split(separator: " ").last.map(String.init) ?? fullName
    }
}
