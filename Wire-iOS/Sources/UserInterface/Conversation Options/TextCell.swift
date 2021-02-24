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
import UIKit

final class TextCell: UITableViewCell, CellConfigurationConfigurable {

    private let container = UIView()
    private let label = CopyableLabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.addSubview(container)
        container.addSubview(label)
        label.font = FontSpec(.normal, .light).font
        label.lineBreakMode = .byClipping
        label.numberOfLines = 0
        constrain(contentView, container, label) { contentView, container, label in
            container.leading == contentView.leading
            container.top == contentView.top
            container.trailing == contentView.trailing
            container.bottom == contentView.bottom - 32
            label.top == container.top + 16
            label.leading == container.leading + 16
            label.trailing == container.trailing - 16
            label.bottom == container.bottom - 16
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant) {
        guard case let .text(text) = configuration else { preconditionFailure() }
        label.attributedText = text && .lineSpacing(8)
        label.textColor = UIColor.from(scheme: .textForeground, variant: variant)
        container.backgroundColor = UIColor.from(scheme: .barBackground, variant: variant)
    }

}
