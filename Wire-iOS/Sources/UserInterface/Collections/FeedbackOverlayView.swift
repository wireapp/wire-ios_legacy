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

import UIKit

final class FeedbackOverlayView: UIView {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .smallSemiboldFont
        label.textColor = .from(scheme: .textForeground)

        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        constrainViews()
        alpha = 0.0
        backgroundColor = .from(scheme: .background)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func constrainViews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor, constant: 24),
            titleLabel.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -24)
        ])
    }

    func show(text: String) {
        titleLabel.text = text
        UIView.animateKeyframes(withDuration: 2, delay: 0, options: [], animations: {
            let fadeOutDuration = 0.015
            let fadeInDuration = 0.01
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: fadeInDuration) {
                self.alpha = 1.0
            }
            UIView.addKeyframe(withRelativeStartTime: 1 - fadeOutDuration, relativeDuration: fadeOutDuration) {
                self.alpha = 0.0
            }
        }, completion: nil)
    }
}
