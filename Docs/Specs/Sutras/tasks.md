# Sutras — Tasks (v1.2)

- [x] Entity, UseCase, StateModel, ViewModel, Coordinator, ViewController, Views
- [x] DIContainer + Library wiring (`.sutras` quick access)
- [x] Catalog API integration: DTO, Mapper, Endpoints, `ILSutraRepository` + Impl, paging, server filters, stale-response guard
- [x] Unit tests written: `ILSutrasViewModelTests`, `ILSutrasUseCaseTests`, `ILSutraRepositoryTests` (+ `ILSutraTestSupport`) — not run
- [ ] Run the unit tests (needs a device / simulator destination)
- [x] Server-side text search (`q`, debounced, TD-Sutras-003 resolved) · `audio_url` → "Có audio" badge
- [ ] "Downloaded" badge (needs the Downloads feature, TD-Sutras-002)
- [ ] Run the new/updated tests (`xcodebuild test` is blocked by the GRPCProtobufGenerator plugin prompt — enable it in Xcode once)
- [ ] Visual QA on device
