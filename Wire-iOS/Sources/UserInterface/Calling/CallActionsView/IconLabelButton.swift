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

protocol IconLabelButtonInput {
    func icon(forState state: UIControl.State) -> StyleKitIcon
    var label: String { get }
    var accessibilityIdentifier: String { get }
}

class IconLabelButton: ButtonWithLargerHitArea {
    private static let width: CGFloat = 64

    private(set) var iconButton = IconButton()
    private(set) var subtitleTransformLabel = TransformLabel()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private var widthConstraint: NSLayoutConstraint!

    var appearance: CallActionAppearance = .dark(blurred: false) {
        didSet {
            updateState()
        }
    }

    init(input: IconLabelButtonInput, iconSize: StyleKitIcon.Size = .tiny) {
        super.init()
        setupViews()
        createConstraints()
        iconButton.setIcon(input.icon(forState: .normal), size: iconSize, for: .normal)
        iconButton.setIcon(input.icon(forState: .selected), size: iconSize, for: .selected)
        subtitleTransformLabel.text = input.label
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        apply(appearance)
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
        subtitleTransformLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleTransformLabel.textTransform = .upper
        subtitleTransformLabel.textAlignment = .center
        subtitleTransformLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        titleLabel?.font = FontSpec(.small, .semibold).font!
        [blurView, iconButton, subtitleTransformLabel].forEach(addSubview)
    }

    private func createConstraints() {
        widthConstraint = widthAnchor.constraint(equalToConstant: IconLabelButton.width)
        NSLayoutConstraint.activate([
            widthConstraint,
            iconButton.widthAnchor.constraint(equalTo: widthAnchor),
            iconButton.heightAnchor.constraint(equalTo: iconButton.heightAnchor),
            blurView.leadingAnchor.constraint(equalTo: iconButton.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: iconButton.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: iconButton.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: iconButton.bottomAnchor),
            iconButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconButton.topAnchor.constraint(equalTo: topAnchor),
            iconButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            iconButton.heightAnchor.constraint(equalTo: widthAnchor),
            subtitleTransformLabel.topAnchor.constraint(equalTo: iconButton.bottomAnchor, constant: 8.0),
            subtitleTransformLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            subtitleTransformLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleTransformLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    func updateState() {
        apply(appearance)
        subtitleTransformLabel.font = titleLabel?.font
        subtitleTransformLabel.textColor = titleColor(for: state)
    }

    func updateButtonWidth(width: CGFloat) {
        widthConstraint.constant = width
        blurView.layer.cornerRadius = width / 2
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

    func apply(_ configuration: CallActionAppearance) {
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
 extension UIControl.State {
    static let disabledAndSelected: UIControl.State = [.disabled, .selected]
    static let selectedAndHighlighted: UIControl.State = [.highlighted, .selected]
}
