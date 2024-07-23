//

import AVFoundation
import Combine
import Dependencies

struct AudioPlayerClient: DependencyKey {
    
    var configurePlayer: @Sendable () -> Result<Void, Player.AudioPlayerError>
    var setupPlayer: @Sendable (URL) async throws -> Void
    var play: @Sendable () -> Void
    var pause: @Sendable () -> Void
    var setPlaybackRate: @Sendable (Float) -> Void
    var skipForward: @Sendable (Double) -> Void
    var skipBackward: @Sendable (Double) -> Void
    var seek: @Sendable (TimeInterval) async -> Void
    var eventPublisher: AnyPublisher<Player.Event, Never>
    var duration: @Sendable () -> TimeInterval
    var currentTime: @Sendable () -> TimeInterval
    
    static var liveValue: AudioPlayerClient {
        let player = Player()
        return .init(
            configurePlayer: { player.configurePlayer() },
            setupPlayer: { try await player.setupPlayer(for: $0) },
            play: { player.play() },
            pause: { player.pause() },
            setPlaybackRate: { player.setPlaybackRate($0) },
            skipForward: { player.skipForward(to: $0) },
            skipBackward: { player.skipBackward(to: $0) },
            seek: { await player.seek(to: $0) },
            eventPublisher: player.eventPublisher,
            duration: { player.duration },
            currentTime: { player.currentTime }
        )
    }
    
    static var previewValue: AudioPlayerClient {
        .init(
            configurePlayer: { .success(()) },
            setupPlayer: { _ in },
            play: {  },
            pause: {   },
            setPlaybackRate: { _ in  },
            skipForward: { _ in },
            skipBackward: {  _ in },
            seek: { _ in },
            eventPublisher: Just(.pause).eraseToAnyPublisher(),
            duration: { 120 },
            currentTime: { 60 }
        )
    }
}

class Player {
    
    enum AudioPlayerError: Error, CustomStringConvertible, Equatable {
        
        case failedToConfigureSession(error: Error)
        case playerNotInitialized
        case failedToLoadFile
        case failedToDecodeFile(error: Error)
        case failedToPlayToEnd(error: Error)
        case playbackStalled
        case unknownError
        
        var description: String {
            switch self {
            case .failedToConfigureSession(let error):
                return "player.error.failedToLoadFile".localizedWithArguments(error.localizedDescription)
            case .playerNotInitialized:
                return "player.error.playerNotInitialized".localized
            case .failedToLoadFile:
                return "player.error.failedToLoadFile".localized
            case .failedToDecodeFile(let error):
                return "player.error.failedToDecodeFile".localizedWithArguments(error.localizedDescription)
            case .failedToPlayToEnd(let error):
                return "player.error.failedToPlayToEnd".localizedWithArguments(error.localizedDescription)
            case .playbackStalled:
                return "player.error.playbackPaused".localized
            case .unknownError:
                return "player.error.unknownError".localized
            }
        }
        
        static func == (lhs: Player.AudioPlayerError, rhs: Player.AudioPlayerError) -> Bool {
            lhs.description == rhs.description
        }
    }
    
    enum Event {
        case play
        case pause
        case errorOccurred(AudioPlayerError)
    }
    
    private let session: AVAudioSession = .sharedInstance()
    private let player: AVPlayer = .init()
    private(set) var duration: Double = .zero
    private var currentRate: Float = 1.0
    
    private var bag: Set<AnyCancellable> = .init()
    private let eventSubject: PassthroughSubject<Event, Never> = .init()
    
    var eventPublisher: AnyPublisher<Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    var currentTime: Double {
        player.currentTime().seconds
    }
    
    func configurePlayer() -> Result<Void, AudioPlayerError> {
        do {
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            return .success(())
        } catch {
            return .failure(.failedToConfigureSession(error: error))
        }
    }
    
    private func subscribeOnNotifications() {
        bag.removeAll()
        let notificationCenter = NotificationCenter.default
        // Interruption Notification
        let notificationNames: Set<Notification.Name> = [
            AVAudioSession.interruptionNotification,
            AVAudioSession.routeChangeNotification,
            .AVPlayerItemFailedToPlayToEndTime,
            .AVPlayerItemPlaybackStalled
        ]
        Publishers.MergeMany(notificationNames.map { notificationCenter.publisher(for: $0 )})
            .sink { [weak self] notification in
                guard let self else { return }
                self.handle(notification: notification)
            }
            .store(in: &bag)
    }
    
    private func handle(notification: Notification) {
        switch notification.name {
        case AVAudioSession.interruptionNotification:
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            switch type {
            case .began:
                eventSubject.send(.pause)
            case .ended:
                guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    eventSubject.send(.play)
                }
            @unknown default:
                fatalError()
            }
            
        case AVAudioSession.routeChangeNotification:
            guard
                let userInfo = notification.userInfo,
                let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
                reason == .oldDeviceUnavailable
            else {
                return
            }
            eventSubject.send(.pause)
        case .AVPlayerItemFailedToPlayToEndTime:
            let error = (notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error) ?? AudioPlayerError.unknownError
            eventSubject.send(.errorOccurred(.failedToPlayToEnd(error: error)))
        case .AVPlayerItemPlaybackStalled:
            eventSubject.send(.errorOccurred(.playbackStalled))
        default:
            break
        }
    }
    
    func setupPlayer(for url: URL) async throws {
        player.pause()
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        let item = AVPlayerItem(asset: asset)
        self.duration = duration.seconds
        player.replaceCurrentItem(with: item)
    }
    
    func play() {
        player.playImmediately(atRate: currentRate)
    }
    
    func pause() {
        player.pause()
    }
    
    func setPlaybackRate(_ rate: Float) {
        currentRate = rate
        player.rate = rate
    }
    
    func skipForward(to seconds: Double) {
        let currentTime = player.currentTime()
        let tenSecondsForward = CMTimeAdd(currentTime, CMTime(seconds: seconds, preferredTimescale: 1))
        player.seek(to: tenSecondsForward)
    }
    
    func skipBackward(to seconds: Double) {
        let currentTime = player.currentTime()
        let fiveSecondsBackward = CMTimeSubtract(currentTime, CMTime(seconds: seconds, preferredTimescale: 1))
        player.seek(to: fiveSecondsBackward)
    }
    
    func seek(to timeInterval: TimeInterval) async {
        let targetTime = CMTimeMake(value: Int64(timeInterval), timescale: 1)
        await player.seek(to: targetTime)
    }
}
