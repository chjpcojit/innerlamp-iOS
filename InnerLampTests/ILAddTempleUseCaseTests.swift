//
//  ILAddTempleUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILAddTempleUseCaseTests: XCTestCase {

    private let sut = ILAddTempleUseCaseImpl(administrativeUnitRepository: StubAdministrativeUnitRepository())
    private let existing = [
        ILOrdinationPlaceEntity(id: "t1", name: "Chùa Từ Quang", subtitle: "12 Lê Lợi, TP. Hồ Chí Minh")
    ]

    func test_validate_emptyName_returnsNameRequired() {
        XCTAssertEqual(sut.validate(name: "  ", province: "Hà Nội", ward: "Phường Ba Đình", existing: []), .nameRequired)
    }

    func test_validate_emptyProvince_returnsProvinceRequired() {
        XCTAssertEqual(sut.validate(name: "Pháp Hoa", province: " ", ward: "Phường 1", existing: []), .provinceRequired)
    }

    func test_validate_emptyWard_returnsWardRequired() {
        XCTAssertEqual(
            sut.validate(name: "Pháp Hoa", province: "Hà Nội", ward: " ", existing: []),
            .wardRequired
        )
    }

    func test_loadProvinces_returnsRepositoryProvinces() async throws {
        let provinces = try await sut.loadProvinces()
        XCTAssertEqual(provinces.map(\.code), ["46"])
    }

    func test_loadWards_forwardsProvinceCodeToRepository() async throws {
        let wards = try await sut.loadWards(provinceCode: "46")
        XCTAssertEqual(wards.map(\.provinceCode), ["46"])
        XCTAssertEqual(wards.map(\.fullName), ["Phường Thuận Hóa"])
    }

    func test_makeProposal_keepsTrimmedWard() {
        XCTAssertEqual(sut.makeProposal(name: "Pháp Hoa", province: "Hà Nội", ward: " Phường Ba Đình ", address: "").ward, "Phường Ba Đình")
    }

    func test_validate_sameNameAndProvinceIgnoringPrefixAndDiacritics_returnsDuplicate() {
        let error = sut.validate(name: "tu quang", province: "tp ho chi minh", ward: "Phường Sài Gòn", existing: existing)
        XCTAssertEqual(error, .duplicate("Chùa Từ Quang"))
    }

    func test_validate_sameNameDifferentProvince_isValid() {
        XCTAssertNil(sut.validate(name: "Từ Quang", province: "Hà Nội", ward: "Phường Ba Đình", existing: existing))
    }

    func test_makeProposal_addsDefaultPrefixOnlyWhenMissing() {
        XCTAssertEqual(sut.makeProposal(name: " Pháp Hoa ", province: "Đà Nẵng", ward: "Phường Hải Châu", address: "").name, "Chùa Pháp Hoa")
        XCTAssertEqual(sut.makeProposal(name: "Thiền viện Trúc Lâm", province: "Lâm Đồng", ward: "Phường 1", address: "").name, "Thiền viện Trúc Lâm")
    }
}

private struct StubAdministrativeUnitRepository: ILAdministrativeUnitRepository {
    func loadProvinces() async throws -> [ILProvinceEntity] {
        [ILProvinceEntity(code: "46", name: "Huế", fullName: "Thành phố Huế", kind: .city)]
    }

    func loadWards(provinceCode: String, query: String?) async throws -> [ILWardEntity] {
        [ILWardEntity(code: "1", name: "Thuận Hóa", fullName: "Phường Thuận Hóa", kind: .ward, provinceCode: provinceCode)]
    }
}
