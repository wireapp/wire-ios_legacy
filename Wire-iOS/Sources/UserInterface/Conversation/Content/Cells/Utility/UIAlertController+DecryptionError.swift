//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireDataModel

extension UIAlertController {
    
    static func decryptionErrorDetails(client: UserClientType?, errorCode: Int?) -> UIAlertController {
        let title = "content.system.cannot_decrypt.alert.title".localized
        let buttonTitle = "content.system.cannot_decrypt.alert.contact_us".localized
        let message = "content.system.cannot_decrypt.alert.message".localized
        let messageWithError = "Error \(errorCode ?? 0) \(client?.displayIdentifier ?? "-")\n\(message)"
        let alertController = UIAlertController(title: title,
                                                message: messageWithError,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction.ok())
        alertController.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: { (_) in
            UIApplication.shared.open(URL.wr_cannotDecryptHelp)
        }))
        
        return alertController
    }
    
}
