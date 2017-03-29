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


import Classy
import Cartography


@objc final public class ConversationCellBurstTimestampView: UIView {

    public let unreadDot = UIView()
    public let label = UILabel()
    public let leftSeparator = UIView()
    public let rightSeparator = UIView()

    private let unreadDotContainer = UIView()

    private let inset: CGFloat = 16
    private var heightConstraints = [NSLayoutConstraint]()
    private var unreadDotHiddenConstraint: NSLayoutConstraint?

    public var isShowingUnreadDot: Bool = true {
        didSet {
            unreadDotHiddenConstraint?.isActive = !isShowingUnreadDot
            leftSeparator.isHidden = isShowingUnreadDot
        }
    }

    public var isSeparatorHidden: Bool = false {
        didSet {
            leftSeparator.isHidden = isSeparatorHidden
            rightSeparator.isHidden = isSeparatorHidden
        }
    }

    public var isSeparatorExpanded: Bool = false {
        didSet {
            separatorHeight = isSeparatorExpanded ? 4 : .hairline
        }
    }

    private var separatorHeight: CGFloat = .hairline {
        didSet {
            heightConstraints.forEach {
                $0.constant = separatorHeight
            }
        }
    }

    init() {
        super.init(frame: .zero)
        CASStyler.default().styleItem(self)
        setupViews()
        createConstraints()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        [leftSeparator, label, rightSeparator, unreadDotContainer].forEach(addSubview)
        unreadDotContainer.addSubview(unreadDot)
        unreadDotContainer.backgroundColor = .clear
        clipsToBounds = true
    }

    private func createConstraints() {
        constrain(self, label, leftSeparator, rightSeparator) { view, label, leftSeparator, rightSeparator in
            leftSeparator.leading == view.leading
            leftSeparator.trailing == label.leading - inset
            leftSeparator.centerY == view.centerY

            rightSeparator.leading == label.trailing + inset
            rightSeparator.trailing == view.trailing
            rightSeparator.centerY == view.centerY

            label.centerY == view.centerY
            label.leading == view.leadingMargin
            label.trailing <= view.trailingMargin ~ LayoutPriority(500)

            heightConstraints = [
                leftSeparator.height == separatorHeight,
                rightSeparator.height == separatorHeight
            ]
        }

        constrain(self, unreadDotContainer, unreadDot, label) { view, unreadDotContainer, unreadDot, label in
            unreadDot.center == unreadDotContainer.center
            unreadDotHiddenConstraint = unreadDot.height == 0
            unreadDotHiddenConstraint?.isActive = false
            unreadDot.width == unreadDot.height

            unreadDot.height == 8 ~ LayoutPriority(751)

            unreadDotContainer.leading == view.leading
            unreadDotContainer.trailing == label.leading
            unreadDotContainer.top == view.top
            unreadDotContainer.bottom == view.bottom
        }
    }

}
