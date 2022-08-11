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
import UIKit

class RightIconDetailsCell: DetailsCollectionViewCell {
    private let accessoryIconView = UIImageView()

    var accessory: UIImage? {
        get { return accessoryIconView.image }
        set { updateAccessory(newValue) }
    }

    var accessoryColor: UIColor {
        get { return accessoryIconView.tintColor }
        set { accessoryIconView.tintColor = newValue }
    }

    private func updateAccessory(_ newValue: UIImage?) {
        if let value = newValue {
            accessoryIconView.image = value
            accessoryIconView.isHidden = false
        } else {
            accessoryIconView.isHidden = true
        }
    }

    override func setUp() {
        super.setUp()

        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .center

        contentStackView.insertArrangedSubview(accessoryIconView, at: contentStackView.arrangedSubviews.count)
    }
}
