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

import UIKit
import WireCommonComponents

enum IconButtonStyle {
    case `default`
    case circular
    case navigation
}

struct IconDefinition: Equatable {
    let type: StyleKitIcon
    let size: CGFloat
    let renderingMode: UIImage.RenderingMode
}

class IconButton: ButtonWithLargerHitArea {
    var circular = false {
        didSet {
            updateCircular()
        }
    }

    var borderWidth: CGFloat = 0.5 {
        didSet {
            updateCircular()
        }
    }

    var hasRoundCorners = false {
        didSet {
            updateCustomCornerRadius()
        }
    }

    var adjustsTitleWhenHighlighted = false
    var adjustsBorderColorWhenHighlighted = false
    var adjustBackgroundImageWhenHighlighted = false

    private var iconColorsByState: [UIControl.State: UIColor] = [:]
    private var borderColorByState: [UIControl.State: UIColor] = [:]
    private var iconDefinitionsByState: [UIControl.State: IconDefinition] = [:]
    private var priorState: UIControl.State?

    override init(fontSpec: FontSpec = .smallLightFont) {
        super.init(fontSpec: fontSpec)

        hitAreaPadding = CGSize(width: 20, height: 20)
    }

    convenience init(style: IconButtonStyle,
                     variant: ColorSchemeVariant = ColorScheme.default.variant,
                     fontSpec: FontSpec = .normalRegularFont) {
        self.init(fontSpec: fontSpec)

        setIconColor(UIColor.from(scheme: .iconNormal, variant: variant), for: .normal)
        setIconColor(UIColor.from(scheme: .iconSelected, variant: variant), for: .selected)
        setIconColor(UIColor.from(scheme: .iconHighlighted, variant: variant), for: .highlighted)
        setBackgroundImageColor(UIColor.from(scheme: .iconBackgroundSelected, variant: variant), for: .selected)

        switch style {
        case .default:
            break
        case .circular:
            circular = true
            borderWidth = 0
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            contentHorizontalAlignment = .center
        case .navigation:
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
            titleLabel?.font = fontSpec.font
            adjustsImageWhenDisabled = false
            borderWidth = 0
            contentHorizontalAlignment = .left
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateCircularCornerRadius()
    }

    // MARK: - Observing state
    override var isHighlighted: Bool {
        didSet {
            updateForNewStateIfNeeded()
        }
    }

    override var isSelected: Bool {
        didSet {
            updateForNewStateIfNeeded()
        }
    }

    override var isEnabled: Bool {
        didSet {
            updateForNewStateIfNeeded()
        }
    }

    override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state)

