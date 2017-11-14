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
import PureLayout


class LandingButton: ButtonWithLargerHitArea {
    var priorState: UIControlState?

    public var iconButton: IconButton!
    public var subtitleLabel: UILabel!

    public init() {
        super.init(frame: CGRect.zero)
        iconButton = IconButton.iconButtonCircularLight()
        iconButton.translatesAutoresizingMaskIntoConstraints = false
        iconButton.isUserInteractionEnabled = false
        addSubview(iconButton)
        iconButton.autoMatch(.width, to: .height, of: iconButton)
        iconButton.autoPinEdge(toSuperviewEdge: .top)
        iconButton.autoSetDimensions(to: CGSize(width:72, height:72))
        iconButton.autoCenterInSuperview()


        subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        subtitleLabel.autoPinEdge(toSuperviewEdge: .bottom)
        subtitleLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        self.subtitleLabel.autoPinEdge(.top, to: .bottom, of: self.iconButton, withOffset: 16)
        subtitleLabel.autoSetDimension(.height, toSize: 48)
    }

    convenience init(title: NSAttributedString, icon: ZetaIconType, iconBackgroundColor: UIColor) {
        self.init()

        subtitleLabel.numberOfLines = 2
        subtitleLabel.text = nil
        subtitleLabel.attributedText = title
        self.iconButton.setIcon(icon, with: ZetaIconSize.medium, for: .normal)
        self.iconButton.setBackgroundImageColor(iconBackgroundColor, for: .normal)

        self.setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.iconButton.circular = true
    }

    override open func didMoveToWindow() {
        super.didMoveToWindow()
        updateForNewState()
    }

    // MARK: - Observing state
    override open var isHighlighted: Bool {
        didSet {
            priorState = state
            super.isHighlighted = isHighlighted
            iconButton.isHighlighted = isHighlighted
            updateForNewStateIfNeeded()

        }
    }

    override open var isSelected: Bool {
        didSet {
            priorState = state
            super.isSelected = isSelected
            iconButton.isSelected = isSelected
            updateForNewStateIfNeeded()
        }
    }

    override open var isEnabled: Bool {
        didSet {
            priorState = state
            super.isEnabled = isEnabled
            iconButton.isEnabled  = isEnabled
            updateForNewStateIfNeeded()
        }
    }

    func updateForNewStateIfNeeded() {
        if state != priorState {
            priorState = state
            updateForNewState()
        }
    }

    func updateForNewState() {
        // Update for new state (selected, highlighted, disabled) here if needed
        subtitleLabel.font = titleLabel?.font
        //        subtitleLabel.textColor = titleColor(for: state) ?? UIColor.clear  ///FIXME:
    }

}
