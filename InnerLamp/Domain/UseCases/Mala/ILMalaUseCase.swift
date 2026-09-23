//
//  ILMalaUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILMalaUseCase {
    func getInitialState() -> ILMalaEntity

    /// Niệm thêm một hạt. Vượt `goal` thì quay lại hạt 1 (bắt đầu tràng mới); chạm đúng `goal`
    /// thì tính đủ một tràng (`completedRounds` + 1).
    func advanceBead(_ entity: ILMalaEntity) -> ILMalaEntity

    /// "Bắt đầu lại" — đưa số hạt về 0, không đụng tới số tràng đã hoàn thành.
    func resetBeads(_ entity: ILMalaEntity) -> ILMalaEntity

    /// Mốc đặc biệt (rung / chuông) tại số hạt hiện tại, `nil` nếu không phải mốc.
    func milestone(for entity: ILMalaEntity) -> ILMalaMilestone?
}

final class ILMalaUseCaseImpl: ILMalaUseCase {

    // TODO: số hạt/số tràng hiện chỉ sống trong bộ nhớ của màn — khi có Repository lưu local
    // (Core Data/UserDefaults) thì đọc/ghi ở đây và đồng bộ với tràng hạt trên Trang chủ. Chưa
    // inject dependency nào cho tới lúc đó (xem `references/data_layer_boundaries.md`).
    init() {}

    func getInitialState() -> ILMalaEntity {
        ILMalaEntity()
    }

    func advanceBead(_ entity: ILMalaEntity) -> ILMalaEntity {
        var newEntity = entity
        let next = entity.count + 1
        newEntity.count = next > entity.goal ? 1 : next
        if newEntity.count == entity.goal {
            newEntity.completedRounds += 1
        }
        return newEntity
    }

    func resetBeads(_ entity: ILMalaEntity) -> ILMalaEntity {
        var newEntity = entity
        newEntity.count = 0
        return newEntity
    }

    func milestone(for entity: ILMalaEntity) -> ILMalaMilestone? {
        guard entity.count > 0 else { return nil }
        if entity.count == entity.goal { return .roundComplete }
        if entity.count % entity.quarterInterval == 0 { return .quarter }
        return nil
    }
}
