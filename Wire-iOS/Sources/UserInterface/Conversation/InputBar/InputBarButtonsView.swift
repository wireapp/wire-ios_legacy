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
import UIKit
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

    fileprivate lazy var buttonRowTopInset: NSLayoutConstraint = buttonOuterContainer.topAnchor.constraint(equalTo: buttonInnerContainer.topAnchor)
    fileprivate lazy var buttonRowHeight: NSLayoutConstraint = buttonInnerContainer.heightAnchor.constraint(equalToConstant: 0)
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

    @available(*, unavailable)
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

    private func createConstraints() {
        let widthConstraint = widthAnchor.constraint(equalToConstant: 600)
        widthConstraint.priority = UILayoutPriority(rawValue: 750)

        [buttonInnerContainer, buttonOuterContainer].prepareForLayout()
        NSLayoutConstraint.activate([
            buttonRowTopInset,
            buttonInnerContainer.leadingAnchor.constraint(equalTo: buttonOuterContainer.leadingAnchor),
            buttonInnerContainer.trailingAnchor.constraint(equalTo: buttonOuterContainer.trailingAnchor),
            buttonInnerContainer.bottomAnchor.constraint(equalTo: buttonOuterContainer.bottomAnchor),
            buttonRowHeight,

            buttonOuterContainer.heightAnchor.constraint(equalTo: buttonInnerContainer.heightAnchor),
            buttonOuterContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UIScreen.safeArea.bottom),
            buttonOuterContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonOuterContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonOuterContainer.topAnchor.constraint(equalTo: topAnchor),

            heightAnchor.constraint(equalTo: buttonOuterContainer.heightAnchor, constant: UIScreen.safeArea.bottom),
            widthConstraint
        ])
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

    private func layoutAndConstrainButtonRows() {
        let minButtonWidth: CGFloat = constants.minimumButtonWidth(forWidth: bounds.width)

        guard bounds.size.width >= minButtonWidth * 2 else { return }

        // Drop existing constraints
        buttons.forEach {
            $0.removeFromSuperview()
            buttonInnerContainer.addSubview($0)
        }

        let ratio = floorf(Float(bounds.width / minButtonWidth))
        let numberOfButtons: Int = Int(ratio)
        multilineLayout = numberOfButtons < buttons.count

        let (firstRow, secondRow): ([UIButton], [UIButton])
        let customButtonCount = numberOfButtons >= 1 ? numberOfButtons - 1 : 0 // Last one is alway the expand button

        expandRowButton.isHidden = !multilineLayout

        if multilineLayout {
            firstRow = buttons.prefix(customButtonCount) + [expandRowButton]
            secondRow = [UIButton](buttons.suffix(buttons.count - customButtonCount))
            buttonRowHeight.constant = constants.buttonsBarHeight * 2
        } else {
            firstRow = buttons
            secondRow = []
            buttonRowHeight.constant = constants.buttonsBarHeight
        }

        var constraints = constrainRowOfButtons(firstRow,
                                                inset: 0,
                                                rowIsFull: true,
                                                referenceButton: .none)

        defer {
            NSLayoutConstraint.activate(constraints)
        }

        guard !secondRow.isEmpty else { return }

        let filled = secondRow.count == numberOfButtons
        let referenceButton = firstRow.count > 1 ? firstRow[1] : firstRow[0]

        constraints.append(contentsOf: constrainRowOfButtons(secondRow, inset: constants.buttonsBarHeight, rowIsFull: filled, referenceButton: referenceButton)
        )
    }

    private func constrainRowOfButtons(_ buttons: [UIButton],
                                       inset: CGFloat,
                                       rowIsFull: Bool,
                                       referenceButton: UIButton?) -> [NSLayoutConstraint] {
        guard let firstButton = buttons.first,
              let lastButton = buttons.last else { return [] }

        var constraints = [NSLayoutConstraint]()

        firstButton.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(
            firstButton.leadingAnchor.constraint(equalTo: firstButton.superview!.leadingAnchor)
        )

        if rowIsFull {
            lastButton.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(
                lastButton.trailingAnchor.constraint(equalTo: lastButton.superview!.trailingAnchor)
            )
        }

        for button in buttons {
            button.translatesAutoresizingMaskIntoConstraints = false

            if button == expandRowButton {

                constraints.append(contentsOf: [
                    button.topAnchor.constraint(equalTo: topAnchor),
                    button.heightAnchor.constraint(equalToConstant: constants.buttonsBarHeight)
                ])
            } else {
                buttonInnerContainer.translatesAutoresizingMaskIntoConstraints = false

                constraints.append(contentsOf: [
                    button.topAnchor.constraint(equalTo: buttonInnerContainer.topAnchor, constant: inset),
                    button.heightAnchor.constraint(equalToConstant: constants.buttonsBarHeight)
                ])
            }
        }

        var previous: UIButton = firstButton
        for current: UIButton in buttons.dropFirst() {
            let isFirstButton = previous == buttons.first
            let isLastButton = rowIsFull && current == buttons.last
            let offset = constants.iconSize / 2 + buttonMargin

            [previous, current].prepareForLayout()

            constraints.append(
                previous.trailingAnchor.constraint(equalTo: current.leadingAnchor)
            )

            if isFirstButton {
                constraints.append(
                    previous.widthAnchor.constraint(equalTo: current.widthAnchor, multiplier: 0.5, constant: offset)
                )
            } else if isLastButton {
                constraints.append(
                    current.widthAnchor.constraint(equalTo: previous.widthAnchor, multiplier: 0.5, constant: offset)
                )
            } else {
                constraints.append(
                    current.widthAnchor.constraint(equalTo: previous.widthAnchor)
                )
            }

            previous = current
        }

        if let reference = referenceButton, !rowIsFull {
            [reference, lastButton].prepareForLayout()
            constraints.append(
                lastButton.widthAnchor.constraint(equalTo: reference.widthAnchor)
            )
        }

        setupInsets(forButtons: buttons, rowIsFull: rowIsFull)

        return constraints
    }

    private func setupInsets(forButtons buttons: [UIButton], rowIsFull: Bool) {
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
