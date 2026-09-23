//
//  LocalizationFileStorage.swift
//  InnerLamp
//

import Foundation

protocol LocalizationFileStorage {
    /// File mặc định đóng gói sẵn trong app bundle — luôn tồn tại, dùng khi
    /// chưa từng tải bản nào từ server hoặc khi tải thất bại.
    func loadBundled(language: String) -> LocalizedStringsFile?

    /// File đã tải từ server ở lần chạy trước — lưu lại để dùng ngay từ lúc mở
    /// app kế tiếp mà không cần chờ mạng.
    func loadCached(language: String) -> LocalizedStringsFile?

    func save(_ file: LocalizedStringsFile) throws
}

final class LocalizationFileStorageImpl: LocalizationFileStorage {

    private let bundle: Bundle
    private let fileManager: FileManager
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(bundle: Bundle = .main, fileManager: FileManager = .default) {
        self.bundle = bundle
        self.fileManager = fileManager
    }

    func loadBundled(language: String) -> LocalizedStringsFile? {
        guard let url = bundledURL(language: language),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? decoder.decode(LocalizedStringsFile.self, from: data)
    }

    func loadCached(language: String) -> LocalizedStringsFile? {
        guard let url = cachedFileURL(language: language),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? decoder.decode(LocalizedStringsFile.self, from: data)
    }

    func save(_ file: LocalizedStringsFile) throws {
        guard let url = cachedFileURL(language: file.language) else {
            throw CocoaError(.fileNoSuchFile)
        }
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try encoder.encode(file)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Private

    /// Xcode file-system-synchronized group có thể giữ nguyên cấu trúc thư mục hoặc
    /// làm phẳng resource lúc build — thử vài khả năng thay vì phụ thuộc 1 hành vi
    /// build cụ thể, cuối cùng quét toàn bộ .json trong bundle theo tên file.
    private func bundledURL(language: String) -> URL? {
        let filename = "\(language).json"
        if let url = bundle.url(forResource: language, withExtension: "json", subdirectory: "Resources/Localization") {
            return url
        }
        if let url = bundle.url(forResource: language, withExtension: "json", subdirectory: "Localization") {
            return url
        }
        if let url = bundle.url(forResource: language, withExtension: "json") {
            return url
        }
        return bundle.urls(forResourcesWithExtension: "json", subdirectory: nil)?
            .first { $0.lastPathComponent == filename }
    }

    private func cachedFileURL(language: String) -> URL? {
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return appSupport.appendingPathComponent("Localization/\(language).json")
    }
}
