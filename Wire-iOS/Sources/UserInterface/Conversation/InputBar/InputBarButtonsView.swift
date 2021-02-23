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


import Foundation
import Cartography
import WireCommonComponents

private struct InputBarRowConstants {
    let titleTopMargin: CGFloat = 10
    let minimumButtonWidthIPhone5: CGFloat = 53
    let minimumButtonWidth: CGFloat = 56
    let buttonsBarHeight: CGFloat = 56
    let iconSize = StyleKitIcon.Size.tiny.rawValue
        
    func minimumButtonWidth(forWidth width: CGFloat) -> CGFloat {
        return width <= CGFloat.iPhone4Inch.width ? minimumButtonWidthIPhone5 : minimumButtonWidth
    }
}


final class InputBarButtonsView: UIView {
    
    typealias RowIndex = UInt
    
    fileprivate(set) var multilineLayout: Bool = false
    fileprivate(set) var currentRow: RowIndex = 0
    
    fileprivate var buttonRowTopInset: NSLayoutConstraint!
    fileprivate var buttonRowHeight: NSLayoutConstraint!
    fileprivate var lastLayoutWidth: CGFloat = 0
    
    let expandRowButton = IconButton()
    var buttons: [UIButton] {
        didSet {
            buttonInnerContainer.subviews.forEach({ $0.removeFromSuperview() })
            layoutAndConstrainButtonRows()
        }
    }
    fileprivate let buttonInnerContainer = UIView()
    fileprivate let buttonOuterContainer = UIView()
    fileprivate let constants = InputBarRowConstants()
    
