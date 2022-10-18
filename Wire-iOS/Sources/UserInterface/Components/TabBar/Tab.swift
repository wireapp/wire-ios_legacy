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

class Tab: LegacyButton {

    var title: String = "" {
        didSet {
            accessibilityLabel = title
            setTitle(title.localizedUppercase, for: .normal)
        }
    }

    init() {
        super.init(fontSpec: .smallSemiboldFont)

        titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
        isSelected = false
        updateColors()

    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }

    private func updateColors() {
        setTitleColor(SemanticColors.Label.textDefault, for: .normal)
        setTitleColor(SemanticColors.Label.textDefault, for: .highlighted)

    }
}
