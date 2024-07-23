//
import SwiftUI

@main
struct HeadwayDemoApp: App {
   
    var body: some Scene {
        WindowGroup {
            BookSummaryView(store: .init(initialState: .init(), reducer: {
                BookSummaryFeature()
            }))
        }
    }
}
