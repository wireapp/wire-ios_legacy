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

import UIKit
import WireCommonComponents

class TitleView: UIView, DynamicTypeCapable {

    // MARK: - Properties
    var titleColor: UIColor?
    var titleFont: FontSpec?
    var tapHandler: ((UIButton) -> Void)?

    private let stackView = UIStackView(axis: .vertical)
    let titleButton = UIButton()
    private let subtitleLabel = UILabel()

    // MARK: - Initialization
    init(color: UIColor? = nil, fontSpec: FontSpec? = nil) {
        super.init(frame: CGRect.zero)
        isAccessibilityElement = true
        accessibilityIdentifier = "Name"

        if let color = color, let font = fontSpec {
            titleColor = color
            titleFont = font
        }

        createViews()
    }

    // MARK: - Private methods
    private func createConstraints() {
        [titleButton, stackView, subtitleLabel].prepareForLayout()

        stackView.fitIn(view: self)
    }

    private func createViews() {
        titleButton.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        addSubview(stackView)
        [titleButton, subtitleLabel].forEach(stackView.addArrangedSubview)
    }

    // MARK: - Methods
    @objc
    func titleButtonTapped(_ sender: UIButton) {
        tapHandler?(sender)
    }

    /// Configures the title view for the given conversation
    /// - parameter conversation: The conversation for which the view should be configured
    /// - parameter interactive: Whether the view should react to user interaction events
    /// - return: Whether the view contains any `NSTextAttachments`
    func configure(icon: NSTextAttachment?, title: String, subtitle: String? = nil, interactive: Bool, showInteractiveIcon: Bool = true) {
        configure(icons: icon == nil ? [] : [icon!], title: title, subtitle: subtitle, interactive: interactive, showInteractiveIcon: showInteractiveIcon)
    }

    func configure(icons: [NSTextAttachment], title: String, subtitle: String? = nil, interactive: Bool, showInteractiveIcon: Bool = true) {

        guard let font = titleFont, let color = titleColor else { return }
        let shouldShowInteractiveIcon = interactive && showInteractiveIcon
        let normalLabel = IconStringsBuilder.iconString(with: icons, title: title, interactive: shouldShowInteractiveIcon, color: color)

        titleButton.titleLabel!.font = font.font
        titleButton.setAttributedTitle(normalLabel, for: [])
        titleButton.isEnabled = interactive
        titleButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        accessibilityLabel = titleButton.titleLabel?.text

        subtitleLabel.isHidden = subtitle == nil
        subtitleLabel.text = subtitle
        subtitleLabel.font = .smallLightFont

        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func redrawFont() {
        titleButton.titleLabel!.font = titleFont?.font
    }
}

// MARK: NSTextAttachment Extension
extension NSTextAttachment {
    static func downArrow(color: UIColor) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = StyleKitIcon.downArrow.makeImage(
            size: 8,
            color: SemanticColors.Icon.foregroundPlainDownArrow).withRenderingMode(.alwaysTemplate)
        return attachment
    }
}
