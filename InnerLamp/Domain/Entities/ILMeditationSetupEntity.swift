//
//  ILMeditationSetupEntity.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation

/// Pure business entity for the "Chuẩn bị thiền" screen (design handoff `setup`) — Domain layer only.
///
/// Holds only fields with real business meaning: the available session durations and the currently
/// selected one. It must NOT contain UI-only fields (`*Error`, `isSubmitting`, localized labels,
/// display formatting) — those live in `ILMeditationSetupStateModel`
/// (`Presentation/Scenes/MeditationSetup/`) instead. See `references/data_layer_boundaries.md`.
struct ILMeditationSetupEntity: Equatable {
    /// Các mức thời lượng thiền khả dụng (phút) — catalog tĩnh hiện tại, sau này có thể lấy từ
    /// nội dung/pháp thoại thực.
    var durationOptions: [Int] = [5, 12, 20, 30, 45]

    /// Thời lượng đang chọn (phút) — luôn là một giá trị nằm trong `durationOptions`.
    var durationMinutes: Int = 20

    static let empty = ILMeditationSetupEntity()
}
