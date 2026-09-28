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

    /// The one shared, app-wide gRPC channel — built once, held for the app's lifetime, never
    /// created per call or per feature. See Docs/Specs/GRPC/requirements.md FR-001. The lifetime
    /// object also owns the event-loop group that backs the channel, so neither is torn down
    /// while RPCs are in flight.
    lazy var grpcChannelLifetime: GRPCConfiguration.ChannelLifetime = {
        GRPCConfiguration.makeChannelLifetime()
    }()

    lazy var grpcService: GRPCService = {
        GRPCService(
            client: GRPCConfiguration.makeClient(channel: grpcChannelLifetime.channel),
            authTokenProvider: KeychainAuthTokenProviding(keychainService: keychainService),
            loggingService: loggingService
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

    // MARK: - BuddhistEvent
    lazy var buddhistEventLocalDataSource: ILBuddhistEventLocalDataSource = {
        ILBuddhistEventLocalDataSourceImpl(stack: coreDataStack)
    }()

    func makeBuddhistEventRepository() -> ILBuddhistEventRepository {
        ILBuddhistEventRepositoryImpl(localDataSource: buddhistEventLocalDataSource)
    }

    func makeBuddhistEventUseCase() -> ILBuddhistEventUseCase {
        ILBuddhistEventUseCaseImpl(repository: makeBuddhistEventRepository())
    }

    // MARK: - Deity catalog (Core Data, seeded from bundled phat_botat.json)
    lazy var deityLocalDataSource: ILDeityLocalDataSource = {
        ILDeityLocalDataSourceImpl(stack: coreDataStack)
    }()

    func makeDeityRepository() -> ILDeityRepository {
        ILDeityRepositoryImpl(localDataSource: deityLocalDataSource)
    }

    // MARK: - SutraQuote
    lazy var sutraQuoteLocalDataSource: ILSutraQuoteLocalDataSource = {
        ILSutraQuoteLocalDataSourceImpl(stack: coreDataStack)
    }()

    func makeSutraQuoteRepository() -> ILSutraQuoteRepository {
        ILSutraQuoteRepositoryImpl(localDataSource: sutraQuoteLocalDataSource)
    }

    func makeSutraQuoteUseCase() -> ILSutraQuoteUseCase {
        ILSutraQuoteUseCaseImpl(repository: makeSutraQuoteRepository())
    }

    // MARK: - UserBirthProfile
    lazy var userBirthProfileLocalDataSource: ILUserBirthProfileLocalDataSource = {
        ILUserBirthProfileLocalDataSourceImpl(stack: coreDataStack)
    }()

    func makeUserBirthProfileRepository() -> ILUserBirthProfileRepository {
        ILUserBirthProfileRepositoryImpl(localDataSource: userBirthProfileLocalDataSource)
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
    func makeLoginRepository() -> ILLoginRepository {
        ILLoginRepositoryImpl(networkService: networkService)
    }

    func makeLoginUseCase() -> ILLoginUseCase {
        ILLoginUseCaseImpl(
            repository: makeLoginRepository(),
            keychainService: keychainService,
            userRepository: makeUserRepository()
        )
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
        ILHomeUseCaseImpl(
            keychainService: keychainService,
            buddhistEventUseCase: makeBuddhistEventUseCase(),
            deityUseCase: makeDeityUseCase(),
            sutraQuoteUseCase: makeSutraQuoteUseCase()
        )
    }

    func makeHomeViewModel() -> ILHomeViewModel {
        ILHomeViewModel(useCase: makeHomeUseCase())
    }

    func makeHomeCoordinator(navigationController: UINavigationController) -> ILHomeCoordinator {
        ILHomeCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Deity
    func makeDeityUseCase() -> ILDeityUseCase {
        ILDeityUseCaseImpl() // static catalog; add real dependencies only alongside their real implementation
    }

    func makeDeityViewModel(deityID: String) -> ILDeityViewModel {
        ILDeityViewModel(useCase: makeDeityUseCase(), deityID: deityID)
    }

    func makeDeityCoordinator(navigationController: UINavigationController, deityID: String) -> ILDeityCoordinator {
        ILDeityCoordinator(navigationController: navigationController, container: self, deityID: deityID)
    }

    // MARK: - Deities (danh sách "Chư Phật & Bồ Tát")
    func makeDeitiesUseCase() -> ILDeitiesUseCase {
        ILDeitiesUseCaseImpl(deityUseCase: makeDeityUseCase())
    }

    func makeDeitiesViewModel() -> ILDeitiesViewModel {
        ILDeitiesViewModel(useCase: makeDeitiesUseCase())
    }

    func makeDeitiesCoordinator(navigationController: UINavigationController) -> ILDeitiesCoordinator {
        ILDeitiesCoordinator(navigationController: navigationController, container: self)
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

    // MARK: - LunarDayDetail
    func makeLunarDayDetailUseCase() -> ILLunarDayDetailUseCase {
        ILLunarDayDetailUseCaseImpl() // pure computation on ILLunarCalendar — no injected dependencies
    }

    func makeLunarDayDetailViewModel(date: Date, verse: ILHomeQuoteEntity? = nil) -> ILLunarDayDetailViewModel {
        ILLunarDayDetailViewModel(
            useCase: makeLunarDayDetailUseCase(),
            almanacUseCase: makeAlmanacUseCase(),
            sutraQuoteUseCase: makeSutraQuoteUseCase(),
            date: date,
            verse: verse
        )
    }

    func makeLunarDayDetailCoordinator(
        navigationController: UINavigationController,
        date: Date,
        verse: ILHomeQuoteEntity? = nil
    ) -> ILLunarDayDetailCoordinator {
        ILLunarDayDetailCoordinator(navigationController: navigationController, container: self, date: date, verse: verse)
    }

    // MARK: - Almanac (Offline Personal Almanac Engine)
    func makeAlmanacUseCase() -> ILAlmanacUseCase {
        ILAlmanacUseCaseImpl() // pure computation on ILLunarCalendar — no injected dependencies
    }

    // MARK: - Mala
    func makeMalaUseCase() -> ILMalaUseCase {
        ILMalaUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeMalaViewModel(mantraText: String? = nil) -> ILMalaViewModel {
        ILMalaViewModel(useCase: makeMalaUseCase(), soundPlayer: makePracticeSoundPlayer(), mantraText: mantraText)
    }

    func makeMalaCoordinator(navigationController: UINavigationController, mantraText: String? = nil) -> ILMalaCoordinator {
        ILMalaCoordinator(navigationController: navigationController, container: self, mantraText: mantraText)
    }

    // MARK: - Audio
    func makePracticeSoundPlayer() -> ILPracticeSoundPlaying {
        ILPracticeSoundPlayer()
    }

    // MARK: - Bell
    func makeBellUseCase() -> ILBellUseCase {
        ILBellUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeBellViewModel() -> ILBellViewModel {
        ILBellViewModel(useCase: makeBellUseCase(), soundPlayer: makePracticeSoundPlayer())
    }

    func makeBellCoordinator(navigationController: UINavigationController) -> ILBellCoordinator {
        ILBellCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - MeditationSetup
    func makeMeditationSetupUseCase() -> ILMeditationSetupUseCase {
        ILMeditationSetupUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeMeditationSetupViewModel() -> ILMeditationSetupViewModel {
        ILMeditationSetupViewModel(useCase: makeMeditationSetupUseCase())
    }

    func makeMeditationSetupCoordinator(navigationController: UINavigationController) -> ILMeditationSetupCoordinator {
        ILMeditationSetupCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - MeditationSession
    func makeMeditationSessionUseCase() -> ILMeditationSessionUseCase {
        ILMeditationSessionUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeMeditationSessionViewModel(durationMinutes: Int, isGuided: Bool) -> ILMeditationSessionViewModel {
        ILMeditationSessionViewModel(
            durationMinutes: durationMinutes,
            isGuided: isGuided,
            useCase: makeMeditationSessionUseCase(),
            soundPlayer: makePracticeSoundPlayer()
        )
    }

    func makeMeditationSessionCoordinator(
        navigationController: UINavigationController,
        durationMinutes: Int,
        isGuided: Bool
    ) -> ILMeditationSessionCoordinator {
        ILMeditationSessionCoordinator(
            navigationController: navigationController,
            container: self,
            durationMinutes: durationMinutes,
            isGuided: isGuided
        )
    }

    // MARK: - MeditationHub
    func makeMeditationHubUseCase() -> ILMeditationHubUseCase {
        ILMeditationHubUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeMeditationHubViewModel() -> ILMeditationHubViewModel {
        ILMeditationHubViewModel(useCase: makeMeditationHubUseCase())
    }

    func makeMeditationHubCoordinator(navigationController: UINavigationController) -> ILMeditationHubCoordinator {
        ILMeditationHubCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Photos
    func makePhotosUseCase() -> ILPhotosUseCase {
        ILPhotosUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makePhotosViewModel() -> ILPhotosViewModel {
        ILPhotosViewModel(useCase: makePhotosUseCase())
    }

    func makePhotosCoordinator(navigationController: UINavigationController) -> ILPhotosCoordinator {
        ILPhotosCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Article
    func makeArticleUseCase() -> ILArticleUseCase {
        ILArticleUseCaseImpl() // static catalog; add real dependencies only alongside their real implementation
    }

    func makeArticleViewModel(articleID: String) -> ILArticleViewModel {
        ILArticleViewModel(useCase: makeArticleUseCase(), articleID: articleID)
    }

    func makeArticleCoordinator(navigationController: UINavigationController, articleID: String) -> ILArticleCoordinator {
        ILArticleCoordinator(navigationController: navigationController, container: self, articleID: articleID)
    }

    // MARK: - Articles
    func makeArticlesUseCase() -> ILArticlesUseCase {
        ILArticlesUseCaseImpl() // static catalog; add real dependencies only alongside their real implementation
    }

    func makeArticlesViewModel() -> ILArticlesViewModel {
        ILArticlesViewModel(useCase: makeArticlesUseCase())
    }

    func makeArticlesCoordinator(navigationController: UINavigationController) -> ILArticlesCoordinator {
        ILArticlesCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Reader
    func makeReaderUseCase() -> ILReaderUseCase {
        ILReaderUseCaseImpl() // static catalog; add real dependencies only alongside their real implementation
    }

    func makeReaderViewModel(sutraID: String) -> ILReaderViewModel {
        ILReaderViewModel(useCase: makeReaderUseCase(), sutraID: sutraID)
    }

    func makeReaderCoordinator(navigationController: UINavigationController, sutraID: String) -> ILReaderCoordinator {
        ILReaderCoordinator(navigationController: navigationController, container: self, sutraID: sutraID)
    }

    // MARK: - Library
    func makeLibraryUseCase() -> ILLibraryUseCase {
        ILLibraryUseCaseImpl(deityUseCase: makeDeityUseCase())
    }

    func makeLibraryViewModel() -> ILLibraryViewModel {
        ILLibraryViewModel(useCase: makeLibraryUseCase())
    }

    func makeLibraryCoordinator(navigationController: UINavigationController) -> ILLibraryCoordinator {
        ILLibraryCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Talk
    func makeTalkUseCase() -> ILTalkUseCase {
        ILTalkUseCaseImpl() // static mock catalog; add real dependencies only alongside their real implementation
    }

    func makeTalkViewModel(talkID: String) -> ILTalkViewModel {
        ILTalkViewModel(useCase: makeTalkUseCase(), talkID: talkID)
    }

    func makeTalkCoordinator(navigationController: UINavigationController, talkID: String) -> ILTalkCoordinator {
        ILTalkCoordinator(navigationController: navigationController, container: self, talkID: talkID)
    }

    // MARK: - SutraDetail
    func makeSutraDetailUseCase() -> ILSutraDetailUseCase {
        ILSutraDetailUseCaseImpl() // static catalog; add real dependencies only alongside their real implementation
    }

    func makeSutraDetailViewModel(sutraID: String) -> ILSutraDetailViewModel {
        ILSutraDetailViewModel(useCase: makeSutraDetailUseCase(), sutraID: sutraID)
    }

    func makeSutraDetailCoordinator(navigationController: UINavigationController, sutraID: String) -> ILSutraDetailCoordinator {
        ILSutraDetailCoordinator(navigationController: navigationController, container: self, sutraID: sutraID)
    }

    // MARK: - Player
    func makePlayerUseCase() -> ILPlayerUseCase {
        ILPlayerUseCaseImpl() // static mock catalog; add real dependencies only alongside their real implementation
    }

    func makePlayerViewModel(sutraID: String) -> ILPlayerViewModel {
        ILPlayerViewModel(useCase: makePlayerUseCase(), sutraID: sutraID)
    }

    func makePlayerCoordinator(navigationController: UINavigationController, sutraID: String) -> ILPlayerCoordinator {
        ILPlayerCoordinator(navigationController: navigationController, container: self, sutraID: sutraID)
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

    // MARK: - Post
    func makePostUseCase() -> ILPostUseCase {
        ILPostUseCaseImpl() // static catalog; add real dependencies only alongside their real implementation
    }

    func makePostViewModel(postID: String) -> ILPostViewModel {
        ILPostViewModel(useCase: makePostUseCase(), postID: postID)
    }

    func makePostCoordinator(navigationController: UINavigationController, postID: String) -> ILPostCoordinator {
        ILPostCoordinator(navigationController: navigationController, container: self, postID: postID)
    }

    // MARK: - Events
    func makeEventsUseCase() -> ILEventsUseCase {
        ILEventsUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeEventsViewModel() -> ILEventsViewModel {
        ILEventsViewModel(useCase: makeEventsUseCase())
    }

    func makeEventsCoordinator(navigationController: UINavigationController) -> ILEventsCoordinator {
        ILEventsCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Festivals
    func makeFestivalsUseCase() -> ILFestivalsUseCase {
        ILFestivalsUseCaseImpl()
    }

    func makeFestivalsViewModel() -> ILFestivalsViewModel {
        ILFestivalsViewModel(useCase: makeFestivalsUseCase())
    }

    func makeFestivalsCoordinator(navigationController: UINavigationController) -> ILFestivalsCoordinator {
        ILFestivalsCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Temple
    func makeTempleUseCase() -> ILTempleUseCase {
        ILTempleUseCaseImpl() // static catalog; add real dependencies only alongside their real implementation
    }

    func makeTempleViewModel(templeID: String) -> ILTempleViewModel {
        ILTempleViewModel(useCase: makeTempleUseCase(), templeID: templeID)
    }

    func makeTempleCoordinator(navigationController: UINavigationController, templeID: String) -> ILTempleCoordinator {
        ILTempleCoordinator(navigationController: navigationController, container: self, templeID: templeID)
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

    // MARK: - Settings
    func makeSettingsUseCase() -> ILSettingsUseCase {
        ILSettingsUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeSettingsViewModel() -> ILSettingsViewModel {
        ILSettingsViewModel(useCase: makeSettingsUseCase())
    }

    func makeSettingsCoordinator(navigationController: UINavigationController) -> ILSettingsCoordinator {
        ILSettingsCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - EditProfile
    func makeEditProfileUseCase() -> ILEditProfileUseCase {
        ILEditProfileUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeEditProfileViewModel() -> ILEditProfileViewModel {
        ILEditProfileViewModel(useCase: makeEditProfileUseCase())
    }

    func makeEditProfileCoordinator(navigationController: UINavigationController) -> ILEditProfileCoordinator {
        ILEditProfileCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Notifications
    func makeNotificationsUseCase() -> ILNotificationsUseCase {
        ILNotificationsUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeNotificationsViewModel() -> ILNotificationsViewModel {
        ILNotificationsViewModel(useCase: makeNotificationsUseCase())
    }

    func makeNotificationsCoordinator(navigationController: UINavigationController) -> ILNotificationsCoordinator {
        ILNotificationsCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Stats
    func makeStatsUseCase() -> ILStatsUseCase {
        ILStatsUseCaseImpl() // add real dependencies only alongside their real implementation
    }

    func makeStatsViewModel() -> ILStatsViewModel {
        ILStatsViewModel(useCase: makeStatsUseCase())
    }

    func makeStatsCoordinator(navigationController: UINavigationController) -> ILStatsCoordinator {
        ILStatsCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - DeviceAttestation (background core service — no scene/coordinator)
    lazy var appAttestDataSource: ILAppAttestDataSource = {
        ILAppAttestDataSourceImpl()
    }()

    func makeDeviceAttestationRepository() -> ILDeviceAttestationRepository {
        ILDeviceAttestationRepositoryImpl(appAttestDataSource: appAttestDataSource)
    }

    func makeDeviceAttestationUseCase() -> ILDeviceAttestationUseCase {
        ILDeviceAttestationUseCaseImpl(
            repository: makeDeviceAttestationRepository(),
            keychainService: keychainService,
            userDefaultsService: userDefaultsService
        )
    }
}
