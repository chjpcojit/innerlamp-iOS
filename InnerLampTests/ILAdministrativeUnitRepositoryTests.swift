//
//  ILAdministrativeUnitRepositoryTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

/// Routes by `path` + `?q=` and decodes the canned envelope like `NetworkServiceImpl` does.
private final class MockAdministrativeNetworkService: NetworkService {
    var responses: [String: Result<String, NetworkError>] = [:]
    private(set) var requested: [String] = []
    private(set) var requiresAuthValues: [Bool] = []

    func request<T: Decodable & Sendable>(endpoint: Endpoint, responseType: T.Type) async throws -> T {
        let key = endpoint.path + (endpoint.queryParameters?["q"].map { "?q=\($0)" } ?? "")
        requested.append(key)
        requiresAuthValues.append(endpoint.requiresAuth)
        guard let result = responses[key] else { throw NetworkError.noInternetConnection }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let envelope = try decoder.decode(APIEnvelope<T>.self, from: Data(try result.get().utf8))
        guard let data = envelope.data else { throw NetworkError.noData }
        return data
    }

    func request(endpoint: Endpoint) async throws {}
}

final class ILAdministrativeUnitRepositoryTests: XCTestCase {

    private let provincesPath = "/v1/administrative-units/new/provinces"
    private let wardsPath = "/v1/administrative-units/new/provinces/79/wards"

    private let provincesJSON = #"""
    {"success":true,"data":{"items":[
    {"code":"91","name":"An Giang","full_name":"Tỉnh An Giang","type":"province"},
    {"code":"79","name":"Hồ Chí Minh","full_name":"Thành phố Hồ Chí Minh","type":"city"},
    {"code":"00","name":"Lạ","full_name":"Lạ","type":"future_kind"}]}}
    """#

    private let wardsJSON = #"""
    {"success":true,"data":{"items":[
    {"code":"26737","name":"Tân Định","full_name":"Phường Tân Định","type":"ward","province_code":"79"},
    {"code":"26800","name":"Cần Giờ","full_name":"Xã Cần Giờ","type":"commune","province_code":"79"},
    {"code":"26900","name":"Côn Đảo","full_name":"Đặc khu Côn Đảo","type":"special_zone","province_code":"79"}]}}
    """#

    private func makeSUT(_ network: MockAdministrativeNetworkService) -> ILAdministrativeUnitRepositoryImpl {
        ILAdministrativeUnitRepositoryImpl(networkService: network)
    }

    func test_loadProvinces_mapsCodesAsStringsAndKinds() async throws {
        let network = MockAdministrativeNetworkService()
        network.responses[provincesPath] = .success(provincesJSON)

        let provinces = try await makeSUT(network).loadProvinces()

        XCTAssertEqual(provinces.map(\.code), ["91", "79", "00"])
        XCTAssertEqual(provinces[1].name, "Hồ Chí Minh")
        XCTAssertEqual(provinces[1].fullName, "Thành phố Hồ Chí Minh")
        XCTAssertEqual(provinces.map(\.kind), [.province, .city, .other])
        XCTAssertEqual(network.requiresAuthValues, [false])
    }

    func test_loadWards_mapsKindsAndProvinceCode() async throws {
        let network = MockAdministrativeNetworkService()
        network.responses[wardsPath] = .success(wardsJSON)

        let wards = try await makeSUT(network).loadWards(provinceCode: "79", query: nil)

        XCTAssertEqual(wards.map(\.kind), [.ward, .commune, .specialZone])
        XCTAssertEqual(wards.first, ILWardEntity(
            code: "26737", name: "Tân Định", fullName: "Phường Tân Định", kind: .ward, provinceCode: "79"
        ))
        XCTAssertEqual(network.requested, [wardsPath])
    }

    func test_loadWards_blankQuery_isOmitted() async throws {
        let network = MockAdministrativeNetworkService()
        network.responses[wardsPath] = .success(wardsJSON)

        _ = try await makeSUT(network).loadWards(provinceCode: "79", query: "   ")

        XCTAssertEqual(network.requested, [wardsPath])
    }

    func test_loadWards_query_isTrimmedAndSent() async throws {
        let network = MockAdministrativeNetworkService()
        network.responses[wardsPath + "?q=tan dinh"] = .success(#"{"success":true,"data":{"items":[]}}"#)

        let wards = try await makeSUT(network).loadWards(provinceCode: "79", query: "  tan dinh ")

        XCTAssertTrue(wards.isEmpty)
        XCTAssertEqual(network.requested, [wardsPath + "?q=tan dinh"])
    }

    func test_endpoint_longQuery_isCappedAt100() {
        let endpoint = AdministrativeWardsEndpoint(provinceCode: "79", query: String(repeating: "a", count: 150))
        XCTAssertEqual(endpoint.queryParameters?["q"]?.count, AdministrativeWardsEndpoint.maxQueryLength)
    }

    func test_endpoint_provinceCode_isPathEncoded() {
        let endpoint = AdministrativeWardsEndpoint(provinceCode: "7/9?x")
        XCTAssertEqual(endpoint.path, "/v1/administrative-units/new/provinces/7%2F9%3Fx/wards")
    }

    func test_loadWards_unknownProvince_throwsNotFound() async {
        let network = MockAdministrativeNetworkService()
        network.responses[wardsPath] = .failure(
            .apiError(code: "ADMINISTRATIVE_UNIT_NOT_FOUND", message: "m", type: "business", details: nil)
        )

        do {
            _ = try await makeSUT(network).loadWards(provinceCode: "79", query: nil)
            XCTFail("expected notFound")
        } catch let error as ILCatalogError {
            guard case .notFound = error else { return XCTFail("got \(error)") }
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func test_loadProvinces_offline_throwsOffline() async {
        let network = MockAdministrativeNetworkService()

        do {
            _ = try await makeSUT(network).loadProvinces()
            XCTFail("expected offline")
        } catch let error as ILCatalogError {
            guard case .offline = error else { return XCTFail("got \(error)") }
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }
}
