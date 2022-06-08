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
import WireDataModel
import WireSyncEngine

extension SelfProfileViewController {

    @discardableResult func presentUserSettingChangeControllerIfNeeded() -> Bool {
        if ZMUser.selfUser()?.readReceiptsEnabledChangedRemotely ?? false {
            let currentValue = ZMUser.selfUser()!.readReceiptsEnabled
            self.presentReadReceiptsChangedAlert(with: currentValue)

            return true
        } else {
            return false
        }
    }

    fileprivate func presentReadReceiptsChangedAlert(with newValue: Bool) {
        let title = newValue
            ? L10n.Localizable.Self.ReadReceiptsEnabled.title
            : L10n.Localizable.Self.ReadReceiptsDisabled.title
        let description = L10n.Localizable.Self.ReadReceiptsDescription.title

        let settingsChangedAlert = UIAlertController(title: title, message: description, preferredStyle: .alert)

        let okAction = UIAlertAction(title: L10n.Localizable.General.ok, style: .default) { [weak settingsChangedAlert] _ in
            ZMUserSession.shared()?.perform {
                ZMUser.selfUser()?.readReceiptsEnabledChangedRemotely = false
            }
            settingsChangedAlert?.dismiss(animated: true)
        }

        settingsChangedAlert.addAction(okAction)

        self.present(settingsChangedAlert, animated: true)
    }

}
