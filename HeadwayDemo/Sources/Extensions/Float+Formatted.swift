//

import Foundation

extension Float {
    
    var formatted: String {
        if self == floor(self) {
            return String(format: "%.0f", self)
        }
        return String(self)
    }
}
