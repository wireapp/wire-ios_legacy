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

import WireSyncEngine

final class SwitchingAccountRouter: SessionManagerSwitchingDelegate {
    // MARK: - Public Implementation
    // Ask user if they want switch account if there's an ongoing call
    public func confirmSwitchingAccount(completion: @escaping (Bool) -> Void) {
        
        guard
            let userSession = ZMUserSession.shared(),
            userSession.isCallOngoing
        else {
            return completion(true)
        }
        
        presentSwitchAccountAlert(with: completion)
    }
    
    // MARK: - Private Implementation
    private func presentSwitchAccountAlert(with completion: @escaping (Bool) -> Void) {
        guard let topmostController = UIApplication.shared.topmostViewController() else {
            return completion(false)
        }
        
        let alert = UIAlertController(title: "call.alert.ongoing.alert_title".localized,
                                      message: "self.settings.switch_account.message".localized,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "self.settings.switch_account.action".localized,
                                      style: .default,
                                      handler: { action in
            SessionManager.shared?.activeUserSession?.callCenter?.endAllCalls()
            completion(true)
        }))
        alert.addAction(.cancel {
            completion(false)
        })

        topmostController.present(alert, animated: true, completion: nil)
    }
}
