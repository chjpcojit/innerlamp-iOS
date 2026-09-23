//
//  PIIMaskerTests.swift
//  InnerLampTests
//
//  Created by Antigravity on 12/9/26.
//

import XCTest
@testable import InnerLamp

/// CI gate bắt buộc — xem "Test Suite" trong Mobile Logging Architecture.md.
/// Nếu bất kỳ test nào fail, build phải fail. Khi thêm format PII mới, thêm test case
/// ở đây trước khi thêm regex.
final class PIIMaskerTests: XCTestCase {

    // MARK: - CLABE (18 chữ số)

    func test_mask_clabe_standalone() {
        let input = "Transfer to 002010077777777771 completed"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("002010077777777771"))
        XCTAssertTrue(output.contains("[CLABE:****]"))
    }

    func test_mask_clabe_embedded_in_sentence() {
        let input = "Recipient CLABE is 002010077777777771, please confirm"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("002010077777777771"))
    }

    // MARK: - Card Number

    func test_mask_card_with_spaces() {
        let input = "Card 4111 1111 1111 1111 declined"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("4111"))
        XCTAssertTrue(output.contains("[CARD:****]"))
    }

    func test_mask_card_with_dashes() {
        let input = "Card 4111-1111-1111-1111 declined"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("4111-1111"))
    }

    func test_mask_card_no_separator() {
        let input = "Card 4111111111111111 approved"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("4111111111111111"))
    }

    // MARK: - Token

    func test_mask_bearer_token() {
        let input = "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("eyJhbGci"))
        XCTAssertTrue(output.contains("[TOKEN:****]"))
    }

    func test_mask_token_in_json_string() {
        let input = #"{"access_token": "eyJhbGciOiJSUzI1NiJ9.payload"}"#
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("eyJhbGci"))
    }

    // MARK: - Phone (México)

    func test_mask_mexican_phone() {
        let input = "User phone: +52 55 1234 5678"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("1234 5678"))
        XCTAssertTrue(output.contains("[PHONE:****]"))
    }

    // MARK: - Email

    func test_mask_email() {
        let input = "Confirmation sent to usuario@gmail.com"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("usuario@gmail.com"))
        XCTAssertTrue(output.contains("[EMAIL:****]"))
    }

    // MARK: - Metadata (blocked keys)

    func test_blocked_key_pin_is_dropped() {
        let input: [String: Any] = ["pin": "1234", "screen": "transfer"]
        let output = PIIMasker.maskMetadata(input)
        XCTAssertNil(output["pin"])
        XCTAssertEqual(output["screen"] as? String, "transfer")
    }

    func test_blocked_key_token_is_dropped() {
        let input: [String: Any] = ["access_token": "eyJhbGci...", "attempt": "1"]
        let output = PIIMasker.maskMetadata(input)
        XCTAssertNil(output["access_token"])
        XCTAssertNotNil(output["attempt"])
    }

    func test_nested_metadata_is_recursively_masked() {
        let input: [String: Any] = [
            "context": ["clabe": "002010077777777771", "type": "checking"]
        ]
        let output = PIIMasker.maskMetadata(input)
        let nested = output["context"] as? [String: Any]
        XCTAssertNil(nested?["clabe"])
        XCTAssertEqual(nested?["type"] as? String, "checking")
    }

    // MARK: - Safe content không bị ảnh hưởng

    func test_safe_string_passes_through_unchanged() {
        let input = "User tapped confirm button on transfer screen"
        let output = PIIMasker.maskMessage(input)
        XCTAssertEqual(input, output)
    }

    func test_amount_tier_categorization() {
        XCTAssertEqual(PIIMasker.categorizeAmount(100), "tier_1_micro")
        XCTAssertEqual(PIIMasker.categorizeAmount(1_000), "tier_2_low")
        XCTAssertEqual(PIIMasker.categorizeAmount(10_000), "tier_3_medium")
        XCTAssertEqual(PIIMasker.categorizeAmount(100_000), "tier_4_high")
    }
}
