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


extension UIBarButtonItem {

    convenience init(icon: ZetaIconType, style: UIBarButtonItemStyle = .plain, target: Any?, action: Selector?) {
        self.init(
            image: UIImage(for: icon, iconSize: .tiny, color: ColorScheme.default().color(withName: ColorSchemeColorTextForeground)),
            style: style,
            target: target,
            action: action
        )
    }
    
    static func backButton(target: Any?, action: Selector?) -> UIBarButtonItem {
        return .init(icon: .backArrow, target: target, action: action)
    }

}
