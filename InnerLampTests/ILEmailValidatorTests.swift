//
//  ILEmailValidatorTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILEmailValidatorTests: XCTestCase {

    func test_isValid_acceptsWellFormedEmails() {
        XCTAssertTrue(ILEmailValidator.isValid("phapdanh@email.com"))
        XCTAssertTrue(ILEmailValidator.isValid("a.b+c@sub.domain.vn"))
    }

    func test_isValid_trimsSurroundingWhitespace() {
        XCTAssertTrue(ILEmailValidator.isValid("  phapdanh@email.com \n"))
    }

    func test_isValid_rejectsMalformedEmails() {
        XCTAssertFalse(ILEmailValidator.isValid(""))
        XCTAssertFalse(ILEmailValidator.isValid("not-an-email"))
        XCTAssertFalse(ILEmailValidator.isValid("missing@tld"))
        XCTAssertFalse(ILEmailValidator.isValid("two@@email.com"))
        XCTAssertFalse(ILEmailValidator.isValid("space in@email.com"))
        XCTAssertFalse(ILEmailValidator.isValid("short@tld.c"))
    }
}
