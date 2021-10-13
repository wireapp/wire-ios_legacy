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
        isAccessibilityElement = true

        titleLabel.textAlignment = .center
        subtitleLabel.textAlignment = .center

        titleLabel.text = first
        subtitleLabel.text = second

        addSubview(titleLabel)
        addSubview(subtitleLabel)

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          titleLabel.leadingAnchor.constraint(equalTo: selfView.leadingAnchor),
          titleLabel.trailingAnchor.constraint(equalTo: selfView.trailingAnchor),
          titleLabel.topAnchor.constraint(equalTo: selfView.topAnchor, constant: 4),
          subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
          subtitleLabel.leadingAnchor.constraint(equalTo: selfView.leadingAnchor),
          subtitleLabel.trailingAnchor.constraint(equalTo: selfView.trailingAnchor),
          subtitleLabel.bottomAnchor.constraint(equalTo: selfView.bottomAnchor)
        ])
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
