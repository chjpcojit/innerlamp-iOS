//
//  ILLightLampTestSupport.swift
//  InnerLampTests
//

import Foundation
@testable import InnerLamp

enum ILLightLampTestFactory {

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    static func lamp(
        id: String = "lamp",
        kind: ILLampKind = .oil,
        intention: ILLampIntention = .peace,
        target: String = "",
        vow: String = "",
        durationDays: Int = 7,
        litAt: Date
    ) -> ILLampEntity {
        ILLampEntity(
            id: id, kind: kind, intention: intention, target: target, vow: vow,
            durationDays: durationDays, litAt: litAt
        )
    }
}

/// In-memory `ILLampRepository`; `saveError` / `loadError` make the next call fail.
nonisolated final class FakeILLampRepository: ILLampRepository {
    var stored: [ILLampEntity] = []
    var saveError: Error?
    var loadError: Error?
    private(set) var saveCallCount = 0

    func loadAll() async throws -> [ILLampEntity] {
        if let loadError { throw loadError }
        return stored
    }

    func save(_ lamp: ILLampEntity) async throws {
        saveCallCount += 1
        if let saveError { throw saveError }
        stored.append(lamp)
    }
}

/// Hand-written `ILLightLampUseCase` double for ViewModel tests.
final class MockILLightLampUseCase: ILLightLampUseCase {
    var activeLamps: [ILLampEntity] = []
    var lightError: Error?
    var loadError: Error?
    private(set) var lightedDrafts: [ILLampDraft] = []

    func light(_ draft: ILLampDraft, now: Date) async throws -> ILLampEntity {
        lightedDrafts.append(draft)
        if let lightError { throw lightError }
        let lamp = ILLampEntity(
            id: "lit-\(lightedDrafts.count)", kind: draft.kind, intention: draft.intention,
            target: draft.target.trimmingCharacters(in: .whitespacesAndNewlines),
            vow: draft.vow.trimmingCharacters(in: .whitespacesAndNewlines),
            durationDays: draft.durationDays, litAt: now
        )
        activeLamps.append(lamp)
        return lamp
    }

    func loadActiveLamps(now: Date) async throws -> [ILLampEntity] {
        if let loadError { throw loadError }
        return activeLamps
    }
}

struct ILLightLampTestError: Error {}
