//

import SwiftUI

struct HDPlayerView: View {
    
    enum Action {
        case play
        case pause
        case backward
        case gobackward
        case goforward
        case forward
        case speed
        case beginEditing
        case endEditing
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding
    var isPlaying: Bool
    
    @Binding
    var hasBackward: Bool
    
    @Binding
    var hasForward: Bool
    
    @Binding
    var isLoading: Bool
    
    @Binding
    var playbackSpeed: Float
    
    @Binding
    var currentTime: TimeInterval
    
    @Binding
    var duration: TimeInterval
    
    var action: (Action) -> Void = { _ in }
        
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                progressView
                speedButton
            }
            controlButtonsStack
                .tint(.primary)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Subviews
private extension HDPlayerView {
    
    var speedButton: some View {
        Button {
            action(.speed)
        } label: {
            Text("playerView.playSpeed.button.title".localizedWithArguments("\(playbackSpeed.formatted)"))
                .foregroundColor(.primary)
                .font(.footnote)
                .padding(.vertical, 8)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial)
                )
        }
    }
    
    var progressView: some View {
        Slider(value: $currentTime, in: 0.0...duration, label: {
            EmptyView()
        }, minimumValueLabel: {
            Text(currentTime.formattedAsTime)
                .foregroundColor(.secondaryForeground)
                .font(.caption)
                .frame(width: 36)
        }, maximumValueLabel: {
            Text(duration.formattedAsTime)
                .foregroundColor(.secondaryForeground)
                .font(.caption)
                .frame(width: 36)
        }, onEditingChanged: { editing in
            action(editing ? .beginEditing : .endEditing)
        }
        )
        .tint(.controlTint)
    }
    
    var controlButtonsStack: some View {
        HStack(spacing: 2) {
            Button {
                action(.backward)
            } label: {
                image(with: "backward.end.fill", side: 20)
            }
            .disabled(!hasBackward)
            
            Button {
                action(.gobackward)
            } label: {
                image(with: "gobackward.5", side: 30)
            }
            
            Button {
                action(isPlaying ? .pause : .play)
            } label: {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: 30, height: 30)
                        .padding()
                } else {
                    image(with: isPlaying ? "pause.fill" : "play.fill", side: 30)
                }
            }
            .fixedSize()
            .disabled(isLoading)
            
            Button {
                action(.goforward)
            } label: {
                image(with: "goforward.10", side: 30)
            }
            Button {
                action(.forward)
            } label: {
                image(with: "forward.end.fill", side: 20)
            }
            .disabled(!hasForward)
        }
    }
    
    func image(with systemName: String, side: CGFloat) -> some View {
        Image(systemName: systemName)
            .resizable()
            .frame(width: side, height: side)
            .padding()
    }
}

#Preview {
    HDPlayerView(
        isPlaying: .constant(false),
        hasBackward: .constant(true),
        hasForward: .constant(false),
        isLoading: .constant(true),
        playbackSpeed: .constant(1.0),
        currentTime: .constant(10),
        duration: .constant(120)
    )
}
