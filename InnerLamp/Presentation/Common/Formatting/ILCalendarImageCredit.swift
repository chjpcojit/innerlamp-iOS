//
//  ILCalendarImageCredit.swift
//  InnerLamp
//

import Foundation

extension ILCalendarImageEntity {
    /// "Ảnh: Judgefloro · Public domain" — author and license are both required by CC BY / CC BY-SA;
    /// a missing half is dropped rather than printed blank, and no credit at all yields "".
    var creditText: String {
        switch (author.isEmpty, license.isEmpty) {
        case (false, false):
            return String(format: "lunarDayDetail.hero.imageCreditFormat".localized, author, license)
        case (false, true):
            return String(format: "lunarDayDetail.hero.imageCreditSingleFormat".localized, author)
        case (true, false):
            return String(format: "lunarDayDetail.hero.imageCreditSingleFormat".localized, license)
        case (true, true):
            return ""
        }
    }
}
