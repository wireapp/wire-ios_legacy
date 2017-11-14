//
//  IconLabelButton.swift
//  WireExtensionComponents
//
//  Created by Bill Chan on 13.11.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import PureLayout

open class IconLabelButtonSwift: ButtonWithLargerHitArea {
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
        subtitleLabel.textTransform = .upper ///FIXME:
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
        subtitleLabel.textColor = titleColor(for: state) ?? UIColor.clear  ///FIXME:
    }

}
