//
//  ILLightLampUseCase.swift
//  InnerLamp
//

import Foundation

/// What the user chose on the lighting form, before it becomes a stored lamp.
struct ILLampDraft: Equatable {
    var kind: ILLampKind = .oil
    var intention: ILLampIntention = .peace
    var target: String = ""
    var vow: String = ""
    var durationDays: Int = ILLampEntity.defaultDurationDays
}

protocol ILLightLampUseCase {

    /// Normalizes the draft (trims target and vow), stores it as a new lamp lit at `now` and
    /// returns it.
    func light(_ draft: ILLampDraft, now: Date) async throws -> ILLampEntity

    /// Lamps still shining at `now`, newest first.
    func loadActiveLamps(now: Date) async throws -> [ILLampEntity]
}

final class ILLightLampUseCaseImpl: ILLightLampUseCase {

    private let repository: ILLampRepository
    private let makeID: () -> String

    init(repository: ILLampRepository, makeID: @escaping () -> String = { UUID().uuidString }) {
        self.repository = repository
        self.makeID = makeID
    }

    func light(_ draft: ILLampDraft, now: Date) async throws -> ILLampEntity {
        let lamp = ILLampEntity(
            id: makeID(),
            kind: draft.kind,
            intention: draft.intention,
            target: draft.target.trimmingCharacters(in: .whitespacesAndNewlines),
            vow: draft.vow.trimmingCharacters(in: .whitespacesAndNewlines),
            durationDays: draft.durationDays,
            litAt: now
        )
        try await repository.save(lamp)
        return lamp
    }

    func loadActiveLamps(now: Date) async throws -> [ILLampEntity] {
        try await repository.loadAll()
            .filter { $0.isActive(now: now) }
            .sorted { $0.litAt > $1.litAt }
    }
}
