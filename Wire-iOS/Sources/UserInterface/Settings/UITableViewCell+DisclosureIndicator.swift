//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import UIKit

extension UITableViewCell {
    func showDisclosureIndicator() {
        let image = UIImage(systemName: "chevron.right")
        let accessory = UIImageView(frame: CGRect(x: 0, y: 0, width: (image?.size.width)!, height: (image?.size.height)!))
        accessory.image = image
        accessory.tintColor = SemanticColors.Label.textDefault
        accessoryView = accessory
    }

    func hideDisclosureIndicator() {
        accessoryView = nil
    }
}
