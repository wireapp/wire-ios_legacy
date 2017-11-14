//
//  LandingButton.swift
//  Wire-iOS
//
//  Created by Bill Chan on 14.11.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation
import PureLayout

@objc class LandingButton: ButtonWithLargerHitArea {
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
        iconButton.autoPinEdge(toSuperviewEdge: .left)
        iconButton.autoPinEdge(toSuperviewEdge: .right)
        iconButton.autoPinEdge(toSuperviewEdge: .top)
        subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        //        subtitleLabel.textTransform = .upper ///FIXME:
        addSubview(subtitleLabel)
        subtitleLabel.autoPinEdge(toSuperviewEdge: .bottom)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    convenience init(title: NSAttributedString, icon: ZetaIconType, iconBackgroundColor: UIColor) {
        self.init()

        subtitleLabel.numberOfLines = 2
        subtitleLabel.text = nil
        subtitleLabel.attributedText = title
        self.iconButton.setIcon(icon, with: ZetaIconSize.medium, for: .normal)
        self.iconButton.setBackgroundImageColor(iconBackgroundColor, for: .normal)

        ///TODO: no capitalize
        ///TODO: rm text
        constrain(self.iconButton) { iconButton in
            iconButton.width == 72
            iconButton.width == iconButton.height
        }
        self.setup()
    }

    private func setup() {
        self.iconButton.circular = true
    }
}
