//
//  ILCalendarEventRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Server event calendar (`/v1/calendar/events`). Network-only; maps every failure to
/// `ILCatalogError` (the same failure modes as the other server catalogs).
nonisolated final class ILCalendarEventRepositoryImpl: ILCalendarEventRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func loadEvents(year: Int) async throws -> ILCalendarEventsEntity {
        do {
            let response = try await networkService.request(
                endpoint: CalendarEventsEndpoint(year: year),
                responseType: ILCalendarEventsDTO.self
            )
            return ILCalendarEventMapper.toDomain(response)
        } catch {
            throw ILCatalogError.from(error)
        }
    }
}
