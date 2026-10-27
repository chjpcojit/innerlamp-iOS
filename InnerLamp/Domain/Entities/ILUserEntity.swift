//
//  ILUserEntity.swift
//  InnerLamp
//

import Foundation

/// Pure business entity for a user account — Domain layer only.
///
/// Mirrors the backend's `userResponse` struct field for field. `dharmaName` and
/// `ordinationTempleID` carry `omitempty` on the Go side, so the key can be absent on the wire — the
/// Data-layer DTO keeps them `String?` and maps them to the non-optional `String` here with an
/// empty-string default. That matches the existing `ILHomeEntity.displayName` precedent: the
/// "show a fallback when this is empty" decision belongs to whichever ViewModel renders it, not to
/// the Entity.
struct ILUserEntity: Equatable {
    var id: Int64 = 0
    var email: String = ""
    var phoneNumber: String = ""
    var dharmaName: String = ""
    /// EN: `user.ordination_temple_id` (contract 3.0.0); empty when the user picked no temple.
    /// VI: `user.ordination_temple_id` (contract 3.0.0); rỗng khi người dùng chưa chọn chùa.
    var ordinationTempleID: String = ""

    static let empty = ILUserEntity()
}
