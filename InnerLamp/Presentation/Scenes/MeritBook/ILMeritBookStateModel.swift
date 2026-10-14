//
//  ILMeritBookStateModel.swift
//  InnerLamp
//

import Foundation

/// UI-only state of the "Sổ công đức" screen: already-formatted strings, no UIKit import.
struct ILMeritBookStateModel: Equatable {

    struct Stat: Equatable {
        let value: String
        let caption: String
    }

    struct HistoryRow: Equatable, Identifiable {
        let id: String
        let title: String
        /// "<temple> · <dd/MM/yyyy>"
        let subtitle: String
        let amount: String
        let statusText: String
        let isConfirmed: Bool
    }

    struct Letter: Equatable {
        let body: String
        let signature: String
    }

    struct Monthly: Equatable {
        let title: String
        let subtitle: String
    }

    struct BuildProject: Equatable {
        struct Line: Equatable {
            let label: String
            let value: String
        }

        let name: String
        let subtitle: String
        /// 0...1
        let progress: Double
        let progressLine: String
        let percentText: String
        let lines: [Line]
        let updatedText: String
    }

    var stats: [Stat] = []
    var history: [HistoryRow] = []
    var letter: Letter?
    /// `nil` = monthly support is off (the screen shows the "not enabled" note).
    var monthly: Monthly?
    var buildProject: BuildProject?
}
