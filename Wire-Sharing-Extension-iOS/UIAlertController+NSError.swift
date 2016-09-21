// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


import UIKit
import zshare

extension UIAlertController {

    convenience init(error: NSError, context:NSExtensionContext, actionHandler:@escaping () -> ()) {
        if let title = error.userInfo[NSLocalizedDescriptionKey] as? String,
            let message = error.userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String {
                self.init(title: title, message: message, preferredStyle:UIAlertControllerStyle.alert)
        } else {
            self.init(title: NSLocalizedString("sharing-ext.login.error.title", comment: ""),
                message: NSLocalizedString("sharing-ext.login.error.message", comment: ""),
                preferredStyle:UIAlertControllerStyle.alert)
        }
    
        let cancelAction = UIAlertAction(title: NSLocalizedString("sharing-ext.close", comment: "Close action of error alert"), style: UIAlertActionStyle.cancel) { (action: UIAlertAction) -> Void in
            actionHandler()
        }
    
        self.addAction(cancelAction)
        
    }

}
