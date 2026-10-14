# Handoff — 2026-10-12 16:22
<!-- tự sinh khi kết thúc phiên 2f57f901 bằng claude-haiku-4-5-20251001; /handoff để ghi bản chất lượng cao hơn -->

## Đang làm dở
- Device test FestivalDetail 'Còn XX ngày' - chờ user xác định đúng khối trên app thật
- Unit test chặn bởi GRPCProtobufGenerator - chưa chạy build-for-testing được

## Việc tiếp theo
1. Xác định khối 'Còn XX ngày' trên sự kiện Ngày Phụ nữ Việt Nam, sửa UI nếu cần (border/trailing)
2. Device test FestivalDetail + Festivals + lazy var refactor toàn flow
3. Fix GRPCProtobufGenerator & chạy unit test toàn bộ

## Tồn đọng / blocker
- GRPCProtobufGenerator chặn build-for-testing - không chạy unit test được
- Chưa xác định chính xác khối UI 'Còn XX ngày' cần sửa - phụ thuộc xác nhận user

## Quyết định gần đây
- Dùng 'Còn XX ngày' thay 'còn 8 ngày' để debug xác định khối - phương pháp tạm thời, gỡ khi xong
- Thêm border cho viên 'còn N ngày' mặc dù prototype gốc không vẽ - tuân theo yêu cầu user
- Resolve màu viền theo trait để hỗ trợ dark/light mode - sửa tương tự ILFestivalDetailListCardView

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
