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

import UIKit

class CheckmarkCell: DetailsCollectionViewCell {

    var showCheckmark: Bool = false {
        didSet {
            updateCheckmark(forColor: ColorScheme.default.variant)
        }
    }

    override var disabled: Bool {
        didSet {
            updateCheckmark(forColor: ColorScheme.default.variant)
        }
    }
    
    override func setUp() {
        super.setUp()
        icon = nil
        status = nil
    }

    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)
        updateCheckmark(forColor: colorSchemeVariant)
    }

    private func updateCheckmark(forColor colorSchemeVariant: ColorSchemeVariant) {

        guard showCheckmark else {
            accessory = nil
            return
        }

        let color: UIColor
        
        switch (colorSchemeVariant, disabled) {
        case (.light, false):
            color = UIColor(scheme: .textForeground, variant: colorSchemeVariant)
        case (.light, true):
            color = UIColor(scheme: .textPlaceholder, variant: colorSchemeVariant)
        case (.dark, false):
            color = .white
        case (.dark, true):
            color = UIColor(scheme: .textPlaceholder, variant: colorSchemeVariant)
        }
    
        accessory = UIImage(for: .checkmark, iconSize: .tiny, color: color)
    }

}
