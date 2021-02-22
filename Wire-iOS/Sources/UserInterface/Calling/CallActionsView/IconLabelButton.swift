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
import WireCommonComponents

class IconLabelButton: ButtonWithLargerHitArea {
    private static let width: CGFloat = 64
    private static let height: CGFloat = 88
    
    private(set) var iconButton = IconButton()
    private(set) var subtitleLabel = TransformLabel()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    var appearance: CallActionAppearance = .dark(blurred: false) {
        didSet {
            updateState()
        }
    }
    
    init(icon: StyleKitIcon, label: String, accessibilityIdentifier: String) {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
        iconButton.setIcon(icon, size: .tiny, for: .normal)
        subtitleLabel.text = label
        self.accessibilityIdentifier = accessibilityIdentifier
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateState()
    }
    
    private func setupViews() {
        iconButton.translatesAutoresizingMaskIntoConstraints = false
        iconButton.isUserInteractionEnabled = false
        iconButton.borderWidth = 0
        iconButton.circular = true
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = IconLabelButton.width / 2
        blurView.isUserInteractionEnabled = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textTransform = .upper
        subtitleLabel.textAlignment = .center
        titleLabel?.font = FontSpec(.small, .semibold).font!
        [blurView, iconButton, subtitleLabel].forEach(addSubview)
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: IconLabelButton.width),
            heightAnchor.constraint(greaterThanOrEqualToConstant: IconLabelButton.height),
            iconButton.widthAnchor.constraint(equalToConstant: IconLabelButton.width),
            iconButton.heightAnchor.constraint(equalToConstant: IconLabelButton.width),
            blurView.leadingAnchor.constraint(equalTo: iconButton.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: iconButton.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: iconButton.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: iconButton.bottomAnchor),
            iconButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconButton.topAnchor.constraint(equalTo: topAnchor),
            iconButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 16)
            ])
    }

    private func updateState() {
        apply(appearance)
        subtitleLabel.font = titleLabel?.font
        subtitleLabel.textColor = titleColor(for: state)
    }
    
    override var isHighlighted: Bool {
        didSet {
            iconButton.isHighlighted = isHighlighted
            updateState()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            iconButton.isSelected = isSelected
            updateState()
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            iconButton.isEnabled = isEnabled
            updateState()
        }
    }
    
    private func apply(_ configuration: CallActionAppearance) {
        setTitleColor(configuration.iconColorNormal, for: .normal)
        iconButton.setIconColor(configuration.iconColorNormal, for: .normal)
        iconButton.setBackgroundImageColor(configuration.backgroundColorNormal, for: .normal)
        
        iconButton.setIconColor(configuration.iconColorSelected, for: .selected)
        iconButton.setBackgroundImageColor(configuration.backgroundColorSelected, for: .selected)
        
        setTitleColor(configuration.iconColorNormal.withAlphaComponent(0.4), for: .disabled)
        iconButton.setIconColor(configuration.iconColorNormal.withAlphaComponent(0.4), for: .disabled)
        iconButton.setBackgroundImageColor(configuration.backgroundColorNormal, for: .disabled)

        setTitleColor(configuration.iconColorNormal.withAlphaComponent(0.4), for: .disabledAndSelected)
        iconButton.setIconColor(configuration.iconColorSelected.withAlphaComponent(0.4), for: .disabledAndSelected)
        iconButton.setBackgroundImageColor(configuration.backgroundColorSelected, for: .disabledAndSelected)
        
        iconButton.setBackgroundImageColor(configuration.backgroundColorSelectedAndHighlighted, for: .selectedAndHighlighted)
        
        blurView.isHidden = !configuration.showBlur
    }

}

// MARK: - Helper

fileprivate extension UIControl.State {
    static let disabledAndSelected: UIControl.State = [.disabled, .selected]
    static let selectedAndHighlighted: UIControl.State = [.highlighted, .selected]
}
