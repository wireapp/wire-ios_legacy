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

class SettingsSignOutCellDescriptor: SettingsExternalScreenCellDescriptor {
    
    var requestPasswordController: RequestPasswordController?
    
    init() {
        super.init(title: "self.sign_out".localized,
                   isDestructive: true,
                   presentationStyle: .modal,
                   identifier: nil,
                   presentationAction: { return nil },
                   previewGenerator: nil,
                   icon: nil,
                   accessoryViewMode: .default)
        
        requestPasswordController = RequestPasswordController(context: .logout, callback: { (password) in
            guard let password = password else { return }
            
            ZClientViewController.shared()?.showLoadingView = true
            ZMUserSession.shared()?.logout(credentials: ZMEmailCredentials(email: "", password: password), { (result) in
                ZClientViewController.shared()?.showLoadingView = false
                
                if case .failure(let error) = result {
                    ZClientViewController.shared()?.showAlert(forError: error)
                }
            })
        })
    }
    
    override func generateViewController() -> UIViewController? {
        return requestPasswordController?.alertController
    }
    
}
