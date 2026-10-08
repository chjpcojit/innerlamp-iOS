//
//  ILCalendarImageRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Server calendar image (`/v1/calendar/image`). Network-only; maps every failure to
/// `ILCatalogError` (the same failure modes as the other server catalogs).
nonisolated final class ILCalendarImageRepositoryImpl: ILCalendarImageRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func loadImage(for date: Date) async throws -> ILCalendarImageEntity {
        do {
            let response = try await networkService.request(
                endpoint: CalendarImageEndpoint(date: ILCalendarImageMapper.dateQueryValue(for: date)),
                responseType: ILCalendarImageDTO.self
            )
            guard let image = ILCalendarImageMapper.toDomain(response) else {
                throw NetworkError.noData
            }
            return image
        } catch {
            throw ILCatalogError.from(error)
        }
    }
}
