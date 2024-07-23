//

import Foundation

extension String {
    
    var localized: String {
       NSLocalizedString(self, comment: "")
    }
    
    func localizedWithArguments(_ args: CVarArg...) -> String {
        argumented(args)
    }
    
    func argumented(_ args: [CVarArg]) -> String {
        String(format: self.localized, args)
    }
}
