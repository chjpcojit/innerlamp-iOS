//
//  ILAddTempleStateModel.swift
//  InnerLamp
//

import Foundation

/// Trường đang báo lỗi trên form.
enum ILAddTempleField: Equatable {
    case name
    case province
    case ward
}

/// Plain state model của màn "Thêm thông tin chùa" — không UIKit, không business logic.
struct ILAddTempleStateModel {
    var name: String = ""
    var province: String = ""
    var ward: String = ""
    var address: String = ""

    /// Danh mục từ metadata. Rỗng khi chưa tải xong (`isLoadingProvinces`).
    var provinceOptions: [String] = []
    var wardOptions: [String] = []
    var isLoadingProvinces = false
    var isLoadingWards = false

    var errorMessage: String?
    var errorField: ILAddTempleField?

    static let initial = ILAddTempleStateModel()
}
