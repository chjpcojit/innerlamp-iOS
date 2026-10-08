# Handoff — 2026-10-08 18:09
<!-- tự sinh khi kết thúc phiên 11892a09 bằng claude-haiku-4-5-20251001; /handoff để ghi bản chất lượng cao hơn -->

## Đang làm dở
- Kiểm chứng blur fix + overlay trên thiết bị (dừng: build OK, chưa chạy app)
- Điều tra API 401 trang sổ giỗ chạp: backend tới được, xử lý token OK, cần xác định nguyên nhân thực

## Việc tiếp theo
1. Test blur fix và overlay trang chủ trên device thật
2. Xác định nguyên nhân API lỗi sổ giỗ chạp: token hết hạn, host unreachable hay server error
3. Giải quyết gRPC GRPCProtobufGenerator blocker unit test ⌘U

## Tồn đọng / blocker
- gRPC plugin GRPCProtobufGenerator chặn unit test ⌘U
- ILSettingsUseCase.swift:28 missing return statement
- API 401 sổ giỗ chạp - backend tới được, token handling ổn nhưng nguyên nhân chưa xác định

## Quyết định gần đây
- Blur ở top camera là scroll edge effect iOS 26 mặc định - tắt bằng topEdgeEffect.isHidden = true
- Overlay lịch âm: giảm alpha để thấy ảnh nhưng text vẫn rõ
- Đưa topEdgeEffect fix vào BaseViewController áp dụng toàn ứng dụng

## Nợ tài liệu (tự động)
Code đã đổi nhưng chưa có concept OKF nào trỏ tới (dùng skill `il-okf-writer` sau khi code đã kiểm chứng):
- InnerLamp/App/ (3 file: AppCoordinator.swift, DIContainer.swift, SceneDelegate.swift)
- InnerLamp/Core/Base/Animation/ (1 file: ILEntranceAnimator.swift)
- InnerLamp/Core/Base/ (2 file: BaseNavigationController.swift, BaseViewController.swift)
- InnerLamp/Core/Base/Transition/ (1 file: TransitionProviding.swift)
- InnerLamp/Core/GRPC/ (6 file: GRPCAuthInterceptor.swift, GRPCConfiguration.swift, GRPCError.swift, +3 file)
- InnerLamp/Core/Logging/ (1 file: SentryLoggingService.swift)
- InnerLamp/Core/Networking/ (2 file: APIConfig.swift, AuthSessionRefresher.swift)
- InnerLamp/Core/Utils/ (2 file: ILLunarCalendar.swift, String+PathSegment.swift)
- InnerLamp/Data/DataSources/Local/ (9 file: ILBuddhistEventLocalDataSource.swift, ILBuddhistEventTemplateMO.swift, ILCatalogCache.swift, +6 file)
- InnerLamp/Data/DataSources/Remote/ (18 file: ArticleDetailEndpoint.swift, ArticlesPageEndpoint.swift, CalendarImageEndpoint.swift, +15 file)
- InnerLamp/Data/DTOs/ (9 file: ILArticleDTO.swift, ILCalendarImageDTO.swift, ILCatalogListDTO.swift, +6 file)
- InnerLamp/Data/DTOs/Mappers/ (7 file: ILArticleMapper.swift, ILCalendarImageMapper.swift, ILDeityMapper.swift, +4 file)
- InnerLamp/Data/Repositories/ (9 file: ILArticleRepositoryImpl.swift, ILCalendarImageRepositoryImpl.swift, ILCatalogErrorMapping.swift, +6 file)
- InnerLamp/Domain/Entities/ (23 file: ILArticleEntity.swift, ILArticlesEntity.swift, ILBuddhistEventEntity.swift, +20 file)
- InnerLamp/Domain/Repositories/ (8 file: ILArticleRepository.swift, ILCalendarImageRepository.swift, ILCatalogError.swift, +5 file)
- InnerLamp/Domain/UseCases/Article/ (1 file: ILArticleUseCase.swift)
- InnerLamp/Domain/UseCases/Articles/ (1 file: ILArticlesUseCase.swift)
- InnerLamp/Domain/UseCases/BuddhistEvent/ (1 file: ILBuddhistEventUseCase.swift)
- InnerLamp/Domain/UseCases/Deities/ (1 file: ILDeitiesUseCase.swift)
- InnerLamp/Domain/UseCases/Deity/ (1 file: ILDeityUseCase.swift)
- ... +76 thư mục khác
