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
import UIKit

private final class MenuDotView: UIView {
    init() {
        super.init(frame: .zero)

        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.size.width / 2
    }
}

final class AnimatedListMenuView: UIView {
    /// Animation progress. Value from 0 to 1.0
    var progress: CGFloat = 0 {
        didSet {
            guard !(0...1 ~= progress) else { return }
            progress = min(1, max(0, progress))
        }
    }

    private let leftDotView: MenuDotView = MenuDotView()
    private let centerDotView: MenuDotView = MenuDotView()
    private let rightDotView: MenuDotView = MenuDotView()

    private var initialConstraintsCreated = false
    private var centerToRightDistanceConstraint: NSLayoutConstraint?
    private var leftToCenterDistanceConstraint: NSLayoutConstraint?

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        [leftDotView, centerDotView, rightDotView].forEach {
            addSubview($0)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setProgress(_ progress: CGFloat, animated: Bool) {
        self.progress = progress

        centerToRightDistanceConstraint?.constant = centerToRightDistance(forProgress: self.progress)
        leftToCenterDistanceConstraint?.constant = leftToCenterDistance(forProgress: self.progress)

        if animated {
            setNeedsUpdateConstraints()

            UIView.animate(withDuration: 0.25, animations: {
                self.layoutIfNeeded()
            })
        }
    }

    override func updateConstraints() {
        if initialConstraintsCreated {
            super.updateConstraints()
            return
        }

        let dotWidth: CGFloat = 4

        let dotViews = [leftDotView, centerDotView, rightDotView]

        dotViews.forEach {$0.translatesAutoresizingMaskIntoConstraints = false}
        translatesAutoresizingMaskIntoConstraints = false

        centerToRightDistanceConstraint = centerDotView.rightAnchor.constraint(equalTo: rightDotView.leftAnchor, constant: centerToRightDistance(forProgress: progress))

        leftToCenterDistanceConstraint = leftDotView.rightAnchor.constraint(equalTo: centerDotView.leftAnchor, constant: leftToCenterDistance(forProgress: progress))

        let leftDotLeftConstraint = leftDotView.leftAnchor.constraint(equalTo: self.leftAnchor)

        dotViews.forEach {$0.widthAnchor.constraint(equalToConstant: dotWidth).isActive = true
                          $0.heightAnchor.constraint(equalToConstant: dotWidth).isActive = true
        }

        let subviewConstraints: [NSLayoutConstraint] = [
            leftDotView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            centerDotView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            rightDotView.centerYAnchor.constraint(equalTo: self.centerYAnchor),

            rightDotView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8),
            leftDotLeftConstraint,

            centerToRightDistanceConstraint!,
            leftToCenterDistanceConstraint!
        ]
        NSLayoutConstraint.activate(subviewConstraints)

        initialConstraintsCreated = true

        super.updateConstraints()
    }

    func centerToRightDistance(forProgress progress: CGFloat) -> CGFloat {
        return -(4 + (10 * (1 - progress)))
    }

    func leftToCenterDistance(forProgress progress: CGFloat) -> CGFloat {
        return -(4 + (20 * (1 - progress)))
    }

}
