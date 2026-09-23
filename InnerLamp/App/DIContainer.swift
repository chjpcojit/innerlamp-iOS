//
//  DIContainer.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import Foundation
import UIKit

final class DIContainer {
    
    // MARK: - Core Services
    lazy var userDefaultsService: UserDefaultsService = {
        UserDefaultsServiceImpl()
    }()
    
    lazy var keychainService: KeychainService = {
        KeychainServiceImpl()
    }()

    lazy var coreDataStack: CoreDataStack = {
        CoreDataStack()
    }()

    lazy var networkService: NetworkService = {
        NetworkServiceImpl(
            session: NetworkConfiguration.makeSession(),
            authTokenProvider: KeychainAuthTokenProviding(keychainService: keychainService),
            logger: NetworkLogger(loggingService: loggingService)
        )
    }()

    lazy var localizationService: LocalizationService = LocalizationServiceImpl.shared

    lazy var themeService: ThemeService = ThemeServiceImpl.shared

    // MARK: - Logging (xem InnerLamp/Docs/Specs/Mobile Logging Architecture.md)
    lazy var loggingService: LoggingService = SentryLoggingService.shared
    lazy var securityAlertReporter: SecurityAlertReporting = SecurityAlertReporter.shared
    lazy var metricsCollector: MetricsCollecting = MetricsCollector.shared
    lazy var flowTracker: FlowTracking = FlowTracker.shared

    // MARK: - User
    lazy var userLocalDataSource: ILUserLocalDataSource = {
        ILUserLocalDataSourceImpl(stack: coreDataStack)
    }()

    func makeUserRepository() -> ILUserRepository {
        ILUserRepositoryImpl(localDataSource: userLocalDataSource)
    }

    // MARK: - Splash
    func makeSplashUseCase() -> ILSplashUseCase {
        ILSplashUseCaseImpl(onboardingUseCase: makeOnboardingUseCase())
    }

    func makeSplashViewModel() -> ILSplashViewModel {
        ILSplashViewModel(useCase: makeSplashUseCase())
    }

