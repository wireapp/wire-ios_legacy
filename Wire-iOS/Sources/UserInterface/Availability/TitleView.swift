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
import Cartography
import WireCommonComponents

class TitleView: UIView {

    internal var titleColor, titleColorSelected: UIColor?
    internal var titleFont: UIFont?
    internal let titleButton = UIButton()
    var tapHandler: ((UIButton) -> Void)?

    public init(color: UIColor? = nil, selectedColor: UIColor? = nil, font: UIFont? = nil) {
        super.init(frame: CGRect.zero)
        self.isAccessibilityElement = true
        self.accessibilityIdentifier = "Name"

        if let color = color, let selectedColor = selectedColor, let font = font {
            self.titleColor = color
            self.titleColorSelected = selectedColor
            self.titleFont = font
        }

        createViews()
    }

    private func createConstraints() {
        constrain(self, titleButton) { view, button in
            button.edges == view.edges
        }
    }

    private func createViews() {
        titleButton.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
        addSubview(titleButton)
    }

    @objc func titleButtonTapped(_ sender: UIButton) {
        tapHandler?(sender)
    }

    /// Configures the title view for the given conversation
    /// - parameter conversation: The conversation for which the view should be configured
    /// - parameter interactive: Whether the view should react to user interaction events
    /// - return: Whether the view contains any `NSTextAttachments`
    internal func configure(icon: NSTextAttachment?, title: String, interactive: Bool, showInteractiveIcon: Bool = true) {
        configure(icons: icon == nil ? [] : [icon!], title: title, interactive: interactive, showInteractiveIcon: showInteractiveIcon)
    }

    internal func configure(icons: [NSTextAttachment], title: String, interactive: Bool, showInteractiveIcon: Bool = true) {

        guard let font = titleFont, let color = titleColor, let selectedColor = titleColorSelected else { return }
        let shouldShowInteractiveIcon = interactive && showInteractiveIcon
        let normalLabel = IconStringsBuilder.iconString(with: icons, title: title, interactive: shouldShowInteractiveIcon, color: color)
        let selectedLabel = IconStringsBuilder.iconString(with: icons, title: title, interactive: shouldShowInteractiveIcon, color: selectedColor)

        titleButton.titleLabel!.font = font
        titleButton.setAttributedTitle(normalLabel, for: [])
        titleButton.setAttributedTitle(selectedLabel, for: .highlighted)
        titleButton.sizeToFit()
        titleButton.isEnabled = interactive
        titleButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        accessibilityLabel = titleButton.titleLabel?.text
        frame = CGRect(origin: frame.origin, size: titleButton.bounds.size)
        createConstraints()
        setNeedsLayout()
        layoutIfNeeded()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension NSTextAttachment {
    static func downArrow(color: UIColor) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = StyleKitIcon.downArrow.makeImage(size: 8, color: color)
        return attachment
    }
}