        if adjustsTitleWhenHighlighted && state.contains(.normal) {
            super.setTitleColor(titleColor(for: .highlighted)?.mix(UIColor.black, amount: 0.4), for: .highlighted)
        }
    }

    private func updateCircular() {
        if circular {
            layer.masksToBounds = true
            layer.borderWidth = borderWidth
            updateCircularCornerRadius()
        } else {
            layer.masksToBounds = false
            layer.borderWidth = 0.0
            layer.cornerRadius = 0
        }
    }

    func setTitleImageSpacing(_ titleImageSpacing: CGFloat, horizontalMargin: CGFloat = 0) {

        let isLeftToRight = UIView.userInterfaceLayoutDirection(for: .unspecified) == .leftToRight

        let inset = titleImageSpacing / 2.0
        let leftInset = isLeftToRight ? -inset : inset
        let rightInset = isLeftToRight ? inset : -inset

        imageEdgeInsets = UIEdgeInsets(top: imageEdgeInsets.top, left: leftInset, bottom: imageEdgeInsets.bottom, right: rightInset)
        titleEdgeInsets = UIEdgeInsets(top: titleEdgeInsets.top, left: rightInset, bottom: titleEdgeInsets.bottom, right: leftInset)

        let horizontal = inset + horizontalMargin
        contentEdgeInsets = UIEdgeInsets(top: contentEdgeInsets.top, left: horizontal, bottom: contentEdgeInsets.bottom, right: horizontal)
    }

    func setBackgroundImageColor(_ color: UIColor,
                                 for state: UIControl.State) {
        setBackgroundImage(UIImage.singlePixelImage(with: color), for: state)

        if adjustBackgroundImageWhenHighlighted && state.contains(.normal) {
            setBackgroundImage(UIImage.singlePixelImage(with: color.mix(UIColor.black, amount: 0.4)), for: .highlighted)
        }
    }

    func setIcon(_ iconType: StyleKitIcon?,
                 size: StyleKitIcon.Size,
                 for state: UIControl.State,
                 renderingMode: UIImage.RenderingMode = UIImage.RenderingMode.alwaysTemplate,
                 force: Bool = false) {

        setIcon(iconType, iconSize: size.rawValue, for: state, renderingMode: renderingMode, force: force)
    }

    /// set icon to a new icon or no icon
    ///
    /// - Parameters:
    ///   - iconType: the StyleKitIcontype
    ///   - iconSize: StyleKitIcon.Size
    ///   - state: UIControl state
    ///   - renderingMode: Default rendering mode is AlwaysTemplate
    ///   - force: force update
    func setIcon(_ iconType: StyleKitIcon?,
                 iconSize: CGFloat,
                 for state: UIControl.State,
                 renderingMode: UIImage.RenderingMode = UIImage.RenderingMode.alwaysTemplate,
                 force: Bool = false) {
        guard let iconType = iconType else {
            removeIcon(for: state)
            return
        }

        let newIcon = IconDefinition(type: iconType, size: iconSize, renderingMode: renderingMode)

        guard force || newIcon != iconDefinitionsByState[state] else {
            return
        }

        iconDefinitionsByState[state] = newIcon

        let color: UIColor
        if renderingMode == .alwaysOriginal,
            let iconColor = iconColor(for: .normal) {
            color = iconColor
        } else {
            color = .black
        }

        let image = UIImage.imageForIcon(iconType, size: iconSize, color: color)

        setImage(image.withRenderingMode(renderingMode), for: state)
    }

    func removeIcon(for state: UIControl.State) {
        iconDefinitionsByState[state] = nil
        setImage(nil, for: state)
    }

    func setIconColor(_ color: UIColor?,
                      for state: UIControl.State) {
        if nil != color {
            iconColorsByState[state] = color
        } else {
            iconColorsByState.removeValue(forKey: state)
        }

        if let currentIcon = iconDefinitionsByState[state],
            currentIcon.renderingMode == .alwaysOriginal {
            setIcon(currentIcon.type,
                    iconSize: currentIcon.size,
                    for: state,
                    renderingMode: currentIcon.renderingMode,
                    force: true)
        }

        updateTintColor()
    }

    func iconDefinition(for state: UIControl.State) -> IconDefinition? {
        return iconDefinitionsByState[state]
    }

    func iconColor(for state: UIControl.State) -> UIColor? {
        return iconColorsByState[state] ?? iconColorsByState[.normal]
    }

    func borderColor(for state: UIControl.State) -> UIColor? {
        return borderColorByState[state] ?? borderColorByState[.normal]
    }

    private func updateBorderColor() {
        layer.borderColor = borderColor(for: state)?.cgColor
    }

    func updateTintColor() {
        tintColor = iconColor(for: state)
    }

    private func updateCircularCornerRadius() {
        guard circular else { return }

        /// Create a circular mask. It would also mask subviews.

        let radius: CGFloat = bounds.size.height / 2
        let maskPath = UIBezierPath(roundedRect: bounds,
                                    byRoundingCorners: .allCorners,
                                    cornerRadii: CGSize(width: radius, height: radius))

        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = maskPath.cgPath

        layer.mask = maskLayer

        /// When the button has border, set self.layer.cornerRadius to prevent border is covered by icon
        layer.cornerRadius = borderWidth > 0 ? radius : 0
    }

    func updateCustomCornerRadius() {
        layer.cornerRadius = hasRoundCorners ? 6 : 0
    }

    private func updateForNewStateIfNeeded() {
        guard state != priorState else { return }

        priorState = state
        // Update for new state (selected, highlighted, disabled) here if needed
        updateTintColor()
        updateBorderColor()
    }

    func icon(for state: UIControl.State) -> StyleKitIcon? {
        return iconDefinition(for: state)?.type
    }

    func setBorderColor(_ color: UIColor?, for state: UIControl.State) {
        state.expanded.forEach { expandedState in
            if color != nil {
                borderColorByState[expandedState] = color

                if adjustsBorderColorWhenHighlighted &&
                    expandedState == .normal {
                    borderColorByState[.highlighted] = color?.mix(.black, amount: 0.4)
                }
            }
        }

        updateBorderColor()
    }
}
