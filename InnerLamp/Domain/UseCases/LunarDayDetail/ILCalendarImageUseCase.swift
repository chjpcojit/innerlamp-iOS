//
//  ILCalendarImageUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILCalendarImageUseCase {
    /// The picture of the Gregorian day of `date`, or `nil` — without any request — when its year is
    /// outside the range the server supports. Throws `ILCatalogError` on a failed request.
    func loadImage(for date: Date) async throws -> ILCalendarImageEntity?
}

final class ILCalendarImageUseCaseImpl: ILCalendarImageUseCase {

    /// Years the server accepts (`400 INVALID_DATE` outside it).
    static let supportedYears = 1900...2100

    private let repository: ILCalendarImageRepository
    private let calendar: Calendar

    init(
        repository: ILCalendarImageRepository,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    func loadImage(for date: Date) async throws -> ILCalendarImageEntity? {
        guard Self.supportedYears.contains(calendar.component(.year, from: date)) else { return nil }
        return try await repository.loadImage(for: date)
    }
}
