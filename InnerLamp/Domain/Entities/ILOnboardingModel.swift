//
//  ILOnboardingModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 12/9/26.
//

import Foundation

struct ILOnboardingIntentItem: Equatable {
    let id: Int
    let label: String
    var isSelected: Bool

    init(id: Int, label: String, isSelected: Bool = false) {
        self.id = id
        self.label = label
        self.isSelected = isSelected
    }
}

struct ILOnboardingBellItem: Equatable {
    let id: Int
    let label: String
    let sub: String
    var isEnabled: Bool

    init(id: Int, label: String, sub: String, isEnabled: Bool = true) {
        self.id = id
        self.label = label
        self.sub = sub
        self.isEnabled = isEnabled
    }
}

/// Nội dung của 1 step onboarding. Thêm step mới = thêm 1 case data vào mảng `steps`,
/// không cần thêm ViewController property hay sửa layout — miễn case đó tái dùng 1 trong các
/// "hình dạng" step đã có (`chipChoice`, `toggleList`). Chỉ khi cần 1 hình dạng UI hoàn toàn mới
/// mới phải thêm case + view mới.
enum ILOnboardingStepContent: Equatable {
    case intro
    case chipChoice(title: String, subtitle: String, items: [ILOnboardingIntentItem])
    case toggleList(title: String, subtitle: String, items: [ILOnboardingBellItem])
}

struct ILOnboardingStateModel: Equatable {
    var currentStep: Int
    var steps: [ILOnboardingStepContent]

    init(currentStep: Int = 0, steps: [ILOnboardingStepContent] = []) {
        self.currentStep = currentStep
        self.steps = steps
    }

    var totalSteps: Int { steps.count }

    var isLastStep: Bool { currentStep >= totalSteps - 1 }

    var ctaTitle: String {
        if isLastStep { return "onboarding.cta.createAccount".localized }
        return currentStep == 0 ? "onboarding.cta.start".localized : "onboarding.cta.continue".localized
    }

    var backTitle: String {
        currentStep == 0 ? "onboarding.back.toLogin".localized : "onboarding.back.previous".localized
    }

    /// Convenience đọc items của step `.chipChoice` đầu tiên — dùng cho persistence ở UseCase.
    var intents: [ILOnboardingIntentItem] {
        for step in steps {
            if case .chipChoice(_, _, let items) = step { return items }
        }
        return []
    }

    /// Convenience đọc items của step `.toggleList` đầu tiên — dùng cho persistence ở UseCase.
    var bells: [ILOnboardingBellItem] {
        for step in steps {
            if case .toggleList(_, _, let items) = step { return items }
        }
        return []
    }

    /// Toggle 1 item (chip hoặc bell) tại step bất kỳ — dùng chung cho mọi step dạng "chọn từ list",
    /// bất kể có bao nhiêu step hay step đó nằm ở vị trí nào.
    func togglingItem(atStep stepIndex: Int, itemIndex: Int) -> ILOnboardingStateModel {
        var copy = self
        guard steps.indices.contains(stepIndex) else { return copy }

        switch steps[stepIndex] {
        case .intro:
            break
        case .chipChoice(let title, let subtitle, var items):
            guard items.indices.contains(itemIndex) else { break }
            items[itemIndex].isSelected.toggle()
            copy.steps[stepIndex] = .chipChoice(title: title, subtitle: subtitle, items: items)
        case .toggleList(let title, let subtitle, var items):
            guard items.indices.contains(itemIndex) else { break }
            items[itemIndex].isEnabled.toggle()
            copy.steps[stepIndex] = .toggleList(title: title, subtitle: subtitle, items: items)
        }
        return copy
    }

    static var initial: ILOnboardingStateModel {
        let defaultIntents = [
            ILOnboardingIntentItem(id: 0, label: "onboarding.intent.0".localized, isSelected: true),
            ILOnboardingIntentItem(id: 1, label: "onboarding.intent.1".localized, isSelected: false),
            ILOnboardingIntentItem(id: 2, label: "onboarding.intent.2".localized, isSelected: false),
            ILOnboardingIntentItem(id: 3, label: "onboarding.intent.3".localized, isSelected: false),
            ILOnboardingIntentItem(id: 4, label: "onboarding.intent.4".localized, isSelected: false),
            ILOnboardingIntentItem(id: 5, label: "onboarding.intent.5".localized, isSelected: false)
        ]

        let defaultBells = [
            ILOnboardingBellItem(id: 0, label: "onboarding.bell.0.label".localized, sub: "onboarding.bell.0.sub".localized, isEnabled: true),
            ILOnboardingBellItem(id: 1, label: "onboarding.bell.1.label".localized, sub: "onboarding.bell.1.sub".localized, isEnabled: false),
            ILOnboardingBellItem(id: 2, label: "onboarding.bell.2.label".localized, sub: "onboarding.bell.2.sub".localized, isEnabled: true)
        ]

        return ILOnboardingStateModel(currentStep: 0, steps: [
            .intro,
            .chipChoice(title: "onboarding.step2.title".localized, subtitle: "onboarding.step2.subtitle".localized, items: defaultIntents),
            .toggleList(title: "onboarding.step3.title".localized, subtitle: "onboarding.step3.subtitle".localized, items: defaultBells)
        ])
    }
}
