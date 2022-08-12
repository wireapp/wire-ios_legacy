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
import WireCommonComponents
import UIKit

final class BackButtonDescription {

    var buttonTapped: (() -> Void)?
    var accessibilityIdentifier: String? = "backButton"

}

extension BackButtonDescription: ViewDescriptor {
    func create() -> UIView {
        let button = IconButton()
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        button.setIconColor(SemanticColors.Icon.foregroundDefault, for: .normal)
        let iconType: StyleKitIcon = UIApplication.isLeftToRightLayout ? .backArrow : .forwardArrow
        button.setIcon(iconType, size: .tiny, for: .normal)
        button.accessibilityIdentifier = accessibilityIdentifier
        button.addTarget(self, action: #selector(BackButtonDescription.backButtonTapped(_:)), for: .touchUpInside)
        button.sizeToFit()
        return button
    }

    @objc dynamic func backButtonTapped(_ sender: UIButton) {
        buttonTapped?()
    }
}
