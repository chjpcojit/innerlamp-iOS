//
//  ResendOTPEndpoint.swift
//  InnerLamp
//

import Foundation

/// One server call — `POST /v1/auth/register/resend-otp`.
///
/// EN: Registration-only resend, body `{email}`. Public
/// VI: Gửi lại mã cho riêng đăng ký, body `{email}`. Public — see `VerifyRegistrationOTPEndpoint` for the shared placement
/// and header notes.
nonisolated struct ResendOTPEndpoint: Endpoint {
    let request: ILOtpResendRequestDTO

    var baseURL: String { APIConfig.serverBaseURL }
    // EN: Contract 3.0.0 path; the old `/v1/auth/resend-otp` (phone + purpose) was removed.
    // VI: Path của contract 3.0.0; route cũ `/v1/auth/resend-otp` (phone + purpose) đã bị bỏ.
    var path: String { "/v1/auth/register/resend-otp" }
    var method: HTTPMethod { .post }
    var requiresAuth: Bool { false }

    var body: Data? {
        try? JSONEncoder().encode(request)
    }
}
