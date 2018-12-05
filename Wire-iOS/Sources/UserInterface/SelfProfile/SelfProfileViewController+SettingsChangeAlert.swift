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

extension SelfProfileViewController {

    @discardableResult func presentUserSettingChangeControllerIfNeeded() -> Bool {
        guard let settings = Settings.shared(),
                let account = SessionManager.shared?.accountManager.selectedAccount else {
                fatal("Settings.shared() is missing")
        }
        
        if settings.readReceiptsValueChanged(for: account) {
            let currentValue = ZMUser.selfUser()!.readReceiptsEnabled
            self.presentReadReceiptsChangedAlert(with: currentValue)
            settings.setValue(currentValue, for: UserDefaultReadReceiptsEnabledLastSeenValue, in: account)
            return true
        }
        else {
            return false
        }
    }
    
    fileprivate func presentReadReceiptsChangedAlert(with newValue: Bool) {
        let title = newValue ? "self.read_receipts_enabled.title".localized : "self.read_receipts_disabled.title".localized
        let description = "self.read_receipts_description.title".localized
        
        let settingsChangedAlert = UIAlertController(title: title,
                                                     message: description,
                                                     cancelButtonTitle: "general.ok".localized)

        self.present(settingsChangedAlert, animated: true)
    }
    
}
