//
//  ILSutraMapper.swift
//  InnerLamp
//

import Foundation

/// Converts sutra DTOs into Domain entities.
nonisolated enum ILSutraMapper {

    static func toDomain(_ dto: ILSutraDTO) -> ILSutraEntity {
        let title = title(from: dto)
        return ILSutraEntity(
            id: dto.id,
            title: title,
            originalTitle: originalTitle(from: dto, title: title),
            kind: dto.kind.flatMap(ILSutraKind.init(wireValue:)),
            tradition: dto.tradition.flatMap(ILSutraTradition.init(wireValue:)),
            collection: dto.collection ?? "",
            reference: dto.reference ?? "",
            isDailyChant: dto.dailyChant,
            purposes: dto.purposes.compactMap(ILSutraPurpose.init(wireValue:)),
            durationMinutes: dto.durationMinutes,
            translator: preferredTranslation(of: dto)?.translator ?? "",
            audioURL: nonEmpty(dto.audioUrl) ?? ""
        )
    }

    static func toDetail(_ dto: ILSutraDTO) -> ILSutraDetailSutraEntity {
        let summary = toDomain(dto)
        let translation = preferredTranslation(of: dto)
        let sections = translation?.sections ?? []
        return ILSutraDetailSutraEntity(
            id: summary.id,
            title: summary.title,
            originalTitle: summary.originalTitle,
            kind: summary.kind,
            tradition: summary.tradition,
            collection: summary.collection,
            reference: summary.reference,
            isDailyChant: summary.isDailyChant,
            purposes: summary.purposes,
            durationMinutes: summary.durationMinutes,
            translator: summary.translator,
            sourceName: translation?.sourceName ?? "",
            sourceURL: absoluteWebLink(from: translation?.sourceUrl),
            license: translation?.license ?? "",
            lineCount: translation?.lineCount ?? 0,
            chapters: sections.enumerated().map { index, section in
                ILSutraDetailChapterEntity(
                    id: "section.\(index + 1)",
                    number: String(index + 1),
                    title: section.name,
                    lineCount: section.lineCount
                )
            },
            summary: nonEmpty(dto.summary) ?? "",
            author: nonEmpty(dto.author) ?? "",
            hanTranslator: nonEmpty(dto.hanTranslator) ?? "",
            hanTranslationYear: dto.hanTranslationYear,
            referenceNote: nonEmpty(dto.referenceNote) ?? "",
            deities: (dto.deities ?? []).map { deity in
                ILSutraDetailDeityEntity(
                    id: deity.deityId,
                    name: nonEmpty(deity.nameVi) ?? deity.deityId,
                    role: deity.role.flatMap(deityRole(wireValue:))
                )
            },
            alternateTitles: alternateTitles(
                from: dto,
                excluding: [summary.title, summary.originalTitle]
            ),
            isUnreviewed: nonEmpty(dto.reviewStatus) != nil,
            variant: translation?.variant.flatMap(variant(wireValue:)),
            licenseURL: absoluteWebLink(from: translation?.licenseUrl),
            licenseNote: nonEmpty(translation?.licenseNote) ?? "",
            note: nonEmpty(translation?.note) ?? ""
        )
    }

    /// @ai: assumption — see Docs/Assumptions/Sutras/AS-Sutras-003-preferred-translation-and-title.md
    /// The Vietnamese translation when there is one, otherwise the first the server lists.
    private static func preferredTranslation(of dto: ILSutraDTO) -> ILSutraTranslationDTO? {
        dto.translations.first { $0.lang == "vi" } ?? dto.translations.first
    }

    /// `vi` → `en` → `pli` → any other language → the slug.
    private static func title(from dto: ILSutraDTO) -> String {
        for language in ["vi", "en", "pli"] {
            if let value = nonEmpty(dto.titles[language]) { return value }
        }
        return dto.titles.keys.sorted().compactMap { nonEmpty(dto.titles[$0]) }.first ?? dto.id
    }

    /// The server `original_title` (detail only), else the Pāli name, else the English name — whichever
    /// differs from the displayed title.
    private static func originalTitle(from dto: ILSutraDTO, title: String) -> String {
        if let value = nonEmpty(dto.originalTitle), value != title { return value }
        for language in ["pli", "en"] {
            if let value = nonEmpty(dto.titles[language]), value != title { return value }
        }
        return ""
    }

    /// The other-language names in `titles`, in a stable order (Pāli, Sanskrit, Chinese, English, then
    /// any language the app does not know), skipping `vi` and the values already shown.
    private static func alternateTitles(
        from dto: ILSutraDTO,
        excluding shown: [String]
    ) -> [ILSutraDetailAlternateTitleEntity] {
        let preferred = ["pli", "sa", "zh", "en"]
        let others = dto.titles.keys.filter { $0 != "vi" && !preferred.contains($0) }.sorted()
        return (preferred + others).compactMap { language in
            guard let text = nonEmpty(dto.titles[language]), !shown.contains(text) else { return nil }
            return ILSutraDetailAlternateTitleEntity(language: language, text: text)
        }
    }

    private static func deityRole(wireValue: String) -> ILSutraDeityRole? {
        switch wireValue {
        case "SPEAKER": .speaker
        case "SUBJECT": .subject
        case "MENTIONED": .mentioned
        default: nil
        }
    }

    private static func variant(wireValue: String) -> ILSutraTranslationVariant? {
        switch wireValue {
        case "translation": .translation
        case "chant": .chant
        case "meaning": .meaning
        case "poem": .poem
        default: nil
        }
    }

    /// Only an absolute `http(s)` link is kept — the value is opened in the browser.
    private static func absoluteWebLink(from raw: String?) -> String? {
        guard let value = nonEmpty(raw),
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil else { return nil }
        return value
    }

    private static func nonEmpty(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
