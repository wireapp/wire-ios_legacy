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
import Cartography


/// A UICollectionReusableView for ParticipantsViewController's collection view's section header view.
final public class ParticipantsCollectionHeaderView: UICollectionReusableView, Reusable {
    public var title: String = "" {
        didSet {
            titleLabel.text = title.uppercased()
            titleLabel.sizeToFit()
        }
    }

    let titleLabel: UILabel = {
        let label = UILabel()

        label.textColor = ColorScheme.default().color(withName: ColorSchemeColorTextDimmed)
        label.font = FontSpec(.small, .semibold).font!

        return label
    }()

    public required init(coder: NSCoder) {
        fatal("init(coder: NSCoder) is not implemented")
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.titleLabel)
        self.clipsToBounds = true

        constrain(self, self.titleLabel) { selfView, titleLabel in
            titleLabel.leading == selfView.leading + 16
            // 32pt, minus 24pt collectionviewlayout inset
            titleLabel.top == selfView.top + 8
            // 24pt, minus 24pt collectionviewlayout inset
            titleLabel.bottom == selfView.bottom
        }
    }
}
