//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class ColorSchemeController: NSObject {

    var userObserverToken: Any?

    override init() {
        super.init()

        userObserverToken = UserChangeInfo.add(userObserver:self, for: ZMUser.selfUser(), userSession: ZMUserSession.shared()!)
        NotificationCenter.default.addObserver(self, selector: #selector(settingsColorSchemeDidChange(notification:)), name: .SettingsColorSchemeChanged, object: nil)

    }

    func notifyColorSchemeChange() {
        NotificationCenter.default.post(name: .ColorSchemeControllerDidApplyColorSchemeChange, object: self)
    }

    @objc func settingsColorSchemeDidChange(notification: Notification?) {
        Message.invalidateMarkdownStyle()

        let colorScheme = ColorScheme.default
        switch Settings.shared().colorScheme {
        case .light:
            colorScheme.variant = .light
        case .dark:
            colorScheme.variant = .dark
        }

        notifyColorSchemeChange()
    }

}

extension ColorSchemeController: ZMUserObserver {
    public func userDidChange(_ note: UserChangeInfo) {
        if !note.accentColorValueChanged {
            return
        }

        let colorScheme = ColorScheme.default
        let newAccentColor = UIColor.accent()
        if !(colorScheme.accentColor == newAccentColor) {
            notifyColorSchemeChange()
        }
    }
}
