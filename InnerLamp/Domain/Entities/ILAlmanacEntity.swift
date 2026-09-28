//
//  ILAlmanacEntity.swift
//  InnerLamp
//

import Foundation

/// A user's birth profile for personalized day selection (Trạch Cát). Pure business data: the birth
/// date plus the derived lunar year, year Can-Chi indices, and the year's Nạp Âm element (mệnh).
///
/// `canIndex`/`chiIndex` are the birth **year** Can-Chi (the "tuổi" animal/element), matching the
/// comparison of the day's Địa Chi against the user's age branch in
/// `ILLunarCalendar.personalEvaluation`. The element type (`ILFiveElements`) and the day-computation
/// result (`ILLunarCalendar.AlmanacResult`) live in `Core/Utils/ILLunarCalendar.swift`.
struct ILUserBirthProfileEntity: Equatable {
    let solarBirthDate: Date
    let lunarYear: Int
    let canIndex: Int
    let chiIndex: Int
    let element: ILFiveElements
}
