//

import Foundation

struct Chapter: Equatable {
    
    let id: Int
    let sourceURL: String
    let keyPoint: String
}

extension [Chapter] {
    
    static var allChapters: [Chapter] {
        [
            .init(id: 0, sourceURL: "mobydick_000_melville_64kb.mp3", keyPoint: "chapter.one.keyPoint".localized),
            .init(id: 1, sourceURL: "mobydick_001_002_melville_64kb.mp3", keyPoint: "chapter.two.keyPoint".localized),
            .init(id: 2, sourceURL: "mobydick_003_melville_64kb.mp3", keyPoint: "chapter.three.keyPoint".localized)
        ]
    }
}
