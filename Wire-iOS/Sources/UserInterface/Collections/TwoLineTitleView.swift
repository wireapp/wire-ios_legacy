//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

public final class TwoLineTitleView: UIView {

    public let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .smallSemiboldFont
        label.textColor = .from(scheme: .textForeground)

        return label
    }()

    public let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .smallLightFont
        label.textColor = .from(scheme: .textForeground)

        return label
    }()

    init(first: String, second: String) {
        super.init(frame: CGRect.zero)
        self.isAccessibilityElement = true

        self.titleLabel.textAlignment = .center
        self.subtitleLabel.textAlignment = .center

        self.titleLabel.text = first
        self.subtitleLabel.text = second

        self.addSubview(self.titleLabel)
        self.addSubview(self.subtitleLabel)

        translatesAutoresizingMaskIntoConstraints = false
        constrain(self, self.titleLabel, self.subtitleLabel) { selfView, titleLabel, subtitleLabel in
            titleLabel.leading == selfView.leading
            titleLabel.trailing == selfView.trailing
            titleLabel.top == selfView.top + 4
            subtitleLabel.top == titleLabel.bottom
            subtitleLabel.leading == selfView.leading
            subtitleLabel.trailing == selfView.trailing
            subtitleLabel.bottom == selfView.bottom
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

