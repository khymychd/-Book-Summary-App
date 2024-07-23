//

import SwiftUI

struct HDToggleView: View {
    
    @State var isOn: Bool = true
    @Environment(\.colorScheme) var colorScheme
    
    var leadingIconName: String = "headphones"
    var trailingIconName: String = "text.alignleft"
    
    var body: some View {
        HStack(spacing: 24) {
            Image(systemName: leadingIconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.all, 6)
                .foregroundStyle(isOn ? Color.white : Color.black)
            
            Image(systemName: trailingIconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.all, 6)
                .foregroundStyle(!isOn ? Color.white : Color.black)
        }
        .padding()
        .background {
            ZStack(alignment: isOn ? .leading : .trailing) {
                RoundedRectangle(cornerRadius: 90)
                    .fill(colorScheme == .dark ? Color.secondaryActionForeground : Color.white)
                RoundedRectangle(cornerRadius: 90)
                    .stroke(Color.toggleBorderColor)
                
                Circle()
                    .fill(Color.controlTint)
                    .padding(.all, 2)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    withAnimation(.spring) {
                        self.isOn = value.translation.width < 0
                    }
                }
        )
        .onTapGesture {
            withAnimation(.spring) {
                isOn.toggle()
            }
        }
        .frame(height: 64)
    }
}

#Preview {
    HDToggleView()
}
