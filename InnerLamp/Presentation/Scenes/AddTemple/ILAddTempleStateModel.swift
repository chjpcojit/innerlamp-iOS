//
//  ILAddTempleStateModel.swift
//  InnerLamp
//

import Foundation

/// Trường đang báo lỗi trên form.
enum ILAddTempleField: Equatable {
    case name
    case province
}

/// Plain state model của màn "Thêm thông tin chùa" — không UIKit, không business logic.
struct ILAddTempleStateModel {
    var name: String = ""
    var province: String = ""
    var address: String = ""

    var errorMessage: String?
    var errorField: ILAddTempleField?

    static let initial = ILAddTempleStateModel()
}