    func makeSplashCoordinator(navigationController: UINavigationController) -> ILSplashCoordinator {
        ILSplashCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Onboarding
    func makeOnboardingUseCase() -> ILOnboardingUseCase {
        ILOnboardingUseCaseImpl(userDefaultsService: userDefaultsService)
    }

    func makeOnboardingViewModel() -> ILOnboardingViewModel {
        ILOnboardingViewModel(useCase: makeOnboardingUseCase())
    }

    func makeOnboardingCoordinator(navigationController: UINavigationController) -> ILOnboardingCoordinator {
        ILOnboardingCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - SignUp
    func makeSignUpRepository() -> ILSignUpRepository {
        ILSignUpRepositoryImpl(networkService: networkService)
    }

    func makeSignUpUseCase() -> ILSignUpUseCase {
        ILSignUpUseCaseImpl(repository: makeSignUpRepository())
    }

    func makeSignUpViewModel() -> ILSignUpViewModel {
        ILSignUpViewModel(useCase: makeSignUpUseCase())
    }

    func makeSignUpCoordinator(navigationController: UINavigationController) -> ILSignUpCoordinator {
        ILSignUpCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Login
    func makeLoginUseCase() -> ILLoginUseCase {
        ILLoginUseCaseImpl()
    }

    func makeLoginViewModel() -> ILLoginViewModel {
        ILLoginViewModel(useCase: makeLoginUseCase())
    }

    func makeLoginCoordinator(navigationController: UINavigationController) -> ILLoginCoordinator {
        ILLoginCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Otp
    func makeOtpRepository() -> ILOtpRepository {
        ILOtpRepositoryImpl(networkService: networkService)
    }

    func makeOtpUseCase() -> ILOtpUseCase {
        ILOtpUseCaseImpl(
            repository: makeOtpRepository(),
            keychainService: keychainService,
            userRepository: makeUserRepository()
        )
    }

    func makeOtpViewModel(phoneNumber: String, otpExpiresInSeconds: Int, resendAfterSeconds: Int) -> ILOtpViewModel {
        ILOtpViewModel(
            useCase: makeOtpUseCase(),
            phoneNumber: phoneNumber,
            otpExpiresInSeconds: otpExpiresInSeconds,
            resendAfterSeconds: resendAfterSeconds
        )
    }

    func makeOtpCoordinator(
        navigationController: UINavigationController,
        phoneNumber: String,
        otpExpiresInSeconds: Int,
        resendAfterSeconds: Int
    ) -> ILOtpCoordinator {
        ILOtpCoordinator(
            navigationController: navigationController,
            container: self,
            phoneNumber: phoneNumber,
            otpExpiresInSeconds: otpExpiresInSeconds,
            resendAfterSeconds: resendAfterSeconds
        )
    }

    // MARK: - ForgotPassword
    func makeForgotPasswordUseCase() -> ILForgotPasswordUseCase {
        ILForgotPasswordUseCaseImpl()
    }

    func makeForgotPasswordViewModel() -> ILForgotPasswordViewModel {
        ILForgotPasswordViewModel(useCase: makeForgotPasswordUseCase())
    }

    func makeForgotPasswordCoordinator(navigationController: UINavigationController) -> ILForgotPasswordCoordinator {
        ILForgotPasswordCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Main (tab bar)
    func makeMainTabCoordinator(navigationController: UINavigationController) -> ILMainTabCoordinator {
        ILMainTabCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Home
    func makeHomeUseCase() -> ILHomeUseCase {
        ILHomeUseCaseImpl(keychainService: keychainService)
    }

    func makeHomeViewModel() -> ILHomeViewModel {
        ILHomeViewModel(useCase: makeHomeUseCase())
    }

    func makeHomeCoordinator(navigationController: UINavigationController) -> ILHomeCoordinator {
        ILHomeCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - LunarCalendar
    func makeLunarCalendarUseCase() -> ILLunarCalendarUseCase {
        ILLunarCalendarUseCaseImpl() // pure computation on ILLunarCalendar — no injected dependencies
    }

    func makeLunarCalendarViewModel() -> ILLunarCalendarViewModel {
        ILLunarCalendarViewModel(useCase: makeLunarCalendarUseCase())
    }

    func makeLunarCalendarCoordinator(navigationController: UINavigationController) -> ILLunarCalendarCoordinator {
        ILLunarCalendarCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Mala
    func makeMalaUseCase() -> ILMalaUseCase {
        ILMalaUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeMalaViewModel() -> ILMalaViewModel {
        ILMalaViewModel(useCase: makeMalaUseCase())
    }

    func makeMalaCoordinator(navigationController: UINavigationController) -> ILMalaCoordinator {
        ILMalaCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Library
    func makeLibraryUseCase() -> ILLibraryUseCase {
        ILLibraryUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeLibraryViewModel() -> ILLibraryViewModel {
        ILLibraryViewModel(useCase: makeLibraryUseCase())
    }

    func makeLibraryCoordinator(navigationController: UINavigationController) -> ILLibraryCoordinator {
        ILLibraryCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Sangha
    func makeSanghaUseCase() -> ILSanghaUseCase {
        ILSanghaUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeSanghaViewModel() -> ILSanghaViewModel {
        ILSanghaViewModel(useCase: makeSanghaUseCase())
    }

    func makeSanghaCoordinator(navigationController: UINavigationController) -> ILSanghaCoordinator {
        ILSanghaCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Profile
    func makeProfileUseCase() -> ILProfileUseCase {
        ILProfileUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeProfileViewModel() -> ILProfileViewModel {
        ILProfileViewModel(useCase: makeProfileUseCase())
    }

    func makeProfileCoordinator(navigationController: UINavigationController) -> ILProfileCoordinator {
        ILProfileCoordinator(navigationController: navigationController, container: self)
    }
}
