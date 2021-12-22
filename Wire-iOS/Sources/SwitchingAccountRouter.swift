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

typealias SwitchingAccountRouterProtocol = SessionManagerSwitchingDelegate & SwitchingAccountAlertPresenter

protocol SwitchingAccountAlertPresenter {
    func presentSwitchAccountAlert(completion: @escaping (Bool) -> Void)
}

class SwitchingAccountRouter: SwitchingAccountRouterProtocol {
    // MARK: - SessionManagerSwitchingDelegate
    func confirmSwitchingAccount(completion: @escaping (Bool) -> Void) {
        presentSwitchAccountAlert(completion: completion)
    }

    // MARK: - SwitchingAccountAlertPresenter
    @objc
    internal func presentSwitchAccountAlert(completion: @escaping (Bool) -> Void) {
        guard let topmostController = UIApplication.shared.topmostViewController() else {
            return completion(false)
        }

        let alert = UIAlertController(title: "call.alert.ongoing.alert_title".localized,
                                      message: "self.settings.switch_account.message".localized,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "self.settings.switch_account.action".localized,
                                      style: .default,
                                      handler: { _ in
            completion(true)
        }))
        alert.addAction(.cancel {
            completion(false)
        })

        topmostController.present(alert, animated: true, completion: nil)
    }
}
