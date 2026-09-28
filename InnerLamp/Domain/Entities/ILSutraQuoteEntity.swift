//
//  ILSutraQuoteEntity.swift
//  InnerLamp
//

import Foundation

/// One quoted verse from a sutra (e.g. a verse of the Dhammapada), shown as the daily quote.
///
/// Pure business data. The bundled catalog (`Resources/Data/sutra_quotes_300.json`) is seeded into
/// Core Data on first launch; the wire/storage shapes never leave the Data layer.
struct ILSutraQuoteEntity: Equatable, Identifiable {
    /// Stable 1-based sequence number from the catalog (`stt`). Also defines the quote order used by
    /// the day-of-year rotation in `ILSutraQuoteUseCase`.
    let id: Int
    /// Sutra title, e.g. "Kinh Pháp Cú (Dhammapada)".
    let sutraName: String
    /// Translator credit, e.g. "Hòa thượng Thích Minh Châu".
    let translator: String
    /// Chapter number as written in the source (Roman numerals, e.g. "I").
    let chapterNumber: String
    /// Chapter title, e.g. "Phẩm Song Yếu".
    let chapterName: String
    /// Verse number within the sutra.
    let verseNumber: Int
    /// The verse text itself.
    let content: String
}
