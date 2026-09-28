//
//  ILSutraVerseLineSplitterTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILSutraVerseLineSplitterTests: XCTestCase {

    func test_splitsAtPunctuationAndCapitals() {
        let lines = ILSutraVerseLineSplitter.lines(
            from: "Với hận diệt hận thù, Ðời này không có được. Không hận diệt hận thù, Là định luật ngàn thu"
        )

        XCTAssertEqual(lines, [
            "Với hận diệt hận thù,",
            "Ðời này không có được.",
            "Không hận diệt hận thù,",
            "Là định luật ngàn thu"
        ])
    }

    func test_ignoresMidLineCommas_bySyllableCount() {
        let lines = ILSutraVerseLineSplitter.lines(
            from: "Người khác không hiểu biết, Chúng ta đây bị hại. Chỗ ấy, ai biết được Tranh luận được lắng êm."
        )

        XCTAssertEqual(lines, [
            "Người khác không hiểu biết,",
            "Chúng ta đây bị hại.",
            "Chỗ ấy, ai biết được",
            "Tranh luận được lắng êm."
        ])
    }

    func test_splitsLowercaseVerse_bySyllableCount() {
        let lines = ILSutraVerseLineSplitter.lines(
            from: "Ai mặc áo cà sa, tâm chưa rời uế trược, không tự chế, không thực, không xứng áo cà sa"
        )

        XCTAssertEqual(lines, [
            "Ai mặc áo cà sa,",
            "tâm chưa rời uế trược,",
            "không tự chế, không thực,",
            "không xứng áo cà sa"
        ])
    }

    func test_countsHyphenatedWordAsMultipleSyllables() {
        let lines = ILSutraVerseLineSplitter.lines(
            from: "Tự cắt giây ái dục, Như tay bẻ sen thu, Hãy tu đạo tịch tịnh, Niết-Bàn, Thiện Thệ dạy."
        )

        XCTAssertEqual(lines, [
            "Tự cắt giây ái dục,",
            "Như tay bẻ sen thu,",
            "Hãy tu đạo tịch tịnh,",
            "Niết-Bàn, Thiện Thệ dạy."
        ])
    }

    func test_returnsSingleLine_whenFewerWordsThanLines() {
        XCTAssertEqual(ILSutraVerseLineSplitter.lines(from: "  Ba chữ thôi  "), ["Ba chữ thôi"])
    }

    func test_returnsEmpty_forBlankText() {
        XCTAssertEqual(ILSutraVerseLineSplitter.lines(from: "   "), [])
    }

    /// Every verse in the bundled catalog must come back as 4 non-empty lines that rejoin to the
    /// original text.
    func test_bundledCatalog_everyVerseSplitsIntoFourLines() throws {
        let url = try XCTUnwrap(Bundle(for: ILHomeUseCaseImpl.self).url(forResource: "sutra_quotes_300", withExtension: "json"))
        let quotes = try JSONDecoder().decode([ILSutraQuoteDTO].self, from: Data(contentsOf: url))
        XCTAssertFalse(quotes.isEmpty)

        for quote in quotes {
            let lines = ILSutraVerseLineSplitter.lines(from: quote.noiDung)
            XCTAssertEqual(lines.count, 4, "stt \(quote.stt)")
            XCTAssertFalse(lines.contains(where: \.isEmpty), "stt \(quote.stt)")
            XCTAssertEqual(
                lines.joined(separator: " "),
                quote.noiDung.split(whereSeparator: \.isWhitespace).joined(separator: " "),
                "stt \(quote.stt)"
            )
        }
    }
}
