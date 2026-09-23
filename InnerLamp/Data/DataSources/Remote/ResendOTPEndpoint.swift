//
//  ResendOTPEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `POST /v1/auth/resend-otp`.
///
/// Shared endpoint on the backend (`purpose` selects the flow); the OTP feature only ever sends
/// `purpose = "register"`. Public — see `VerifyRegistrationOTPEndpoint` for the shared placement
/// and header notes.
nonisolated struct ResendOTPEndpoint: Endpoint {
    let request: ILOtpResendRequestDTO

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/auth/resend-otp" }
    var method: HTTPMethod { .post }
    var requiresAuth: Bool { false }

    var body: Data? {
        try? JSONEncoder().encode(request)
    }
}
