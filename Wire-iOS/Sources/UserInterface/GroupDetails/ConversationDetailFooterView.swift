//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

/**
 * A footer view to use to display a bar of actions to perform for a conversation.
 */

@objc class ConversationDetailFooterView: UIView {
    
    private let variant: ColorSchemeVariant
    @objc public let rightButton = IconButton()
    @objc public var leftButton: IconButton
    
    @objc public var leftIcon: ZetaIconType {
        get {
            return leftButton.iconType(for: .normal)
        }
        set {
            leftButton.isHidden = (newValue == .none)
            if newValue != .none {
                leftButton.setIcon(newValue, with: .tiny, for: .normal)
            }
        }
    }
    
    @objc public var rightIcon: ZetaIconType {
        get {
            return rightButton.iconType(for: .normal)
        }
        set {
            rightButton.isHidden = (newValue == .none)
            if newValue != .none {
                rightButton.setIcon(newValue, with: .tiny, for: .normal)
            }
        }
    }
    
    override convenience init(frame: CGRect) {
        self.init(mainButton: IconButton())
    }
    
    internal init(mainButton: IconButton = IconButton()) {
        self.variant = ColorScheme.default.variant
        self.leftButton = mainButton
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        let configureButton = { (button: IconButton) in
            self.addSubview(button)
            button.setIconColor(UIColor.from(scheme: .iconNormal), for: .normal)
            button.setIconColor(UIColor.from(scheme: .iconHighlighted), for: .highlighted)
            button.setIconColor(UIColor.from(scheme: .buttonFaded), for: .disabled)
            button.setTitleColor(UIColor.from(scheme: .iconNormal), for: .normal)
            button.setTitleColor(UIColor.from(scheme: .textDimmed), for: .highlighted)
            button.setTitleColor(UIColor.from(scheme: .buttonFaded), for: .disabled)
        }

        configureButton(leftButton)
        configureButton(rightButton)

        leftButton.titleImageSpacing = 16
        leftButton.titleLabel?.font = FontSpec(.small, .regular).font
        leftButton.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)

        rightButton.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)

        backgroundColor = UIColor.from(scheme: .barBackground)
        
        setupButtons()
    }
    
    private func createConstraints() {
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),
            leftButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            rightButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            rightButton.leadingAnchor.constraint(greaterThanOrEqualTo: leftButton.leadingAnchor, constant: 16)
        ])
    }

    // MARK: - Events
    
    @objc func setupButtons() {
        fatal("Should be overridden in subclasses")
    }
    
    @objc func leftButtonTapped(_ sender: IconButton) {
        fatal("Should be overridden in subclasses")
    }

    @objc func rightButtonTapped(_ sender: IconButton) {
        fatal("Should be overridden in subclasses")
    }

}
