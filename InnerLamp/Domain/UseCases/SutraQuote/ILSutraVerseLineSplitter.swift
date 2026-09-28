//
//  ILSutraVerseLineSplitter.swift
//  InnerLamp
//

import Foundation

/// Splits a flat verse string from the sutra catalog back into its poetic lines.
///
/// The catalog stores every verse as one line of text with no line breaks
/// (e.g. "Với hận diệt hận thù, Ðời này không có được. Không hận diệt hận thù, Là định luật ngàn thu"),
/// but the verses are 4 lines of 5 syllables each (ngũ ngôn). Punctuation alone is unreliable
/// (commas appear mid-line, some line ends have none) and so is capitalization (proper nouns such as
/// "Niết-Bàn" or "Bà-la-môn" are capitalized mid-line, some verses never capitalize line starts).
///
/// The splitter therefore picks the break points that minimize a cost combining:
/// - distance of each line's syllable count from `syllablesPerLine` (a hyphenated word such as
///   "Bà-la-môn" counts one syllable per part),
/// - a small bonus for breaking after punctuation and before a capitalized word.
///
/// Pure function, no Foundation state — safe to call from any layer.
// @ai: keep ILSutraVerseLineSplitterTests in sync when tuning the weights below.
enum ILSutraVerseLineSplitter {

    private static let syllableMismatchWeight = 2
    private static let punctuationBonus = 1
    private static let capitalBonus = 1
    private static let lineEndPunctuation: Set<Character> = [",", ".", ";", ":", "!", "?"]

    /// Returns `text` split into exactly `lineCount` lines, or `[text]` (trimmed) when it has fewer
    /// words than `lineCount`. Returns `[]` for blank text.
    static func lines(
        from text: String,
        lineCount: Int = 4,
        syllablesPerLine: Int = 5
    ) -> [String] {
        let words = text.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return [] }
        guard lineCount > 1, words.count > lineCount else {
            return words.count == lineCount ? words : [words.joined(separator: " ")]
        }

        let syllables = words.map { word in max(1, word.split(separator: "-").count) }
        // prefix[i] = syllables of words[0..<i]
        var prefix = [0]
        for count in syllables { prefix.append(prefix[prefix.count - 1] + count) }

        // Cost of placing a break before word `index` (1..<words.count).
        func breakCost(before index: Int) -> Int {
            var cost = 0
            if let last = words[index - 1].last, lineEndPunctuation.contains(last) { cost -= punctuationBonus }
            if words[index].first?.isUppercase == true { cost -= capitalBonus }
            return cost
        }

        func lineCost(from start: Int, to end: Int) -> Int {
            abs(prefix[end] - prefix[start] - syllablesPerLine) * syllableMismatchWeight
        }

        // best[l][e]: minimal cost to split words[0..<e] into `l` lines; `from[l][e]` is the start
        // of the last of those lines.
        let wordCount = words.count
        let unreachable = Int.max / 2
        var best = Array(repeating: Array(repeating: unreachable, count: wordCount + 1), count: lineCount + 1)
        var from = Array(repeating: Array(repeating: 0, count: wordCount + 1), count: lineCount + 1)
        best[0][0] = 0

        for line in 1...lineCount {
            for end in line...wordCount {
                for start in (line - 1)..<end where best[line - 1][start] < unreachable {
                    let joinCost = start == 0 ? 0 : breakCost(before: start)
                    let cost = best[line - 1][start] + joinCost + lineCost(from: start, to: end)
                    if cost < best[line][end] {
                        best[line][end] = cost
                        from[line][end] = start
                    }
                }
            }
        }

        var result: [String] = []
        var end = wordCount
        for line in stride(from: lineCount, through: 1, by: -1) {
            let start = from[line][end]
            result.append(words[start..<end].joined(separator: " "))
            end = start
        }
        return result.reversed()
    }
}
