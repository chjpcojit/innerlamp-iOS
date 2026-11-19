//
//  MemorialFeatureFlags.swift
//  InnerLamp
//

import Foundation

/// Build-time switches of the memorial feature. Read from `Info.plist`, never from a remote
/// config: a server-side toggle cannot tell the client that the photo *route* is missing (D4).
nonisolated enum MemorialFeatureFlags {

    /// `PUT/DELETE /v1/memorials/{id}/photo` were still returning 404 on 2026-11-16, and a 404 on
    /// that route is indistinguishable from `MEMORIAL_NOT_FOUND`. Keep the UI off until the deploy
    /// is smoke-tested (checklist in `Docs/Specs/Memorial/design.md`).
    static var isPhotoEnabled: Bool {
        Bundle.main.object(forInfoDictionaryKey: "MemorialPhotoEnabled") as? Bool ?? false
    }
}
