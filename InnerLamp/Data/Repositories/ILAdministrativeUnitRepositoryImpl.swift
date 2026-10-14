//
//  ILAdministrativeUnitRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Network-only reader of `/v1/administrative-units/new/*`; maps every failure to
/// `ILCatalogError`. Caching is the system HTTP cache (see `ILAdministrativeUnitRepository`).
nonisolated final class ILAdministrativeUnitRepositoryImpl: ILAdministrativeUnitRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func loadProvinces() async throws -> [ILProvinceEntity] {
        do {
            let response = try await networkService.request(
                endpoint: AdministrativeProvincesEndpoint(),
                responseType: ILAdministrativeUnitListDTO<ILProvinceDTO>.self
            )
            return response.items.map(ILAdministrativeUnitMapper.toDomain)
        } catch {
            throw ILCatalogError.from(error)
        }
    }

    func loadWards(provinceCode: String, query: String?) async throws -> [ILWardEntity] {
        do {
            let response = try await networkService.request(
                endpoint: AdministrativeWardsEndpoint(provinceCode: provinceCode, query: query),
                responseType: ILAdministrativeUnitListDTO<ILWardDTO>.self
            )
            return response.items.map(ILAdministrativeUnitMapper.toDomain)
        } catch {
            throw ILCatalogError.from(error)
        }
    }
}
