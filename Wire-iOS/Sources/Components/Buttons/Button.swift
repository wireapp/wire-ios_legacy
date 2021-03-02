//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

enum ButtonStyle: Int {
    // background color: accent, text color: white
    case full
    case empty
    case fullMonochrome
    case emptyMonochrome
}

class Button: ButtonWithLargerHitArea {
    private var previousState: UIControl.State?

    var circular = false {
        didSet {
            if circular {
                layer.masksToBounds = true
                updateCornerRadius()
            } else {
                layer.masksToBounds = false
                layer.cornerRadius = 0
            }
        }
    }

    var textTransform: TextTransform = .none {
        didSet {
            for(state, title) in originalTitles {
                setTitle(title, for: state)
            }
        }
    }

    var style: ButtonStyle? {
        didSet {
            updateStyle(variant: variant)
        }
    }

    private(set) var variant: ColorSchemeVariant = ColorScheme.default.variant

    private var originalTitles: [UIControl.State: String] = [:]

    private var borderColorByState: [UIControl.State: UIColor] = [:]

    init() {
        super.init(frame: .zero)

        clipsToBounds = true
    }

    convenience init(style: ButtonStyle,
                     variant: ColorSchemeVariant = ColorScheme.default.variant,
                     cornerRadius: CGFloat = 4,
                     titleLabelFont: UIFont = .smallLightFont) {
        self.init()

        self.style = style
        self.variant = variant

        textTransform = .upper
        titleLabel?.font = titleLabelFont
        layer.cornerRadius = cornerRadius
        contentEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)

        updateStyle(variant: variant)
    }

    private func updateStyle(variant: ColorSchemeVariant) {
        guard let style = style else { return }

        switch style {
        case .full:
            updateFullStyle()
        case .fullMonochrome:
            setBackgroundImageColor(UIColor.white, for: .normal)
            setTitleColor(UIColor.from(scheme: .textForeground, variant: .light), for: .normal)
            setTitleColor(UIColor.from(scheme: .textDimmed, variant: .light), for: .highlighted)
        case .empty:
            updateEmptyStyle()
        case .emptyMonochrome:
            setBackgroundImageColor(UIColor.clear, for: .normal)
            setTitleColor(UIColor.white, for: .normal)
            setTitleColor(UIColor.from(scheme: .textDimmed, variant: .light), for: .highlighted)
            setBorderColor(UIColor(white: 1.0, alpha: 0.32), for: .normal)
            setBorderColor(UIColor(white: 1.0, alpha: 0.16), for: .highlighted)
        }
    }

    func updateFullStyle() {
        setBackgroundImageColor(.accent(), for: .normal)
        setTitleColor(UIColor.white, for: .normal)
        setTitleColor(UIColor.from(scheme: .textDimmed, variant: variant), for: .highlighted)
    }

    func updateEmptyStyle() {
        setBackgroundImageColor(nil, for: .normal)
        layer.borderWidth = 1
        setTitleColor(UIColor.buttonEmptyText(variant: variant), for: .normal)
        setTitleColor(UIColor.from(scheme: .textDimmed, variant: variant), for: .highlighted)
        setTitleColor(UIColor.from(scheme: .textDimmed, variant: variant), for: .disabled)
        setBorderColor(UIColor.accent(), for: .normal)
        setBorderColor(UIColor.accentDarken, for: .highlighted)
        setBorderColor(UIColor.from(scheme: .textDimmed, variant: variant), for: .disabled)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize

        return CGSize(width: s.width + titleEdgeInsets.left + titleEdgeInsets.right, height: s.height + titleEdgeInsets.top + titleEdgeInsets.bottom)
    }

    override var bounds: CGRect {
        didSet {
            updateCornerRadius()
        }
    }

    func setBackgroundImageColor(_ color: UIColor?, for state: UIControl.State) {
        if let color = color {
            setBackgroundImage(UIImage.singlePixelImage(with: color), for: state)
        } else {
            setBackgroundImage(nil, for: state)
        }
    }

    func borderColor(for state: UIControl.State) -> UIColor? {
        return borderColorByState[state] ?? borderColorByState[.normal]
    }

    private func updateBorderColor() {
        layer.borderColor = borderColor(for: state)?.cgColor
    }

    private func updateCornerRadius() {
        if circular {
            layer.cornerRadius = bounds.size.height / 2
        }
    }

    // MARK: - Observing state
    override var isHighlighted: Bool {
        didSet {
            updateAppearance(with: previousState)
        }
    }

    override var isSelected: Bool {
        didSet {
            updateAppearance(with: previousState)
        }
    }

    override var isEnabled: Bool {
        didSet {
            guard oldValue != isEnabled else { return }
            updateAppearance(with: previousState)
        }
    }

    private func updateAppearance(with previousState: UIControl.State?) {
        guard state != previousState else {
            return
        }

        // Update for new state (selected, highlighted, disabled) here if needed
        updateBorderColor()

        self.previousState = state
    }

    override func setTitle(_ title: String?, for state: UIControl.State) {
        var title = title
        state.expanded.forEach() { expandedState in
            if title != nil {
                originalTitles[expandedState] = title
            } else {
                originalTitles[expandedState] = nil
            }
        }

        if textTransform != .none {
            title = title?.applying(transform: textTransform)
        }

        super.setTitle(title, for: state)
    }

    func setBorderColor(_ color: UIColor?, for state: UIControl.State) {
        state.expanded.forEach() { expandedState in
            if color != nil {
                borderColorByState[expandedState] = color
            }
        }

        updateBorderColor()
    }
}
