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
import Cartography

class Tab: Button {

    var title: String = "" {
        didSet {
            setTitle(title, for: .normal)
        }
    }

    var colorSchemeVariant : ColorSchemeVariant {
        didSet {
            updateColors()
        }
    }

    init(variant: ColorSchemeVariant) {
        colorSchemeVariant = variant
        super.init(frame: .zero)

        titleLabel?.font = FontSpec(.small, .semibold).font
        isSelected = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 48)
    }

    override var isSelected: Bool {
        didSet {
            updateColors()
        }
    }

    private func updateColors() {
        let selectionColor: UIColor
        switch self.colorSchemeVariant {
        case .dark:
            selectionColor = .white
        case .light:
            selectionColor = .black
        }
        
        setTitleColor(isSelected ? selectionColor : selectionColor.withAlphaComponent(0.5), for: .normal)
    }
}
