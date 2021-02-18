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
import WireSyncEngine

final class SettingsSignOutCellDescriptor: SettingsExternalScreenCellDescriptor {
    
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
        

    }
    
    private func logout(password: String? = nil) {
        guard let selfUser = ZMUser.selfUser() else { return }
    
        if selfUser.usesCompanyLogin || password != nil {
            weak var topMostViewController: SpinnerCapableViewController? = UIApplication.shared.topmostViewController(onlyFullScreen: false) as? SpinnerCapableViewController
            topMostViewController?.isLoadingViewVisible = true
            ZMUserSession.shared()?.logout(credentials: ZMEmailCredentials(email: "", password: password ?? ""), { (result) in
                topMostViewController?.isLoadingViewVisible = false
                
                if case .failure(let error) = result {
                    topMostViewController?.showAlert(for: error)
                }
            })
        } else {
            guard let account = SessionManager.shared?.accountManager.selectedAccount else { return }
            SessionManager.shared?.delete(account: account)
        }
        
    }
    
    override func generateViewController() -> UIViewController? {
        guard let selfUser = ZMUser.selfUser() else { return nil }
        
        var viewController: UIViewController? = nil
        
        if selfUser.emailAddress == nil || selfUser.usesCompanyLogin {
            let alert = UIAlertController(title: "self.settings.account_details.log_out.alert.title".localized,
                                          message: "self.settings.account_details.log_out.alert.message".localized,
                                          preferredStyle: .alert)
            let actionCancel = UIAlertAction(title: "general.cancel".localized, style: .cancel, handler: nil)
            let actionLogout = UIAlertAction(title: "general.ok".localized, style: .destructive, handler: { [weak self] _ in
                self?.logout()
            })
            alert.addAction(actionCancel)
            alert.addAction(actionLogout)
            
            viewController = alert
        } else {
            requestPasswordController = RequestPasswordController(context: .logout, callback: { [weak self] (password) in
                guard let password = password else { return }
                
                self?.logout(password: password)
            })
            
            viewController = requestPasswordController?.alertController
        }
        
        return viewController
    }
    
}
