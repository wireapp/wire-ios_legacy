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
import WireSystem

final class NoResultsView: UIView {
    let label = UILabel()
    private let iconView = UIImageView()

    var placeholderText: String? {
        get {
            return label.text
        }
        set {
            label.text = newValue
            label.accessibilityLabel = newValue
        }
    }

    var icon: StyleKitIcon? = nil {
        didSet {
            iconView.image = icon?.makeImage(size: 160, color: placeholderColor)
        }
    }

    var placeholderColor: UIColor {
        let backgroundColor = UIColor.from(scheme: .background)
        return backgroundColor.mix(UIColor.from(scheme: .sectionText), amount: 0.16)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        accessibilityElements = [label]

        label.numberOfLines = 0
        label.textColor = placeholderColor
        label.textAlignment = .center
        label.font = .mediumSemiboldFont
        addSubview(label)

        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)

        [label, iconView].prepareForLayout()
        NSLayoutConstraint.activate([
          iconView.topAnchor.constraint(equalTo: topAnchor),
          iconView.centerXAnchor.constraint(equalTo: centerXAnchor),

          label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24),
          label.bottomAnchor.constraint(equalTo: bottomAnchor),
          label.leadingAnchor.constraint(equalTo: leadingAnchor),
          label.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatal("init?(coder:) is not implemented")
    }
}
