//
//  ILAddTempleUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILAddTempleUseCaseTests: XCTestCase {

    private let sut = ILAddTempleUseCaseImpl()
    private let existing = [
        ILOrdinationPlaceEntity(id: "t1", name: "Chùa Từ Quang", subtitle: "12 Lê Lợi, TP. Hồ Chí Minh")
    ]

    func test_validate_emptyName_returnsNameRequired() {
        XCTAssertEqual(sut.validate(name: "  ", province: "Hà Nội", existing: []), .nameRequired)
    }

    func test_validate_emptyProvince_returnsProvinceRequired() {
        XCTAssertEqual(sut.validate(name: "Pháp Hoa", province: " ", existing: []), .provinceRequired)
    }

    func test_validate_sameNameAndProvinceIgnoringPrefixAndDiacritics_returnsDuplicate() {
        let error = sut.validate(name: "tu quang", province: "tp ho chi minh", existing: existing)
        XCTAssertEqual(error, .duplicate("Chùa Từ Quang"))
    }

    func test_validate_sameNameDifferentProvince_isValid() {
        XCTAssertNil(sut.validate(name: "Từ Quang", province: "Hà Nội", existing: existing))
    }

    func test_makeProposal_addsDefaultPrefixOnlyWhenMissing() {
        XCTAssertEqual(sut.makeProposal(name: " Pháp Hoa ", province: "Đà Nẵng", address: "").name, "Chùa Pháp Hoa")
        XCTAssertEqual(sut.makeProposal(name: "Thiền viện Trúc Lâm", province: "Đà Lạt", address: "").name, "Thiền viện Trúc Lâm")
    }
}
