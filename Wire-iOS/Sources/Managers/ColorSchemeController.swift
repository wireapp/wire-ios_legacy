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

extension Notification.Name {
    static let colorSchemeControllerDidApplyColorSchemeChange = Notification.Name("ColorSchemeControllerDidApplyColorSchemeChange")
}

@objc extension NSNotification {
    public static let colorSchemeControllerDidApplyColorSchemeChange = Notification.Name.colorSchemeControllerDidApplyColorSchemeChange
}

class ColorSchemeController: NSObject {

    var userObserverToken: Any?

    override init() {
        super.init()

        if let session = ZMUserSession.shared() {
            userObserverToken = UserChangeInfo.add(observer:self, for: ZMUser.selfUser(), in: session)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(settingsColorSchemeDidChange(notification:)), name: .SettingsColorSchemeChanged, object: nil)

    }

    func notifyColorSchemeChange() {
        NotificationCenter.default.post(name: .colorSchemeControllerDidApplyColorSchemeChange, object: self)
    }

    @objc
    func settingsColorSchemeDidChange(notification: Notification?) {
        ColorScheme.default.variant = Settings.shared.colorScheme.colorSchemeVariant

        NSAttributedString.invalidateMarkdownStyle()

        notifyColorSchemeChange()
    }
}

extension ColorSchemeController: ZMUserObserver {
    public func userDidChange(_ note: UserChangeInfo) {
        guard note.accentColorValueChanged else { return }

        let colorScheme = ColorScheme.default

        if !colorScheme.isCurrentAccentColor(UIColor.accent()) {
            notifyColorSchemeChange()
        }
    }
}
