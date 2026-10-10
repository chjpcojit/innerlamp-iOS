# Handoff — 2026-10-10 19:58
<!-- tự sinh khi kết thúc phiên 5e791d02 bằng claude-haiku-4-5-20251001; /handoff để ghi bản chất lượng cao hơn -->

## Đang làm dở
- Unit test Splash: build-for-testing fail vì GRPCProtobufGenerator; chờ chạy ⌘U trên máy thật
- Quyết định has_completed_onboarding vs has_launched_before: user chưa xác nhận có thay đổi hay không

## Việc tiếp theo
1. Chạy unit test / test suite trên device khi GRPCProtobufGenerator được sửa
2. Test Splash flow toàn bộ: cài mới → Onboarding → Login; mất token → Login; refresh fail → Login
3. Test dropdown, Home icons, tràng hạt, icon hàng, lnum font trên device thật (từ handoff)

## Tồn đọng / blocker
- GRPCProtobufGenerator plugin chặn build-for-testing (handoff; chưa xong)
- ILSettingsUseCase.swift:28 missing return statement (handoff)
- API 401 sổ giỗ chạp - nguyên nhân chưa xác định (handoff)
- Not confirmed: Contract FAQ endpoint, contact submit endpoint, legal content API (handoff)
- Trường hợp biên: user mở lần đầu, kill giữa Onboarding, mở lại - cần quyết định giữ hay đổi flag

## Quyết định gần đây
- Splash: user đã onboard mà mất token → vào Login, không xem lại Onboarding - tốt hơn cho UX quay lại
- has_completed_onboarding được set khi xem xong Onboarding - giữ nguyên, user chưa đếm cao Onboarding lại hợp lý
- Token hết hạn: AuthSessionRefresher tự refresh, fail → xóa session → Login (đã xác nhận code)
- Dropdown 'Nơi xuất gia' nổi đè lên form, không đẩy, không giật khi đóng - bảo vệ UX scroll
- Cormorant dùng lnum (Upper Case Numbers) - khớp Design System spec
- ILRow dùng icon thật từ glyph - cải thiện UI consistency
- Refresh fail: AppCoordinator.handleSessionExpired() đưa về Login - đã có sẵn

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
