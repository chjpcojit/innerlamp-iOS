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
            sourceURL: sourceURL(from: translation?.sourceUrl),
            license: translation?.license ?? "",
            lineCount: translation?.lineCount ?? 0,
            chapters: sections.enumerated().map { index, section in
                ILSutraDetailChapterEntity(
                    id: "section.\(index + 1)",
                    number: String(index + 1),
                    title: section.name,
                    lineCount: section.lineCount
                )
            }
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

    /// Pāli name, else English name — whichever differs from the displayed title.
    private static func originalTitle(from dto: ILSutraDTO, title: String) -> String {
        for language in ["pli", "en"] {
            if let value = nonEmpty(dto.titles[language]), value != title { return value }
        }
        return ""
    }

    /// Only an absolute `http(s)` link is kept — the value is opened in the browser.
    private static func sourceURL(from raw: String?) -> String? {
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
