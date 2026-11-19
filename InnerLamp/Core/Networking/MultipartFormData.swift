//
//  MultipartFormData.swift
//  InnerLamp
//

import Foundation

/// A ready-to-send `multipart/form-data` body. One file part is all the memorial photo route
/// accepts (contract §3.6: "exactly one part named `photo`"), and the type is deliberately that
/// narrow — no generic field list to misuse.
nonisolated struct MultipartFormData: Equatable {

    let boundary: String
    let body: Data

    var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    /// - Parameters:
    ///   - field: the part name the server reads (`photo`).
    ///   - filename: any name; the server sniffs the bytes, not the filename.
    static func singleFile(
        field: String,
        filename: String,
        mimeType: String,
        fileData: Data,
        boundary: String = "InnerLamp-\(UUID().uuidString)"
    ) -> MultipartFormData {
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(field)\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n")
        return MultipartFormData(boundary: boundary, body: body)
    }
}

/// Transport for a `multipart/form-data` request that keeps the shared `NetworkService` behaviour:
/// Bearer injection, one 401 refresh, envelope decoding, `error.code` mapping, and PII-free logging.
///
/// Separate from `NetworkService` on purpose: adding a method to that protocol would force every
/// existing mock in the test target to implement it (I3 risk in the task breakdown).
nonisolated protocol MultipartUploading {
    func upload<T: Decodable & Sendable>(
        endpoint: Endpoint,
        form: MultipartFormData,
        responseType: T.Type
    ) async throws -> T
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
