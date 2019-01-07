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

import Foundation

final class BackButtonDescription {
    var buttonTapped: (() -> ())? = nil
    var accessibilityIdentifier: String? = "backButton"
}

extension BackButtonDescription: ViewDescriptor {
    func create() -> UIView {
        let button = IconButton()
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        button.setIconColor(UIColor.from(scheme: .iconNormal, variant: .light), for: .normal)
        button.setIconColor(UIColor.from(scheme: .textDimmed, variant: .light), for: .highlighted)
        let iconType: ZetaIconType = UIApplication.isLeftToRightLayout ? .chevronLeft : .chevronRight
        button.setIcon(iconType, with: .tiny, for: .normal)
        button.accessibilityIdentifier = accessibilityIdentifier
        button.addTarget(self, action: #selector(BackButtonDescription.backButtonTapped(_:)), for: .touchUpInside)
        button.sizeToFit()
        return button
    }

    @objc dynamic func backButtonTapped(_ sender: UIButton) {
        buttonTapped?()
    }
}

