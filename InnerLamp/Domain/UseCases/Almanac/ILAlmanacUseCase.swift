//
//  ILAlmanacUseCase.swift
//  InnerLamp
//

import Foundation

/// Thin orchestration over `ILLunarCalendar`'s almanac computation plus the stored birth profile.
///
/// All real computation lives in `ILLunarCalendar` (pure, offline). This type only builds the
/// `ILUserBirthProfileEntity` from a birth date and hands its birth date (or `nil`) into the unified
/// `ILLunarCalendar.almanac(...)` — so a `nil` profile falls back to the general day evaluation.
protocol ILAlmanacUseCase {
    /// Derives a `ILUserBirthProfileEntity` from a solar birth date (called once when the user enters
    /// their birthday). The result is what `ILUserBirthProfileRepository` persists.
    func makeBirthProfile(solarBirthDate: Date) -> ILUserBirthProfileEntity

    /// Computes the full daily almanac for a target date. When `profile` is provided the Hung/Cát
    /// fields are personalized against it; when `nil` they are the general day evaluation
    /// (Hoàng đạo/Hắc đạo + Trực only). Pure computation — no network/disk I/O.
    func calculateDailyAlmanac(for date: Date, profile: ILUserBirthProfileEntity?) -> ILLunarCalendar.AlmanacResult
}

final class ILAlmanacUseCaseImpl: ILAlmanacUseCase {

    func makeBirthProfile(solarBirthDate: Date) -> ILUserBirthProfileEntity {
        let calendar = Calendar(identifier: .gregorian)
        let comps = calendar.dateComponents([.day, .month, .year], from: solarBirthDate)
        let lunar = ILLunarCalendar.solarToLunar(
            day: comps.day ?? 1,
            month: comps.month ?? 1,
            year: comps.year ?? 2000
        )

        // Year Can-Chi: `can = (lunarYear + 6) % 10`, `chi = (lunarYear + 8) % 12` (same formula as
        // `ILLunarCalendar.canChiYear`). Nạp Âm element is derived from the year Can-Chi.
        let can = ((lunar.year + 6) % 10 + 10) % 10
        let chi = ((lunar.year + 8) % 12 + 12) % 12

        return ILUserBirthProfileEntity(
            solarBirthDate: solarBirthDate,
            lunarYear: lunar.year,
            canIndex: can,
            chiIndex: chi,
            element: ILLunarCalendar.napAmElement(can: can, chi: chi)
        )
    }

    func calculateDailyAlmanac(for date: Date, profile: ILUserBirthProfileEntity?) -> ILLunarCalendar.AlmanacResult {
        ILLunarCalendar.almanac(date: date, birthDate: profile?.solarBirthDate)
    }
}
