//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import Foundation

extension UIViewController {
    func presentAlertWithOKButton(title: String,
                                  message: String,
                                  okActionHandler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)

        let okAction = UIAlertAction(title: "general.ok".localized, style: .cancel, handler: okActionHandler)
        alert.addAction(okAction)

        present(alert, animated: true, completion: nil)
    }
    
    func presentInvalidUserProfileLinkAlert(okActionHandler: ((UIAlertAction) -> Void)? = nil) {
        presentAlertWithOKButton(title: "url_action.invalid_user.title".localized,
                                 message: "url_action.invalid_user.message".localized,
                                 okActionHandler: okActionHandler)
    }
    
}

