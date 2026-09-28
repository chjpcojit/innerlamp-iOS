//
//  ILTalkEntity.swift
//  InnerLamp
//
//  Created by ChjpCoj on 27/9/26.
//

import Foundation

/// 1 mốc trong danh sách "Các phần" của màn Pháp thoại — chỉ dữ liệu nghiệp vụ: vị trí seek
/// (giây) + tiêu đề phần. Chuỗi định dạng ("00:00") là UI state, nằm trên `ILTalkStateModel`.
struct ILTalkChapterEntity: Equatable, Identifiable {
    let id: String
    /// Vị trí seek (giây) — business, chưa format.
    let timestampSeconds: Int
    let title: String
}

/// 1 bài pháp thoại trong catalog — khớp `talk` trong design handoff.
struct ILTalkTrackEntity: Equatable, Identifiable {
    let id: String
    let eyebrow: String
    let title: String
    let narrator: String
    /// Chữ cái hiển thị trong avatar (vd. "Đ" — dữ liệu mock, chưa phải tên viết tắt thật).
    let narratorInitial: String
    let durationMinutes: Int
    /// Số lượt nghe thô (business) — format "2.4k" là việc của ViewModel.
    let listenCount: Int
    /// Tổng thời lượng audio (giây) — dùng tính tiến trình và thời gian còn lại.
    let totalDurationSeconds: Int
    let description: String
    let chapters: [ILTalkChapterEntity]
}

/// Pure business entity cho màn Pháp thoại — Domain layer only.
///
/// Chứa catalog bài pháp thoại, bài đang phát, vị trí phát và cờ play/pause trong bộ nhớ. Mọi
/// chuỗi đã format ("12:48", "-33:12", "2.4k", nhãn phần) là UI state, nằm trên
/// `ILTalkStateModel` — xem `references/data_layer_boundaries.md`.
struct ILTalkEntity: Equatable {
    var talks: [ILTalkTrackEntity] = []
    var currentTalkID: String = ""
    /// Vị trí phát (giây).
    var elapsedSeconds: Int = 0
    /// Đang phát / tạm dừng — cờ trong bộ nhớ cho tới khi có audio thật.
    var isPlaying: Bool = false

    static let empty = ILTalkEntity()
}
