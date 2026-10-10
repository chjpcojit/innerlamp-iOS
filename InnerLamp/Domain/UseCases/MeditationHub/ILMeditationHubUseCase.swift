//
//  ILMeditationHubUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILMeditationHubUseCase {
    func getInitialState() -> ILMeditationHubEntity

    /// Tải 1 bài thiền dẫn về máy. Việc thật cần network + lưu trữ cục bộ nên thuộc ngoài phạm vi
    /// của ui-builder — giữ nguyên chữ ký, thân hàm là 1 dòng TODO.
    /// Xem `references/data_layer_boundaries.md`.
    func downloadGuidedMeditation(id: String) async throws
}

final class ILMeditationHubUseCaseImpl: ILMeditationHubUseCase {

    // Không có dependency ngoài: dữ liệu hiện tại là danh mục mẫu trong bộ nhớ. Khi có API danh mục
    // thiền/danh sách bài thiền dẫn thật mới thêm `ILMeditationHubRepository`.
    init() {}

    func getInitialState() -> ILMeditationHubEntity {
        // TODO: thay danh mục mẫu dưới đây bằng ILMeditationHubRepository → networkService khi API
        // thiền chuông / thiền dẫn được xác nhận (xem `references/data_layer_boundaries.md`).
        ILMeditationHubEntity(
            streakDays: 7,
            weeklyMinutes: 94,
            dailyMinutes: Self.makeMockDailyMinutes(),
            presets: [
                ILMeditationHubPresetEntity(
                    id: "preset.morning",
                    name: "meditationHub.preset.morning.name".localized,
                    minutes: 15,
                    subtitle: "meditationHub.preset.morning.subtitle".localized
                ),
                ILMeditationHubPresetEntity(
                    id: "preset.release",
                    name: "meditationHub.preset.release.name".localized,
                    minutes: 30,
                    subtitle: "meditationHub.preset.release.subtitle".localized
                ),
                ILMeditationHubPresetEntity(
                    id: "preset.sitting",
                    name: "meditationHub.preset.sitting.name".localized,
                    minutes: 45,
                    subtitle: "meditationHub.preset.sitting.subtitle".localized
                )
            ],
            guidedSessions: [
                ILMeditationHubGuidedEntity(
                    id: "guided.breath",
                    method: "meditationHub.guided.breath.method".localized,
                    name: "meditationHub.guided.breath.name".localized,
                    teacher: "meditationHub.guided.breath.teacher".localized,
                    minutes: 12,
                    summary: "meditationHub.guided.breath.summary".localized,
                    isDownloaded: true
                ),
                ILMeditationHubGuidedEntity(
                    id: "guided.relax",
                    method: "meditationHub.guided.relax.method".localized,
                    name: "meditationHub.guided.relax.name".localized,
                    teacher: "meditationHub.guided.relax.teacher".localized,
                    minutes: 20,
                    summary: "meditationHub.guided.relax.summary".localized,
                    isDownloaded: false
                ),
                ILMeditationHubGuidedEntity(
                    id: "guided.metta",
                    method: "meditationHub.guided.metta.method".localized,
                    name: "meditationHub.guided.metta.name".localized,
                    teacher: "meditationHub.guided.metta.teacher".localized,
                    minutes: 15,
                    summary: "meditationHub.guided.metta.summary".localized,
                    isDownloaded: false
                ),
                ILMeditationHubGuidedEntity(
                    id: "guided.bodyscan",
                    method: "meditationHub.guided.bodyscan.method".localized,
                    name: "meditationHub.guided.bodyscan.name".localized,
                    teacher: "meditationHub.guided.bodyscan.teacher".localized,
                    minutes: 10,
                    summary: "meditationHub.guided.bodyscan.summary".localized,
                    isDownloaded: false
                )
            ]
        )
    }

    func downloadGuidedMeditation(id: String) async throws {
        print("TODO: implement downloadGuidedMeditation — network/repository call, not built by ui-builder")
    }

    /// Mock 84 ngày (12 tuần × 7 ngày) theo cùng công thức giả lập của prototype, xếp theo hàng để
    /// khớp `ILHeatmapGridView(columns: 12)`. Thay bằng dữ liệu thật khi có Repository.
    private static func makeMockDailyMinutes() -> [Int] {
        (0..<84).map { index in
            let seed = (index * 37 + 11) % 10
            if seed > 6 { return 30 }
            if seed > 3 { return 15 }
            return 0
        }
    }
}
