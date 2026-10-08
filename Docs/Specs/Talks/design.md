# Talks — Design (v1.1)

MVVM-C. `ILLibraryCoordinator.showTalks()` → `ILTalksCoordinator` → `ILTalksViewController`.
`ILTalksUseCase.getTalks()` returns an 8-talk mock catalog (`ILTalkListItemEntity`, matching the
design handoff `TALK_LIST`) and `filter(_:by:)` is pure. The ViewModel holds the selected
`ILTalkFilter` and republishes `ViewState<ILTalksStateModel>`, formatting eyebrow/meta/progress.
Reuses `ILNavBar`, `ILChipScrollView`, `ILStateView`, `ILColors.Tone.rose`; new icons
`ILIcons.talkAudio/talkVideo/talkText`. Taps forward to `ILTalkCoordinator`. No network call yet.
