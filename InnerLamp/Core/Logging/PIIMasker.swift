//
//  PIIMasker.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

/// `nonisolated` — thuần hàm, không giữ state, không chạm UI. Cần thiết vì `NetworkLogger`
/// (nonisolated, gọi từ `NetworkServiceImpl` actor) dùng `maskMetadata` ngoài main actor.
nonisolated public final class PIIMasker {
    
    // MARK: - Blocked Keys
    public static let blockedKeys: Set<String> = [
        "pin",
        "password",
        "cvv",
        "token",
        "access_token",
        "refresh_token",
        "card_number",
        "account_number",
        "clabe",
        "curp",
        "rfc",
        "email",
        "phone"
    ]
    
    // MARK: - Regex Patterns
    private static let clabeRegex = try! NSRegularExpression(
        pattern: #"\b\d{18}\b"#,
        options: []
    )
    
    private static let cardRegex = try! NSRegularExpression(
        pattern: #"\b\d{4}[ -]?\d{4}[ -]?\d{4}[ -]?\d{4}\b"#,
        options: []
    )
    
    private static let jwtTokenRegex = try! NSRegularExpression(
        pattern: #"eyJ[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+(?:\.[A-Za-z0-9\-_.+/=]*)?"#,
        options: []
    )
    
    private static let bearerTokenRegex = try! NSRegularExpression(
        pattern: #"(?<=Bearer\s)[A-Za-z0-9\-_.+/=]+"#,
        options: [.caseInsensitive]
    )
    
    private static let mexicanPhoneRegex = try! NSRegularExpression(
        pattern: #"\+52[\s-]?(?:\d{2,3}[\s-]?)?\d{4}[\s-]?\d{4}\b"#,
        options: []
    )
    
    private static let emailRegex = try! NSRegularExpression(
        pattern: #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}\b"#,
        options: []
    )
    
    private static let currencyAmountRegex = try! NSRegularExpression(
        pattern: #"(?<=\$)\s*\d{1,3}(?:,\d{3})*(?:\.\d+)?|\b\$\d+(?:,\d{3})*(?:\.\d+)?"#,
        options: []
    )

    // MARK: - Amount Categorization
    public static func categorizeAmount(_ amount: Decimal) -> String {
        switch amount {
        case ..<500:
            return "tier_1_micro"
        case 500..<5_000:
            return "tier_2_low"
        case 5_000..<50_000:
            return "tier_3_medium"
        default:
            return "tier_4_high"
        }
    }
    
    // MARK: - Free-text Message Masking
    public static func maskMessage(_ message: String) -> String {
        var result = message
        
        // 1. CLABE (18 digits)
        result = replaceMatches(in: result, regex: clabeRegex, with: "[CLABE:****]")
        
        // 2. Card Number (16 digits formatted or raw)
        result = replaceMatches(in: result, regex: cardRegex, with: "[CARD:****]")
        
        // 3. JWT & Bearer Tokens
        result = replaceMatches(in: result, regex: jwtTokenRegex, with: "[TOKEN:****]")
        result = replaceMatches(in: result, regex: bearerTokenRegex, with: "[TOKEN:****]")
        
        // 4. Mexican Phone Numbers
        result = replaceMatches(in: result, regex: mexicanPhoneRegex, with: "[PHONE:****]")
        
        // 5. Emails
        result = replaceMatches(in: result, regex: emailRegex, with: "[EMAIL:****]")
        
        // 6. Currency Amounts ($5,000 -> $[AMOUNT:****])
        result = replaceCurrencyAmount(in: result)
        
        return result
    }
    
    // MARK: - Metadata Masking
    public static func maskMetadata(_ metadata: [String: Any]) -> [String: Any] {
        var sanitized: [String: Any] = [:]
        
        for (key, value) in metadata {
            // Drop key completely if in blocked keys (case-insensitive)
            if blockedKeys.contains(key.lowercased()) {
                continue
            }
            
            sanitized[key] = sanitizeValue(value)
        }
        
        return sanitized
    }
    
    // MARK: - Helper Methods
    private static func sanitizeValue(_ value: Any) -> Any {
        if let stringValue = value as? String {
            return maskMessage(stringValue)
        } else if let nestedDict = value as? [String: Any] {
            return maskMetadata(nestedDict)
        } else if let arrayValue = value as? [Any] {
            return arrayValue.map { sanitizeValue($0) }
        } else {
            return value
        }
    }
    
    private static func replaceMatches(
        in text: String,
        regex: NSRegularExpression,
        with template: String
    ) -> String {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
            withTemplate: template
        )
    }
    
    private static func replaceCurrencyAmount(in text: String) -> String {
        let pattern = #"\$(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
            withTemplate: "\\$[AMOUNT:****]"
        )
    }
}
