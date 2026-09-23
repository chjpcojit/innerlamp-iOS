//
//  LocalizationService.swift
//  InnerLamp
//

import Foundation

protocol LocalizationService {
    var currentLanguage: String { get }
    func string(for key: String) -> String
    func syncRemoteIfNeeded() async
}

/// Nguồn dữ liệu ưu tiên: cache đã tải từ server > file mặc định đóng gói trong app.
/// Gọi `syncRemoteIfNeeded()` lúc app khởi động (xem `AppDelegate.bootstrapLocalization`)
/// để kiểm tra version mới — thất bại (mất mạng, server lỗi, decode lỗi) thì im lặng
/// giữ nguyên file đang dùng, không chặn hay làm crash luồng khởi động.
final class LocalizationServiceImpl: LocalizationService {
    static let shared = LocalizationServiceImpl()

    private let networkService: NetworkService
    private let fileStorage: LocalizationFileStorage

    let currentLanguage: String
    private var activeFile: LocalizedStringsFile

    init(
        networkService: NetworkService = NetworkServiceImpl(),
        fileStorage: LocalizationFileStorage = LocalizationFileStorageImpl(),
        language: String = LocalizationConfig.defaultLanguage
    ) {
        self.networkService = networkService
        self.fileStorage = fileStorage
        self.currentLanguage = language
        self.activeFile = fileStorage.loadCached(language: language)
            ?? fileStorage.loadBundled(language: language)
            ?? LocalizedStringsFile(version: "0", language: language, strings: [:])
    }

    func string(for key: String) -> String {
        activeFile.strings[key] ?? key
    }

    func syncRemoteIfNeeded() async {
        do {
            let versionResponse = try await networkService.request(
                endpoint: LocalizationVersionEndpoint(language: currentLanguage),
                responseType: LocalizationVersionResponse.self
            )

            guard versionResponse.version != activeFile.version else { return }

            let remoteFile = try await networkService.request(
                endpoint: LocalizationContentEndpoint(language: currentLanguage),
                responseType: LocalizedStringsFile.self
            )

            try fileStorage.save(remoteFile)
            activeFile = remoteFile
        } catch {
            // Network/decode lỗi → giữ nguyên file cache/bundled đang dùng, không throw tiếp.
        }
    }
}
