//
//  ILMalaUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILMalaUseCase {
    func getInitialState() -> ILMalaEntity

    /// Niệm thêm một hạt. Dừng ở `goal` (đủ vòng) — muốn niệm tiếp phải gọi `startNextRound`.
    func advanceBead(_ entity: ILMalaEntity) -> ILMalaEntity

    /// "Bắt đầu lại" — đưa số hạt về 0, giữ nguyên vòng hiện tại.
    func resetBeads(_ entity: ILMalaEntity) -> ILMalaEntity

    /// Đổi mục tiêu (21 / 54 / 108 biến) — đếm lại từ 0, giữ nguyên vòng hiện tại. Giá trị không
    /// nằm trong `ILMalaEntity.goalOptions` bị bỏ qua.
    func selectGoal(_ goal: Int, for entity: ILMalaEntity) -> ILMalaEntity

    /// "Niệm tiếp vòng mới" — đếm lại từ 0 và sang vòng kế tiếp.
    func startNextRound(_ entity: ILMalaEntity) -> ILMalaEntity

    /// Mốc đặc biệt (rung / chuông) tại số hạt hiện tại, `nil` nếu không phải mốc.
    func milestone(for entity: ILMalaEntity) -> ILMalaMilestone?
}

final class ILMalaUseCaseImpl: ILMalaUseCase {

    // TODO: số hạt/vòng hiện chỉ sống trong bộ nhớ của màn — khi có Repository lưu local
    // (Core Data/UserDefaults) thì đọc/ghi ở đây và đồng bộ với tràng hạt trên Trang chủ. Chưa
    // inject dependency nào cho tới lúc đó (xem `references/data_layer_boundaries.md`).
    init() {}

    func getInitialState() -> ILMalaEntity {
        ILMalaEntity()
    }

    func advanceBead(_ entity: ILMalaEntity) -> ILMalaEntity {
        guard !entity.isRoundComplete else { return entity }
        var newEntity = entity
        newEntity.count += 1
        return newEntity
    }

    func resetBeads(_ entity: ILMalaEntity) -> ILMalaEntity {
        var newEntity = entity
        newEntity.count = 0
        return newEntity
    }

    func selectGoal(_ goal: Int, for entity: ILMalaEntity) -> ILMalaEntity {
        guard ILMalaEntity.goalOptions.contains(goal) else { return entity }
        var newEntity = entity
        newEntity.goal = goal
        newEntity.count = 0
        return newEntity
    }

    func startNextRound(_ entity: ILMalaEntity) -> ILMalaEntity {
        var newEntity = entity
        newEntity.count = 0
        newEntity.round += 1
        return newEntity
    }

    func milestone(for entity: ILMalaEntity) -> ILMalaMilestone? {
        guard entity.count > 0 else { return nil }
        if entity.count == entity.goal { return .roundComplete }
        if entity.count % entity.quarterInterval == 0 { return .quarter }
        return nil
    }
}
