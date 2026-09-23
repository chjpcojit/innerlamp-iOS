//
//  ILEmailValidator.swift
//  InnerLamp
//

import Foundation

/// Single source of truth for the email format rule — Domain layer, Foundation only. Shared by
/// `ILSignUpUseCaseImpl.validateEmail` (submit-time) and `ILSignUpStateModel.isEmailFormatValid`
/// (live border feedback while typing) so the two can never drift apart.
enum ILEmailValidator {
    private static let pattern = "^[^\\s@]+@[^\\s@]+\\.[^\\s@]{2,}$"

    /// Trims surrounding whitespace first, so `" a@b.co "` is valid.
    static func isValid(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .range(of: pattern, options: .regularExpression) != nil
    }
}
