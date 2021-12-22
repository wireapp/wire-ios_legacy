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
import WireSyncEngine

extension Notification.Name {
    static let colorSchemeControllerDidApplyColorSchemeChange = Notification.Name("ColorSchemeControllerDidApplyColorSchemeChange")
}

extension NSNotification {
    static let colorSchemeControllerDidApplyColorSchemeChange = Notification.Name.colorSchemeControllerDidApplyColorSchemeChange
}

final class ColorSchemeController: NSObject {

    var userObserverToken: Any?

    override init() {
        super.init()

        // When SelfUser.provider is nil, e.g. running tests, do not set up UserChangeInfo observer
        if let session = ZMUserSession.shared(),
           SelfUser.provider != nil {
            userObserverToken = UserChangeInfo.add(observer: self, for: SelfUser.current, in: session)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(settingsColorSchemeDidChange), name: .SettingsColorSchemeChanged, object: nil)

    }

    func notifyColorSchemeChange() {
        NotificationCenter.default.post(name: .colorSchemeControllerDidApplyColorSchemeChange, object: self)
    }

    @objc
    private func settingsColorSchemeDidChange() {
        ColorScheme.default.variant = Settings.shared.colorSchemeVariant

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
