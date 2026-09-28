//
//  ILDeitiesUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILDeitiesUseCase {
    /// Toàn bộ catalog "Phật & Bồ Tát" — cùng nguồn dữ liệu với màn chi tiết `Deity`.
    func getInitialState() -> ILDeitiesEntity

    /// Lọc theo loại: `nil` = "Tất cả", `.buddha` = "Chư Phật", `.bodhisattva` = "Bồ Tát".
    ///
    /// Thuần tính toán trên dữ liệu đã có trong bộ nhớ (không network/Repository) nên được
    /// implement thật, không phải stub.
    func deities(in entity: ILDeitiesEntity, kind: ILDeityKind?) -> [ILDeityEntity]
}

final class ILDeitiesUseCaseImpl: ILDeitiesUseCase {

    private let deityUseCase: ILDeityUseCase

    init(deityUseCase: ILDeityUseCase) {
        self.deityUseCase = deityUseCase
    }

    func getInitialState() -> ILDeitiesEntity {
        ILDeitiesEntity(deities: deityUseCase.getAllDeities())
    }

    func deities(in entity: ILDeitiesEntity, kind: ILDeityKind?) -> [ILDeityEntity] {
        guard let kind else { return entity.deities }
        return entity.deities.filter { $0.kind == kind }
    }
}
