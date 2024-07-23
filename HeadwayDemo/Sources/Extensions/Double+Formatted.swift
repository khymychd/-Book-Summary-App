//

import Foundation

extension Double {
    
    var formattedAsTime: String {
        let formatter: DateComponentsFormatter = .init()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(self)) ?? "00:00"
    }
}