    required init(buttons: [UIButton]) {
        self.buttons = buttons
        super.init(frame: CGRect.zero)
        configureViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureViews() {
        addSubview(buttonInnerContainer)
        
        buttons.forEach {
            $0.addTarget(self, action: #selector(anyButtonPressed), for: .touchUpInside)
            buttonInnerContainer.addSubview($0)
        }
        
        buttonInnerContainer.clipsToBounds = true
        expandRowButton.accessibilityIdentifier = "showOtherRowButton"
        expandRowButton.hitAreaPadding = .zero
        expandRowButton.setIcon(.ellipsis, size: .tiny, for: [])
        expandRowButton.addTarget(self, action: #selector(ellipsisButtonPressed), for: .touchUpInside)
        buttonOuterContainer.addSubview(buttonInnerContainer)
        buttonOuterContainer.clipsToBounds = true
        addSubview(buttonOuterContainer)
        addSubview(expandRowButton)
        self.backgroundColor = UIColor.from(scheme: .barBackground)
    }
    
    func createConstraints() {
        constrain(self, buttonInnerContainer, buttonOuterContainer)  { view, innerContainer, outerContainer in
            self.buttonRowTopInset = outerContainer.top == innerContainer.top
            innerContainer.leading == outerContainer.leading
            innerContainer.trailing == outerContainer.trailing
            innerContainer.bottom == outerContainer.bottom
            buttonRowHeight = innerContainer.height == 0
            
            outerContainer.height == innerContainer.height
            outerContainer.bottom == view.bottom - UIScreen.safeArea.bottom
            outerContainer.leading == view.leading
            outerContainer.trailing == view.trailing
            outerContainer.top == view.top
            
            view.height == outerContainer.height + UIScreen.safeArea.bottom
            view.width == 600 ~ 750.0
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size.width != lastLayoutWidth else { return }
        layoutAndConstrainButtonRows()
        lastLayoutWidth = bounds.size.width
    }
    
    func showRow(_ rowIndex: RowIndex, animated: Bool) {
        guard rowIndex != currentRow else { return }
        currentRow = rowIndex
        buttonRowTopInset.constant = CGFloat(rowIndex) * constants.buttonsBarHeight
        UIView.animate(easing: .easeInOutExpo, duration: animated ? 0.35 : 0, animations: layoutIfNeeded)
    }
    
    // MARK: - Button Layout
    
    fileprivate var buttonMargin: CGFloat {
        return conversationHorizontalMargins.left / 2 - StyleKitIcon.Size.tiny.rawValue / 2
    }
    
    fileprivate func layoutAndConstrainButtonRows() {
        let minButtonWidth = constants.minimumButtonWidth(forWidth: bounds.width)

        guard bounds.size.width >= minButtonWidth * 2 else { return }

        // Drop existing constraints
        buttons.forEach {
            $0.removeFromSuperview()
            buttonInnerContainer.addSubview($0)
        }

        let numberOfButtons = Int(floorf(Float(bounds.width / minButtonWidth)))
        multilineLayout = numberOfButtons < buttons.count
        
        let (firstRow, secondRow): ([UIButton], [UIButton])
        let customButtonCount = numberOfButtons >= 1 ? numberOfButtons - 1 : 0 // Last one is alway the expand button

        expandRowButton.isHidden = !multilineLayout

        if multilineLayout {
            firstRow = buttons.prefix(customButtonCount) + [expandRowButton]
            secondRow = Array<UIButton>(buttons.suffix(buttons.count - customButtonCount))
            buttonRowHeight.constant = constants.buttonsBarHeight * 2
        } else {
            firstRow = buttons
            secondRow = []
            buttonRowHeight.constant = constants.buttonsBarHeight
        }
        
        constrainRowOfButtons(firstRow, inset: 0, rowIsFull: true, referenceButton: .none)
        
        guard !secondRow.isEmpty else { return }
        let filled = secondRow.count == numberOfButtons
        let referenceButton = firstRow.count > 1 ? firstRow[1] : firstRow[0]
        constrainRowOfButtons(secondRow, inset: constants.buttonsBarHeight, rowIsFull: filled, referenceButton: referenceButton)
    }
    
    fileprivate func constrainRowOfButtons(_ buttons: [UIButton],
                                           inset: CGFloat,
                                           rowIsFull: Bool,
                                           referenceButton: UIButton?) {
        constrain(buttons.first!) { firstButton in
            firstButton.leading == firstButton.superview!.leading
        }
        
        if rowIsFull {
            constrain(buttons.last!) { lastButton in
                lastButton.trailing == lastButton.superview!.trailing
            }
        }
        
        for button in buttons {
            if button == expandRowButton {
                constrain(button, self) { button, view in
                    button.top == view.top
                    button.height == constants.buttonsBarHeight
                }
            } else {
                constrain(button, buttonInnerContainer) { button, container in
                    button.top == container.top + inset
                    button.height == constants.buttonsBarHeight
                }
            }
        }
        
        var previous: UIView = buttons.first!
        for current: UIView in buttons.dropFirst() {
            let isFirstButton = previous == buttons.first
            let isLastButton = rowIsFull && current == buttons.last
            let offset = constants.iconSize / 2 + buttonMargin
            
            constrain(previous, current) { previous, current in
                previous.trailing == current.leading
                
                if (isFirstButton) {
                    previous.width == current.width * 0.5 + offset
                } else if (isLastButton) {
                    current.width == previous.width * 0.5 + offset
                } else {
                    current.width == previous.width
                }
            }
            previous = current
        }
        
        if let reference = referenceButton , !rowIsFull {
            constrain(reference, buttons.last!) { reference, lastButton in
                lastButton.width == reference.width
            }
        }
        
        setupInsets(forButtons: buttons, rowIsFull: rowIsFull)
    }
    
    fileprivate func setupInsets(forButtons buttons: [UIButton], rowIsFull: Bool) {
        let firstButton = buttons.first!
        let firstButtonLabelSize = firstButton.titleLabel!.intrinsicContentSize
        let firstTitleMargin = (conversationHorizontalMargins.left / 2) - constants.iconSize - (firstButtonLabelSize.width / 2)
        firstButton.contentHorizontalAlignment = .left
        firstButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: buttonMargin, bottom: 0, right: 0)
        firstButton.titleEdgeInsets = UIEdgeInsets(top: constants.iconSize + firstButtonLabelSize.height + constants.titleTopMargin, left: firstTitleMargin, bottom: 0, right: 0)
        
        if rowIsFull {
            let lastButton = buttons.last!
            let lastButtonLabelSize = lastButton.titleLabel!.intrinsicContentSize
            let lastTitleMargin = conversationHorizontalMargins.left / 2.0 - lastButtonLabelSize.width / 2.0
            lastButton.contentHorizontalAlignment = .right
            lastButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: buttonMargin - lastButtonLabelSize.width)
            lastButton.titleEdgeInsets = UIEdgeInsets(top: constants.iconSize + lastButtonLabelSize.height + constants.titleTopMargin, left: 0, bottom: 0, right: lastTitleMargin - 1)
            lastButton.titleLabel?.lineBreakMode = .byClipping
        }
        
        for button in buttons.dropFirst().dropLast() {
            let buttonLabelSize = button.titleLabel!.intrinsicContentSize
            button.contentHorizontalAlignment = .center
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -buttonLabelSize.width)
            button.titleEdgeInsets = UIEdgeInsets(top: constants.iconSize + buttonLabelSize.height + constants.titleTopMargin, left: -constants.iconSize, bottom: 0, right: 0)
        }
    }
    
}

extension InputBarButtonsView {
    @objc fileprivate func anyButtonPressed(_ button: UIButton!) {
        showRow(0, animated: true)
    }
    
    @objc fileprivate func ellipsisButtonPressed(_ button: UIButton!) {
        showRow(currentRow == 0 ? 1 : 0, animated: true)
    }
}
