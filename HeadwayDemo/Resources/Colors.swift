//

import SwiftUI

extension Color {
    
    static var mainBackground: Color {
        let color: UIColor = #colorLiteral(red: 1, green: 0.9715417027, blue: 0.9548227191, alpha: 1)
        return Color(uiColor: color)
    }
    
    static var mainBackgroundDark: Color {
        let color: UIColor = #colorLiteral(red: 0.1333333254, green: 0.1333332956, blue: 0.1333333254, alpha: 1)
        return Color(uiColor: color)
    }
    
    static var controlTint: Color {
        let color: UIColor = #colorLiteral(red: 0.01443455089, green: 0.5933545828, blue: 0.9985713363, alpha: 1)
        return Color(uiColor: color)
    }
    
    static var controlForeground: Color {
        let color: UIColor = #colorLiteral(red: 0.3058823347, green: 0.3058823049, blue: 0.3058823347, alpha: 1)
        return Color(uiColor: color)
    }
    
    static var secondaryForeground: Color {
        let color: UIColor = #colorLiteral(red: 0.4745097756, green: 0.4745097756, blue: 0.4745097756, alpha: 1)
        return Color(uiColor: color)
    }
    
    static var secondaryActionForeground: Color {
        let color: UIColor = #colorLiteral(red: 0.21960783, green: 0.21960783, blue: 0.21960783, alpha: 1)
        return Color(uiColor: color)
    }
    
    static var toggleBorderColor: Color {
        let color: UIColor = #colorLiteral(red: 0.9098040462, green: 0.9098038077, blue: 0.9054959416, alpha: 1)
        return Color(uiColor: color)
    }
}
