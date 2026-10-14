//
//  DIContainer.swift
//  InnerLamp
//
//  Created by ChjpCoj on 11/9/26.
//

import Foundation
import GRPCCore
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
        let authTokenProvider = KeychainAuthTokenProviding(keychainService: keychainService)
        let logger = NetworkLogger(loggingService: loggingService)
        // The refresh call goes through its own transport with no refresher attached, so a 401
        // from `/auth/refresh` cannot loop back into the refresher.
        let refreshTransport = NetworkServiceImpl(
            session: NetworkConfiguration.makeSession(),
            authTokenProvider: authTokenProvider,
            logger: logger
        )
        return NetworkServiceImpl(
            session: NetworkConfiguration.makeSession(),
            authTokenProvider: authTokenProvider,
            logger: logger,
            sessionRefresher: AuthSessionRefresher(
                keychainService: keychainService,
                networkService: refreshTransport
            )
        )
    }()

    /// The one shared, app-wide gRPC client — built once, held for the app's lifetime, never
    /// created per call or per feature. The auth and logging interceptors are attached here, at
    /// construction. See Docs/Specs/GRPC/requirements.md FR-001.
    lazy var grpcClient: GRPCConfiguration.Client = {
        GRPCConfiguration.makeClient(
            authTokenProvider: KeychainAuthTokenProviding(keychainService: keychainService),
            loggingService: loggingService
        )
    }()

    lazy var grpcService: GRPCConfiguration.Service = {
        GRPCService(client: grpcClient)
    }()

    /// Starts the shared client's connection loop. Kept out of the lazy initializers above so
    /// tests that touch `grpcClient`/`grpcService` never open a real connection; the app calls
    /// this once at scene connect. RPCs issued before the client starts are queued by
    /// `GRPCClient`, so this does not need to complete before the first call.
    func startGRPCClient() {
        let client = grpcClient
        Task {
            try? await client.runConnections()
        }
    }

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

    // MARK: - Deity catalog (server /v1/deities*, cached in Core Data)
    lazy var deityCatalogLocalDataSource: ILDeityCatalogLocalDataSource = {
        ILDeityCatalogLocalDataSourceImpl(stack: coreDataStack)
    }()

    func makeDeityCatalogRepository() -> ILDeityCatalogRepository {
        ILDeityCatalogRepositoryImpl(networkService: networkService, localDataSource: deityCatalogLocalDataSource)
    }

    // MARK: - Temple catalog (server /v1/temples*, cached in Core Data)
    lazy var templeLocalDataSource: ILTempleLocalDataSource = {
        ILTempleLocalDataSourceImpl(stack: coreDataStack)
    }()

    func makeTempleRepository() -> ILTempleRepository {
        ILTempleRepositoryImpl(networkService: networkService, localDataSource: templeLocalDataSource)
    }

    // MARK: - Temple options (server GET /v1/temples/options, network-only, searchable)
    func makeTempleOptionRepository() -> ILTempleOptionRepository {
        ILTempleOptionRepositoryImpl(networkService: networkService)
    }

    // MARK: - Administrative units (server /v1/administrative-units/new/*, province -> ward)
    func makeAdministrativeUnitRepository() -> ILAdministrativeUnitRepository {
        ILAdministrativeUnitRepositoryImpl(networkService: networkService)
    }

    // MARK: - Article catalog (server /v1/articles*, network-only)
    func makeArticleRepository() -> ILArticleRepository {
        ILArticleRepositoryImpl(networkService: networkService)
    }

    // MARK: - Sutra catalog (server /v1/sutras*, network-only)
    func makeSutraRepository() -> ILSutraRepository {
        ILSutraRepositoryImpl(networkService: networkService)
    }

    // MARK: - Photos gallery (server /v1/gallery, network-only)
    func makePhotosRepository() -> ILPhotosRepository {
        ILPhotosRepositoryImpl(networkService: networkService)
    }

    // MARK: - Calendar image (server /v1/calendar/image, network-only)
    func makeCalendarImageRepository() -> ILCalendarImageRepository {
        ILCalendarImageRepositoryImpl(networkService: networkService)
    }

    func makeCalendarImageUseCase() -> ILCalendarImageUseCase {
        ILCalendarImageUseCaseImpl(repository: makeCalendarImageRepository())
    }

    // MARK: - CalendarEvent (server)
    func makeCalendarEventRepository() -> ILCalendarEventRepository {
        ILCalendarEventRepositoryImpl(networkService: networkService)
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
        ILSplashUseCaseImpl(onboardingUseCase: makeOnboardingUseCase(), keychainService: keychainService, userDefaultsService: userDefaultsService)
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

    func makeOrdinationPlaceUseCase() -> ILOrdinationPlaceUseCase {
        ILOrdinationPlaceUseCaseImpl(templeOptionRepository: makeTempleOptionRepository())
    }

    func makeSignUpViewModel() -> ILSignUpViewModel {
        ILSignUpViewModel(useCase: makeSignUpUseCase(), ordinationPlaceUseCase: makeOrdinationPlaceUseCase())
    }

    // MARK: - AddTemple (màn "Thêm thông tin chùa")
    func makeAddTempleUseCase() -> ILAddTempleUseCase {
        ILAddTempleUseCaseImpl(administrativeUnitRepository: makeAdministrativeUnitRepository())
    }

    func makeAddTempleViewModel(prefillName: String, existingPlaces: [ILOrdinationPlaceEntity]) -> ILAddTempleViewModel {
        ILAddTempleViewModel(useCase: makeAddTempleUseCase(), prefillName: prefillName, existingPlaces: existingPlaces)
    }

    func makeAddTempleCoordinator(
        navigationController: UINavigationController,
        prefillName: String,
        existingPlaces: [ILOrdinationPlaceEntity]
    ) -> ILAddTempleCoordinator {
        ILAddTempleCoordinator(
            navigationController: navigationController,
            container: self,
            prefillName: prefillName,
            existingPlaces: existingPlaces
        )
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
            calendarEventRepository: makeCalendarEventRepository(),
            sutraQuoteUseCase: makeSutraQuoteUseCase(),
            templeRepository: makeTempleRepository(),
            deityCatalogRepository: makeDeityCatalogRepository(),
            articleRepository: makeArticleRepository(),
            photosRepository: makePhotosRepository()
        )
    }

    func makeHomeViewModel() -> ILHomeViewModel {
        ILHomeViewModel(useCase: makeHomeUseCase(), calendarImageUseCase: makeCalendarImageUseCase())
    }

    func makeHomeCoordinator(navigationController: UINavigationController) -> ILHomeCoordinator {
        ILHomeCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Deity
    func makeDeityUseCase() -> ILDeityUseCase {
        ILDeityUseCaseImpl(deityCatalogRepository: makeDeityCatalogRepository())
    }

    func makeDeityViewModel(deityID: String) -> ILDeityViewModel {
        ILDeityViewModel(useCase: makeDeityUseCase(), deityID: deityID)
    }

    func makeDeityCoordinator(navigationController: UINavigationController, deityID: String) -> ILDeityCoordinator {
        ILDeityCoordinator(navigationController: navigationController, container: self, deityID: deityID)
    }

    // MARK: - Sutras (danh sách "Kinh sách")
    func makeSutrasUseCase() -> ILSutrasUseCase {
        ILSutrasUseCaseImpl(sutraRepository: makeSutraRepository())
    }

    func makeSutrasViewModel() -> ILSutrasViewModel {
        ILSutrasViewModel(useCase: makeSutrasUseCase())
    }

    func makeSutrasCoordinator(navigationController: UINavigationController) -> ILSutrasCoordinator {
        ILSutrasCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Deities (danh sách "Chư Phật & Bồ Tát")
    func makeDeitiesUseCase() -> ILDeitiesUseCase {
        ILDeitiesUseCaseImpl(deityCatalogRepository: makeDeityCatalogRepository())
    }

    func makeDeitiesViewModel() -> ILDeitiesViewModel {
        ILDeitiesViewModel(useCase: makeDeitiesUseCase())
    }

    func makeDeitiesCoordinator(navigationController: UINavigationController) -> ILDeitiesCoordinator {
        ILDeitiesCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Temples (màn "Tất cả chùa")
    func makeTemplesUseCase() -> ILTemplesUseCase {
        ILTemplesUseCaseImpl(templeRepository: makeTempleRepository())
    }

    func makeTemplesViewModel() -> ILTemplesViewModel {
        ILTemplesViewModel(useCase: makeTemplesUseCase())
    }

    func makeTemplesCoordinator(navigationController: UINavigationController) -> ILTemplesCoordinator {
        ILTemplesCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - TempleFinder (màn "Chọn chùa tu tập")
    func makeTempleFinderUseCase() -> ILTempleFinderUseCase {
        ILTempleFinderUseCaseImpl(templeRepository: makeTempleRepository(), sanghaUseCase: makeSanghaUseCase())
    }

    func makeTempleFinderViewModel() -> ILTempleFinderViewModel {
        ILTempleFinderViewModel(useCase: makeTempleFinderUseCase())
    }

    func makeTempleFinderCoordinator(navigationController: UINavigationController) -> ILTempleFinderCoordinator {
        ILTempleFinderCoordinator(navigationController: navigationController, container: self)
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
            calendarImageUseCase: makeCalendarImageUseCase(),
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
        ILPhotosUseCaseImpl(photosRepository: makePhotosRepository())
    }

    func makePhotosViewModel() -> ILPhotosViewModel {
        ILPhotosViewModel(useCase: makePhotosUseCase())
    }

    func makePhotosCoordinator(navigationController: UINavigationController) -> ILPhotosCoordinator {
        ILPhotosCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - PhotoViewer
    func makePhotoViewerViewModel(items: [ILPhotoViewerItemModel], startID: String) -> ILPhotoViewerViewModel? {
        ILPhotoViewerViewModel(items: items, startID: startID)
    }

    func makePhotoViewerCoordinator(
        navigationController: UINavigationController,
        items: [ILPhotoViewerItemModel],
        startID: String
    ) -> ILPhotoViewerCoordinator {
        ILPhotoViewerCoordinator(
            navigationController: navigationController,
            container: self,
            items: items,
            startID: startID
        )
    }

    // MARK: - Article
    func makeArticleUseCase() -> ILArticleUseCase {
        ILArticleUseCaseImpl(articleRepository: makeArticleRepository())
    }

    func makeArticleViewModel(articleID: String) -> ILArticleViewModel {
        ILArticleViewModel(useCase: makeArticleUseCase(), articleID: articleID)
    }

    func makeArticleCoordinator(navigationController: UINavigationController, articleID: String) -> ILArticleCoordinator {
        ILArticleCoordinator(navigationController: navigationController, container: self, articleID: articleID)
    }

    // MARK: - Articles
    func makeArticlesUseCase() -> ILArticlesUseCase {
        ILArticlesUseCaseImpl(articleRepository: makeArticleRepository())
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
        ILLibraryUseCaseImpl(deityCatalogRepository: makeDeityCatalogRepository())
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

    // MARK: - Talks (danh sách "Pháp thoại")
    func makeTalksUseCase() -> ILTalksUseCase {
        ILTalksUseCaseImpl()
    }

    func makeTalksViewModel() -> ILTalksViewModel {
        ILTalksViewModel(useCase: makeTalksUseCase())
    }

    func makeTalksCoordinator(navigationController: UINavigationController) -> ILTalksCoordinator {
        ILTalksCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - SutraDetail
    func makeSutraDetailUseCase() -> ILSutraDetailUseCase {
        ILSutraDetailUseCaseImpl(sutraRepository: makeSutraRepository())
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
        ILSanghaUseCaseImpl(
            userDefaultsService: userDefaultsService,
            accountRepository: ILAccountProfileRepositoryImpl(networkService: networkService),
            templeRepository: makeTempleRepository()
        )
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

    // MARK: - LightLamp (Thắp đèn + Vườn đèn — local Core Data only, no API)
    lazy var lampLocalDataSource: ILLampLocalDataSource = {
        ILLampLocalDataSourceImpl(stack: coreDataStack)
    }()

    func makeLampRepository() -> ILLampRepository {
        ILLampRepositoryImpl(localDataSource: lampLocalDataSource)
    }

    func makeLightLampUseCase() -> ILLightLampUseCase {
        ILLightLampUseCaseImpl(repository: makeLampRepository())
    }

    func makeLightLampViewModel() -> ILLightLampViewModel {
        ILLightLampViewModel(useCase: makeLightLampUseCase())
    }

    func makeLampGardenViewModel() -> ILLampGardenViewModel {
        ILLampGardenViewModel(useCase: makeLightLampUseCase())
    }

    func makeLightLampCoordinator(navigationController: UINavigationController) -> ILLightLampCoordinator {
        ILLightLampCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Donate (Ủng hộ InnerLamp — mocked receiving account, no API)
    func makeDonationAccountRepository() -> ILDonationAccountRepository {
        ILMockDonationAccountRepository()
    }

    func makeDonateUseCase() -> ILDonateUseCase {
        ILDonateUseCaseImpl(repository: makeDonationAccountRepository())
    }

    func makeDonateViewModel() -> ILDonateViewModel {
        ILDonateViewModel(useCase: makeDonateUseCase())
    }

    func makeDonateCoordinator(navigationController: UINavigationController) -> ILDonateCoordinator {
        ILDonateCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Memorial (Sổ giỗ chạp — server `/v1/memorials` + Core Data offline cache)
    lazy var memorialLocalDataSource: ILMemorialLocalDataSource = {
        ILMemorialLocalDataSourceImpl(stack: coreDataStack)
    }()

    func makeMemorialRepository() -> ILMemorialRepository {
        ILMemorialRepositoryImpl(networkService: networkService, localDataSource: memorialLocalDataSource)
    }

    func makeMemorialUseCase() -> ILMemorialUseCase {
        ILMemorialUseCaseImpl(repository: makeMemorialRepository())
    }

    func makeMemorialViewModel() -> ILMemorialViewModel {
        ILMemorialViewModel(useCase: makeMemorialUseCase())
    }

    /// `entry == nil` opens the form blank (add mode).
    func makeMemorialEditViewModel(entry: ILMemorialEntity?) -> ILMemorialEditViewModel {
        ILMemorialEditViewModel(useCase: makeMemorialUseCase(), entry: entry)
    }

    func makeMemorialCoordinator(navigationController: UINavigationController) -> ILMemorialCoordinator {
        ILMemorialCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - FamilyTree (Gia phả — no data source yet, see TD-FamilyTree-001)
    func makeFamilyTreeUseCase() -> ILFamilyTreeUseCase {
        ILFamilyTreeUseCaseImpl()
    }

    func makeFamilyTreeViewModel() -> ILFamilyTreeViewModel {
        // @ai: tech debt — placeholder viewer, see TD-FamilyTree-010
        ILFamilyTreeViewModel(
            useCase: makeFamilyTreeUseCase(),
            viewerResolver: ILPlaceholderFamilyTreeViewerResolver()
        )
    }

    func makeFamilyTreeCoordinator(navigationController: UINavigationController) -> ILFamilyTreeCoordinator {
        ILFamilyTreeCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - FamilyTreeCreate (Tạo gia phả — save has no data source yet, see TD-FamilyTreeCreate-001)
    func makeFamilyTreeCreateUseCase() -> ILFamilyTreeCreateUseCase {
        ILFamilyTreeCreateUseCaseImpl()
    }

    func makeFamilyTreeCreateViewModel() -> ILFamilyTreeCreateViewModel {
        ILFamilyTreeCreateViewModel(useCase: makeFamilyTreeCreateUseCase())
    }

    func makeFamilyTreeCreateCoordinator(navigationController: UINavigationController) -> ILFamilyTreeCreateCoordinator {
        ILFamilyTreeCreateCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - FamilyTreeAddMember (Thêm người vào gia phả — save has no data source yet, see TD-FamilyTreeAddMember-001)
    func makeFamilyTreeAddMemberUseCase() -> ILFamilyTreeAddMemberUseCase {
        ILFamilyTreeAddMemberUseCaseImpl()
    }

    func makeFamilyTreeAddMemberViewModel(
        tree: ILFamilyTreeEntity,
        relativeID: String,
        relation: ILFamilyAddRelation
    ) -> ILFamilyTreeAddMemberViewModel {
        ILFamilyTreeAddMemberViewModel(
            useCase: makeFamilyTreeAddMemberUseCase(), tree: tree, relativeID: relativeID, relation: relation
        )
    }

    func makeFamilyTreeAddMemberCoordinator(
        navigationController: UINavigationController,
        tree: ILFamilyTreeEntity,
        relativeID: String,
        relation: ILFamilyAddRelation
    ) -> ILFamilyTreeAddMemberCoordinator {
        ILFamilyTreeAddMemberCoordinator(
            navigationController: navigationController, container: self,
            tree: tree, relativeID: relativeID, relation: relation
        )
    }

    // MARK: - FamilyTreeMember (Hồ sơ thành viên — save has no data source yet, see TD-FamilyTreeMember-001)
    func makeFamilyTreeMemberUseCase() -> ILFamilyTreeMemberUseCase {
        ILFamilyTreeMemberUseCaseImpl()
    }

    func makeFamilyTreeMemberViewModel(
        tree: ILFamilyTreeEntity,
        memberID: String,
        kinship: String?
    ) -> ILFamilyTreeMemberViewModel {
        ILFamilyTreeMemberViewModel(
            useCase: makeFamilyTreeMemberUseCase(), tree: tree, memberID: memberID, kinship: kinship
        )
    }

    func makeFamilyTreeMemberCoordinator(
        navigationController: UINavigationController,
        tree: ILFamilyTreeEntity,
        memberID: String,
        kinship: String?
    ) -> ILFamilyTreeMemberCoordinator {
        ILFamilyTreeMemberCoordinator(
            navigationController: navigationController, container: self,
            tree: tree, memberID: memberID, kinship: kinship
        )
    }

    // MARK: - FamilyTreeChronicle (Phả ký dòng họ — save has no data source yet, see TD-FamilyTreeChronicle-001)
    func makeFamilyTreeChronicleUseCase() -> ILFamilyTreeChronicleUseCase {
        ILFamilyTreeChronicleUseCaseImpl()
    }

    func makeFamilyTreeChronicleViewModel(
        trees: [ILFamilyTreeEntity],
        initialTreeID: String
    ) -> ILFamilyTreeChronicleViewModel {
        ILFamilyTreeChronicleViewModel(
            useCase: makeFamilyTreeChronicleUseCase(), trees: trees, initialTreeID: initialTreeID
        )
    }

    func makeFamilyTreeChronicleCoordinator(
        navigationController: UINavigationController,
        trees: [ILFamilyTreeEntity],
        initialTreeID: String
    ) -> ILFamilyTreeChronicleCoordinator {
        ILFamilyTreeChronicleCoordinator(
            navigationController: navigationController, container: self,
            trees: trees, initialTreeID: initialTreeID
        )
    }

    // MARK: - Festivals
    func makeFestivalsUseCase() -> ILFestivalsUseCase {
        ILFestivalsUseCaseImpl(calendarEventRepository: makeCalendarEventRepository())
    }

    func makeFestivalsViewModel() -> ILFestivalsViewModel {
        ILFestivalsViewModel(useCase: makeFestivalsUseCase())
    }

    func makeFestivalsCoordinator(navigationController: UINavigationController) -> ILFestivalsCoordinator {
        ILFestivalsCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Festival detail
    func makeFestivalDetailUseCase() -> ILFestivalDetailUseCase {
        ILFestivalDetailUseCaseImpl(calendarEventRepository: makeCalendarEventRepository())
    }

    func makeFestivalDetailViewModel(eventCode: String, date: Date) -> ILFestivalDetailViewModel {
        ILFestivalDetailViewModel(useCase: makeFestivalDetailUseCase(), eventCode: eventCode, date: date)
    }

    func makeFestivalDetailCoordinator(
        navigationController: UINavigationController,
        eventCode: String,
        date: Date
    ) -> ILFestivalDetailCoordinator {
        ILFestivalDetailCoordinator(
            navigationController: navigationController,
            container: self,
            eventCode: eventCode,
            date: date
        )
    }

    // MARK: - Temple
    func makeTempleUseCase() -> ILTempleUseCase {
        ILTempleUseCaseImpl(templeRepository: makeTempleRepository())
    }

    func makeTempleViewModel(templeID: String) -> ILTempleViewModel {
        ILTempleViewModel(useCase: makeTempleUseCase(), templeID: templeID)
    }

    func makeTempleCoordinator(navigationController: UINavigationController, templeID: String) -> ILTempleCoordinator {
        ILTempleCoordinator(navigationController: navigationController, container: self, templeID: templeID)
    }

    // MARK: - Profile
    func makeProfileUseCase() -> ILProfileUseCase {
        ILProfileUseCaseImpl(
            accountRepository: ILAccountProfileRepositoryImpl(networkService: networkService),
            logoutRepository: ILLogoutRepositoryImpl(networkService: networkService),
            keychainService: keychainService,
            sessionDataCleaner: ILSessionDataCleanerImpl(stack: coreDataStack),
            userDefaultsService: userDefaultsService,
            accountScopedDefaultsKeys: [
                ILSanghaUseCaseImpl.myTempleKey,
                ILSanghaUseCaseImpl.myTempleSnapshotKey
            ]
        )
    }

    func makeProfileViewModel() -> ILProfileViewModel {
        ILProfileViewModel(useCase: makeProfileUseCase())
    }

    func makeProfileCoordinator(navigationController: UINavigationController) -> ILProfileCoordinator {
        ILProfileCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Settings
    func makeSettingsUseCase() -> ILSettingsUseCase {
        ILSettingsUseCaseImpl(languageUseCase: makeLanguageUseCase())
    }

    func makeSettingsViewModel() -> ILSettingsViewModel {
        ILSettingsViewModel(useCase: makeSettingsUseCase())
    }

    func makeSettingsCoordinator(navigationController: UINavigationController) -> ILSettingsCoordinator {
        ILSettingsCoordinator(navigationController: navigationController, container: self)
    }

    // MARK: - Language
    func makeLanguageUseCase() -> ILLanguageUseCase {
        ILLanguageUseCaseImpl(userDefaultsService: userDefaultsService, themeService: themeService)
    }

    func makeLanguageViewModel() -> ILLanguageViewModel {
        ILLanguageViewModel(useCase: makeLanguageUseCase())
    }

    func makeLanguageCoordinator(navigationController: UINavigationController) -> ILLanguageCoordinator {
        ILLanguageCoordinator(navigationController: navigationController, container: self)
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

    // MARK: - MeritBook (sample data, in-memory — no donation API yet)
    /// Shared instance so "Dừng hộ trì hằng tháng" survives leaving and re-entering the screen.
    lazy var meritBookRepository: ILMeritBookRepository = ILMeritBookRepositoryImpl()

    func makeMeritBookRepository() -> ILMeritBookRepository {
        meritBookRepository
    }

    func makeMeritBookUseCase() -> ILMeritBookUseCase {
        ILMeritBookUseCaseImpl(repository: makeMeritBookRepository())
    }

    func makeMeritBookViewModel() -> ILMeritBookViewModel {
        ILMeritBookViewModel(useCase: makeMeritBookUseCase())
    }

    func makeMeritBookCoordinator(navigationController: UINavigationController) -> ILMeritBookCoordinator {
        ILMeritBookCoordinator(navigationController: navigationController, container: self)
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
