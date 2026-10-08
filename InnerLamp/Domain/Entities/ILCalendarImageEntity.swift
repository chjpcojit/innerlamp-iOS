//
//  ILCalendarImageEntity.swift
//  InnerLamp
//

import Foundation

/// The picture the backend assigns to one solar date (`GET /v1/calendar/image`) — Domain layer.
/// Raw server values only; the credit line is formatted by the ViewModel.
nonisolated struct ILCalendarImageEntity: Equatable {
    let id: String
    /// Absolute server URL, used verbatim (the host is the backend's LAN IP in dev).
    let imageURL: String
    let author: String
    let license: String
    /// `nil` when the server sent none.
    let licenseURL: String?
    /// `nil` when the server sent none.
    let sourceURL: String?
}
