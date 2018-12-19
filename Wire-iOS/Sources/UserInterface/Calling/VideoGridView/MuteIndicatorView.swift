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

extension UIColor {
    enum MuteIndicator {
        static let containerBackground = UIColor(rgb: 0x33373A, alpha:0.4)
    }
}

extension CGFloat {
    enum MuteIndicator {
        static let containerHeight: CGFloat = 32
        static let containerHorizontalMargin: CGFloat = 12
        static let iconLabelSpacing: CGFloat = 8
    }
}


final class MuteIndicatorView: UIView {
    let mutedIconImageView: UIImageView = {
        let image = UIImage(for: .microphoneWithStrikethrough, iconSize: .like, color: .white)

        return UIImageView(image: image)
    }()

    let mutedLabel: TransformLabel = {
        let label = TransformLabel()
        label.font = .smallSemiboldFont
        label.textColor = .white
        label.text = "conversation.status.silenced".localized
        label.textTransform = .upper

        return label
    }()

    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor.MuteIndicator.containerBackground
        layer.cornerRadius = CGFloat.MuteIndicator.containerHeight / 2
        layer.masksToBounds = true


        [mutedIconImageView, mutedLabel].forEach( addSubview )

        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        constrain(mutedIconImageView, mutedLabel, self) { mutedIconImageView, mutedLabel, containerView in

            mutedLabel.centerY == containerView.centerY
            mutedIconImageView.centerY == containerView.centerY

            mutedIconImageView.leading == containerView.leading + CGFloat.MuteIndicator.containerHorizontalMargin
            mutedIconImageView.trailing == mutedLabel.leading - CGFloat.MuteIndicator.iconLabelSpacing
            mutedLabel.trailing == containerView.trailing - CGFloat.MuteIndicator.containerHorizontalMargin

        }
    }
}

