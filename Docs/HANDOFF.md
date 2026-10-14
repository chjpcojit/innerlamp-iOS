# Handoff — 2026-10-13 11:55
<!-- tự sinh khi kết thúc phiên 5985ad76 bằng claude-haiku-4-5-20251001; /handoff để ghi bản chất lượng cao hơn -->

## Đang làm dở
- Unit test - chặn bởi GRPCProtobufGenerator, build-for-testing chưa chạy được

## Việc tiếp theo
1. Fix GRPCProtobufGenerator & chạy unit test toàn bộ
2. Device test FestivalDetail + Festivals + lazy var refactor (FestivalDetail UI xong, cần test toàn flow)

## Tồn đọng / blocker
- GRPCProtobufGenerator chặn build-for-testing - unit test không chạy được
- Transcript bị cắt ('...Một điều nên kiểm tra thêm: cò') - chưa rõ work item nào chưa xong

## Quyết định gần đây
- ILColors.link cho viền DateCard - tự động light/dark mode, dễ maintain hơn vàng cố định
- radiusPill động = height/2 thay vì constant 999 - giải quyết lỗi mất nền và viền
- Khóa label width (content hugging priority) để viên sát phải - khắc phục khoảng trống dồn vào label

## Nợ tài liệu (tự động)
Code đã đổi nhưng chưa có concept OKF nào trỏ tới (dùng skill `il-okf-writer` sau khi code đã kiểm chứng):
- InnerLamp/App/ (3 file: AppCoordinator.swift, DIContainer.swift, SceneDelegate.swift)
- InnerLamp/Core/Base/Animation/ (1 file: ILEntranceAnimator.swift)
- InnerLamp/Core/Base/ (2 file: BaseNavigationController.swift, BaseViewController.swift)
- InnerLamp/Core/Base/Transition/ (1 file: TransitionProviding.swift)
- InnerLamp/Core/GRPC/ (6 file: GRPCAuthInterceptor.swift, GRPCConfiguration.swift, GRPCError.swift, +3 file)
- InnerLamp/Core/Logging/ (1 file: SentryLoggingService.swift)
- InnerLamp/Core/Networking/ (3 file: APIConfig.swift, AuthSessionRefresher.swift, AuthTokenProvider.swift)
- InnerLamp/Core/Utils/ (2 file: ILLunarCalendar.swift, String+PathSegment.swift)
- InnerLamp/Data/DataSources/Local/ (11 file: ILBuddhistEventLocalDataSource.swift, ILBuddhistEventTemplateMO.swift, ILCatalogCache.swift, +8 file)
- InnerLamp/Data/DataSources/Remote/ (25 file: AdministrativeProvincesEndpoint.swift, AdministrativeWardsEndpoint.swift, ArticleDetailEndpoint.swift, +22 file)
- InnerLamp/Data/DTOs/ (14 file: ILAdministrativeUnitDTO.swift, ILArticleDTO.swift, ILCalendarEventsDTO.swift, +11 file)
- InnerLamp/Data/DTOs/Mappers/ (12 file: ILAccountProfileMapper.swift, ILAdministrativeUnitMapper.swift, ILArticleMapper.swift, +9 file)
- InnerLamp/Data/Repositories/ (18 file: ILAccountProfileRepositoryImpl.swift, ILAdministrativeUnitRepositoryImpl.swift, ILArticleRepositoryImpl.swift, +15 file)
- InnerLamp/Domain/Entities/ (34 file: ILAccountProfileEntity.swift, ILAdministrativeUnitEntity.swift, ILArticleEntity.swift, +31 file)
- InnerLamp/Domain/Repositories/ (17 file: ILAccountProfileRepository.swift, ILAdministrativeUnitRepository.swift, ILArticleRepository.swift, +14 file)
- InnerLamp/Domain/UseCases/AddTemple/ (1 file: ILAddTempleUseCase.swift)
- InnerLamp/Domain/UseCases/Article/ (1 file: ILArticleUseCase.swift)
- InnerLamp/Domain/UseCases/Articles/ (1 file: ILArticlesUseCase.swift)
- InnerLamp/Domain/UseCases/BuddhistEvent/ (1 file: ILBuddhistEventUseCase.swift)
- InnerLamp/Domain/UseCases/Deities/ (1 file: ILDeitiesUseCase.swift)
- ... +110 thư mục khác
