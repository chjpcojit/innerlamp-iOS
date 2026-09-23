//
//  ILOnboardingUseCase.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import Foundation

protocol ILOnboardingUseCase {
    func getInitialState() -> ILOnboardingStateModel
    func savePreferences(state: ILOnboardingStateModel)
    func markOnboardingCompleted()
    func isOnboardingCompleted() -> Bool
}

final class ILOnboardingUseCaseImpl: ILOnboardingUseCase {

    private let userDefaultsService: UserDefaultsService

    private enum StorageKeys {
        static let hasCompletedOnboarding = "has_completed_onboarding"
        static let selectedIntents = "onboarding_selected_intents"
        static let enabledBells = "onboarding_enabled_bells"
    }

    init(userDefaultsService: UserDefaultsService) {
        self.userDefaultsService = userDefaultsService
    }

    func getInitialState() -> ILOnboardingStateModel {
        return ILOnboardingStateModel.initial
    }

    func savePreferences(state: ILOnboardingStateModel) {
        let selectedIntentIds = state.intents.filter { $0.isSelected }.map { $0.id }
        let enabledBellIds = state.bells.filter { $0.isEnabled }.map { $0.id }

        userDefaultsService.save(key: StorageKeys.selectedIntents, value: selectedIntentIds)
        userDefaultsService.save(key: StorageKeys.enabledBells, value: enabledBellIds)
        markOnboardingCompleted()
    }

    func markOnboardingCompleted() {
        userDefaultsService.saveBool(key: StorageKeys.hasCompletedOnboarding, value: true)
    }

    func isOnboardingCompleted() -> Bool {
        return userDefaultsService.loadBool(key: StorageKeys.hasCompletedOnboarding, defaultValue: false)
    }
}
