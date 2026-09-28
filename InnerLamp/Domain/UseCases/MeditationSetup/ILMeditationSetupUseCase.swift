//
//  ILMeditationSetupUseCase.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation

protocol ILMeditationSetupUseCase {
    func getInitialState() -> ILMeditationSetupEntity

    /// Chọn một mức thời lượng (phút). Chỉ chấp nhận giá trị nằm trong `durationOptions` — nếu
    /// không hợp lệ thì trả về nguyên trạng (không thay đổi thời lượng đang chọn).
    func selectDuration(_ minutes: Int, in entity: ILMeditationSetupEntity) -> ILMeditationSetupEntity
}

final class ILMeditationSetupUseCaseImpl: ILMeditationSetupUseCase {

    // Không có dependency ngoài: toàn bộ logic hiện tại là thuần (chọn thời lượng trong bộ nhớ),
    // không cần network/Repository. Khi có nguồn nội dung thiền thật (danh sách thời lượng theo
    // từng bài) mới thêm dependency tương ứng — xem `references/data_layer_boundaries.md`.
    init() {}

    func getInitialState() -> ILMeditationSetupEntity {
        ILMeditationSetupEntity()
    }

    func selectDuration(_ minutes: Int, in entity: ILMeditationSetupEntity) -> ILMeditationSetupEntity {
        guard entity.durationOptions.contains(minutes) else { return entity }
        var newEntity = entity
        newEntity.durationMinutes = minutes
        return newEntity
    }
}
