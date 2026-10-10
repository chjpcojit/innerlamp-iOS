# Handoff — 2026-10-10 17:08
<!-- tự sinh khi kết thúc phiên c9b24956 bằng claude-haiku-4-5-20251001; /handoff để ghi bản chất lượng cao hơn -->

## Đang làm dở
- Test dropdown trên device: mở/đóng mượt, chạm item đúng vùng, checkbox không bị đè, danh sách không bị cắt
- Cập nhật SRS SignUp: xác nhận gửi tên chùa hay id, quyết định chạy spec-writer hay chỉ sửa SRS

## Việc tiếp theo
1. User xác nhận 2 câu SRS SignUp, cập nhật rồi chạy spec-writer
2. Test Home icons, tràng hạt, icon hàng, font lnum trên device thật
3. Chạy unit test / build toàn project, kiểm tra không break, xác nhận contract API

## Tồn đọng / blocker
- ⚠️ Not confirmed: Contract FAQ endpoint, contact submit endpoint, legal content API
- gRPC plugin GRPCProtobufGenerator chặn ⌘U
- ILSettingsUseCase.swift:28 missing return statement
- API 401 sổ giỗ chạp - nguyên nhân chưa xác định
- Prototype SignUp không khớp app: design dùng bottom sheet, code hiện dùng dropdown nổi

## Quyết định gần đây
- Dropdown 'Nơi xuất gia' nổi đè lên form, không đẩy, không giật khi đóng — bảo vệ UX scroll form
- Cormorant luôn dùng Number Case = Upper Case Numbers (lnum feature) — khớp Design System spec
- ILRow dùng icon thật từ glyph thay vẽ hình trừu tượng — cải thiện UI consistency

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
- InnerLamp/Data/DataSources/Local/ (9 file: ILBuddhistEventLocalDataSource.swift, ILBuddhistEventTemplateMO.swift, ILCatalogCache.swift, +6 file)
- InnerLamp/Data/DataSources/Remote/ (18 file: ArticleDetailEndpoint.swift, ArticlesPageEndpoint.swift, CalendarImageEndpoint.swift, +15 file)
- InnerLamp/Data/DTOs/ (10 file: ILArticleDTO.swift, ILCalendarImageDTO.swift, ILCatalogListDTO.swift, +7 file)
- InnerLamp/Data/DTOs/Mappers/ (7 file: ILArticleMapper.swift, ILCalendarImageMapper.swift, ILDeityMapper.swift, +4 file)
- InnerLamp/Data/Repositories/ (9 file: ILArticleRepositoryImpl.swift, ILCalendarImageRepositoryImpl.swift, ILCatalogErrorMapping.swift, +6 file)
- InnerLamp/Domain/Entities/ (25 file: ILArticleEntity.swift, ILArticlesEntity.swift, ILBuddhistEventEntity.swift, +22 file)
- InnerLamp/Domain/Repositories/ (8 file: ILArticleRepository.swift, ILCalendarImageRepository.swift, ILCatalogError.swift, +5 file)
- InnerLamp/Domain/UseCases/AddTemple/ (1 file: ILAddTempleUseCase.swift)
- InnerLamp/Domain/UseCases/Article/ (1 file: ILArticleUseCase.swift)
- InnerLamp/Domain/UseCases/Articles/ (1 file: ILArticlesUseCase.swift)
- InnerLamp/Domain/UseCases/BuddhistEvent/ (1 file: ILBuddhistEventUseCase.swift)
- InnerLamp/Domain/UseCases/Deities/ (1 file: ILDeitiesUseCase.swift)
- ... +88 thư mục khác
