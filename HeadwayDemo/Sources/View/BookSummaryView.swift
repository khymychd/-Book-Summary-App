//

import ComposableArchitecture
import SwiftUI

fileprivate extension Binding {
    
    static func getter(_ value: Value) -> Binding<Value> {
        .init(get: { value }, set: { _ in })
    }
}

struct BookSummaryView: View {
    
    let store: StoreOf<BookSummaryFeature>
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            posterView
            WithPerceptionTracking {
                VStack {
                    keyPointView
                    playerView
                }
                .disabled(store.hasError)
                .padding(.horizontal)
            }
            .padding(.bottom, 64)
        }
        .background(
            colorScheme == .dark ? Color.mainBackgroundDark : Color.mainBackground
        )
        .overlay(alignment: .bottom, content: {
            HDToggleView()
                .padding(.bottom, 8)
        })
        .onAppear {
            store.send(.onAppear)
        }
        .alert(store: self.store.scope(state: \.$errorAlert, action: \.alert))
    }
    
    var keyPointView: some View {
        WithPerceptionTracking {
            VStack {
                Text("playerView.keyPoint".localizedWithArguments("\(store.currentChapterNumber + 1)", "\(store.numberOfChapters)"))
                    .font(.subheadline)
                    .foregroundColor(.secondaryForeground)
                Text(store.currentChapter.keyPoint)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .frame(height: 64)
            }
        }
    }
    
    private var posterView: some View {
        Image("bookCoverage")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(6)
            .padding(32)
    }
    
    private var playerView: some View {
        WithViewStore(store, observe: { $0 }) { state in
            HDPlayerView(
                isPlaying: .getter(state.isPlaying),
                hasBackward:  .getter(state.hasBackward),
                hasForward: .getter(state.hasForward),
                isLoading: .getter(state.isLoading),
                playbackSpeed: .getter(state.playbackSpeed.rawValue),
                currentTime: .init(get: {state.currentTime },set: { store.send(.seekTo($0)) }),
                duration: .getter(state.duration),
                action: handlePlayerViewAction(_:)
            )
        }
    }
    
    private func handlePlayerViewAction(_ action: HDPlayerView.Action) {
        switch action {
        case .play:
            store.send(.play)
        case .pause:
            store.send(.pause)
        case .backward:
            store.send(.backward)
        case .gobackward:
            store.send(.gobackward)
        case .goforward:
            store.send(.goforward)
        case .forward:
            store.send(.forward)
        case .speed:
            store.send(.speed)
        case .beginEditing:
            store.send(.beginEditing)
        case .endEditing:
            store.send(.endEditing)
        }
    }
}

#Preview {
    BookSummaryView(store: .init(initialState: .init(), reducer: {
        BookSummaryFeature()
    }))
}
