//

import ComposableArchitecture
import Foundation

@Reducer
struct BookSummaryFeature {
    
    @ObservableState
    struct State: Equatable {
        
        var currentChapterNumber = 0
        
        var numberOfChapters: Int {
            chapters.count
        }
        
        var chapters: [Chapter] = .allChapters
        var currentChapter: Chapter {
            chapters[currentChapterNumber]
        }
        
        var isPlaying = false
        var isLoading = false
        
        var progress: Float = 0.5
        var playbackSpeed: PlaybackSpeed = .one
        
        var currentTime: TimeInterval = .zero
        var duration: TimeInterval = 1
        
        var hasBackward: Bool {
            currentChapterNumber > 0
        }
        
        var hasForward: Bool {
            currentChapterNumber < chapters.count - 1
        }
        
        var hasError: Bool = false
        
        @Presents
        var errorAlert: AlertState<Action.Alert>?
    }
    
    enum Action: Equatable {
        case pause
        case play
        case backward
        case gobackward
        case goforward
        case forward
        case speed
        case finishedPlaying
        case beginEditing
        case endEditing
        
        case seekTo(TimeInterval)
        
        case fetchResource
        case readyToPlay
        case failedToLoadResource
        
        case updatedCurrentTime(Double)
        case runTimer
        
        case onAppear
        case errorOccurred(Player.AudioPlayerError)
        
        case closeAlert
        
        case alert(PresentationAction<Alert>)
        
        enum Alert: Equatable {}
    }
    
    enum PlaybackSpeed: Float, CaseIterable {
        case half = 0.5
        case one = 1.0
        case oneAndHalf = 1.5
        case two = 2.0
        case twoAndHalf = 2.5
        
        static var allCases: [PlaybackSpeed] {
            return [.half, .one, .oneAndHalf, .two, .twoAndHalf]
        }
        
        var next: PlaybackSpeed {
            let allSpeeds = PlaybackSpeed.allCases
            if let currentIndex = allSpeeds.firstIndex(of: self) {
                let nextIndex = (currentIndex + 1) % allSpeeds.count
                return allSpeeds[nextIndex]
            }
            return self
        }
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.audioPlayer) var player
    
    private enum CancelId: Int, Hashable {
        case timer
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .alert:
                return .none
            case .onAppear:
                let result = player.configurePlayer()
                switch result {
                case .success:
                    return .send(.fetchResource)
                        .merge(with: .publisher {
                            player.eventPublisher.map {
                                switch $0 {
                                case .pause:
                                    return .pause
                                case .play:
                                    return .play
                                case .errorOccurred(let playerError):
                                    return .errorOccurred(playerError)
                                }
                            }
                        })
                case .failure(let error):
                    return .send(.errorOccurred(error))
                }
            case .play:
                player.play()
                state.isPlaying = true
                return .send(.runTimer)
            case .pause:
                player.pause()
                state.isPlaying = false
                return .cancel(id: CancelId.timer)
            case .fetchResource:
                if state.isPlaying {
                    player.pause()
                }
                state.isLoading = true
                guard let url = Bundle.main.url(forResource: state.currentChapter.sourceURL, withExtension: nil) else {
                    state.isLoading = false
                    return .send(.errorOccurred(.failedToLoadFile))
                }
                return .run(operation: { send in
                    try await player.setupPlayer(url)
                    await send.callAsFunction(.readyToPlay)
                }, catch: { error, send in
                    await send.callAsFunction(.errorOccurred(.failedToDecodeFile(error: error)))
                })
            case .backward:
                if state.hasBackward {
                    state.currentChapterNumber -= 1
                    return .send(.fetchResource)
                }
                return .none
            case .gobackward:
                player.skipBackward(5)
                return .none
            case .goforward:
                player.skipForward(10)
                return .none
            case .forward:
                if state.hasForward {
                    state.currentChapterNumber += 1
                    return .send(.fetchResource)
                }
                return .none
            case .speed:
                let nextSpeed = state.playbackSpeed.next
                player.setPlaybackRate(nextSpeed.rawValue)
                state.playbackSpeed = nextSpeed
                return .none
            case .readyToPlay:
                state.duration = player.duration()
                state.isLoading = false
                return .send(.play)
            case .failedToLoadResource:
                return .none
            case .finishedPlaying:
                state.currentTime = .zero
                if state.hasForward {
                    return .send(.forward)
                }
                return .run(operation: { send in
                    await player.seek(.zero)
                    await send.callAsFunction(.pause)
                })
            case .beginEditing:
                return .cancel(id: CancelId.timer)
            case .endEditing:
                let currentTime = state.currentTime
                return .run { send in
                    await player.seek(currentTime)
                    await send.callAsFunction(.runTimer)
                }
            case .seekTo(let time):
                state.currentTime = time
                return .none
            case .updatedCurrentTime(let newValue):
                state.currentTime = newValue
                if floor(newValue) >= floor(state.duration){
                    return .send(.finishedPlaying)
                }
                return .none
            case .runTimer:
                return
                    .cancel(id: CancelId.timer)
                    .merge(with:
                            .run { send in
                                for await _ in self.clock.timer(interval: .seconds(0.25)) {
                                    let currentTime = player.currentTime()
                                    await send(.updatedCurrentTime(currentTime))
                                }
                            }
                        .cancellable(id: CancelId.timer)
                    )
            case .errorOccurred(let error):
                state.hasError = true
                state.errorAlert = AlertState(
                    title: { .init("errorAlert.title".localized)  },
                    actions: { .cancel(.init("errorAlert.cancelTitle".localized))},
                    message: { .init(error.description) }
                )
                return .cancel(id: CancelId.timer)
            case .closeAlert:
                state.errorAlert = nil
                return .none
            }
        }
    }
}
