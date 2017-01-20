//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

final class AccountPasswordProvider {
    
    enum Reason {
        case changingEmail
        case removingEmail
        
        var title: String {
            switch self {
            case .changingEmail:
                return "self.settings.account_section.ask_password.change_email.title".localized
            case .removingEmail:
                return "self.settings.account_section.ask_password.remove_email.title".localized
            }
        }
    }
    
    func askForAccountPassword(reason: Reason, showInController controller: UIViewController, completed: @escaping (String) -> ()) {
        let alert = UIAlertController(title: reason.title, message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "self.settings.account_section.ask_password.password_placeholder".localized
        }
        
        alert.addAction(
            UIAlertAction(title: "self.settings.account_section.ask_password.ok".localized, style: .default) { _ in
                if let newPassword = alert.textFields?.first?.text {
                    completed(newPassword)
                }
            }
        )
        alert.addAction(UIAlertAction(title: "self.settings.account_section.ask_password.cancel".localized, style: .cancel, handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }
}
