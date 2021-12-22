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

class PopUpIconButtonView: UIView {

    public var selectedIndex = 0

    private let button: PopUpIconButton

    // corner radii
    private let smallRadius: CGFloat = 4.0
    private let largeRadius: CGFloat = 10.0

    private let lowerRect: CGRect
    private let upperRect: CGRect
    private let itemWidth: CGFloat

    private let expandDirection: PopUpIconButtonExpandDirection

    init(withButton button: PopUpIconButton) {
        self.button = button
        // button rect in window coordinates
        lowerRect = button.convert(button.bounds, to: nil).insetBy(dx: -8.0, dy: -8.0)

        itemWidth = lowerRect.width + 2 * largeRadius

        var rect = lowerRect
        rect.size.height = lowerRect.height * 1.5
        rect.size.width = CGFloat(button.itemIcons.count) * itemWidth

        // first we test to see if the popup fits onscreen when expanding right,
        // if not we expand left
        if rect.minX - largeRadius + rect.width < UIScreen.main.bounds.maxX {
            expandDirection = .right
        } else {
            expandDirection = .left
        }

        // determine origin
        switch expandDirection {
        case .left:
            rect.origin.x -= largeRadius + CGFloat(button.itemIcons.count - 1) * itemWidth
            rect.origin.y -= largeRadius + lowerRect.height * 1.5
        case .right:
            rect.origin.x -= largeRadius
            rect.origin.y -= largeRadius + lowerRect.height * 1.5
        }

        upperRect = rect

        super.init(frame: UIScreen.main.bounds)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // this makes the popup view the only interactable view
        isUserInteractionEnabled = true
        backgroundColor = UIColor.clear
    }

    override func draw(_ rect: CGRect) {

        guard let path = pathForOverlay(), let context = UIGraphicsGetCurrentContext() else { return }

        context.saveGState()

        // overlay shadow
        let shadowColor = UIColor.from(scheme: .popUpButtonOverlayShadow).cgColor
        let offset = CGSize(width: 0.0, height: 2.0)
        let blurRadius: CGFloat = 4.0
        context.setShadow(offset: offset, blur: blurRadius, color: shadowColor)

        // overlay fill
        UIColor.from(scheme: .barBackground).set()
        path.fill()

        context.restoreGState()

        // button icon
        if let imageView = button.imageView {
            // rect in window coordinates
            let imageRect = imageView.convert(button.imageView!.bounds, to: nil)
            let image = button.icon(for: .normal)!.makeImage(size: .tiny, color: UIColor.from(scheme: .iconNormal))
            image.draw(in: imageRect)
        }

        // item icons
        if let buttonImageView = button.imageView {
            for (index, icon) in button.itemIcons.enumerated() {
                let itemRect = rectForItem(icon)!
                let iconColor = index == selectedIndex ? .accent() : UIColor.from(scheme: .iconNormal)
                let image = icon.makeImage(size: .medium, color: iconColor)
                // rect in window coordinates
                var imageRect = buttonImageView.convert(buttonImageView.bounds, to: nil)
                // center image in item rect
                imageRect.origin = itemRect.origin
                imageRect.origin.x += itemRect.midX - imageRect.midX
                imageRect.origin.y += itemRect.midY - imageRect.midY
                image.draw(in: imageRect)
            }
        }
    }

    private func pathForOverlay() -> UIBezierPath? {

        let rect = lowerRect
        let path = UIBezierPath()

        var point = rect.origin

        // how much to shift upper rect right w/ respect to lower rect
        let shiftFactor: CGFloat = 0.0

        // LOWER RECT

        // start at button origin
        path.move(to: point)

        // line to BL corner
        point.y += lowerRect.height - smallRadius
        path.addLine(to: point)

        // BL corner
        point.x += smallRadius
        path.addArc(withCenter: point, radius: smallRadius,
                    startAngle: .pi, endAngle: .pi*0.5, clockwise: false)

        // line to BR corner
        point.x += lowerRect.width - 2 * smallRadius
        point.y += smallRadius
        path.addLine(to: point)

        // BR corner
        point.y -= smallRadius
        path.addArc(withCenter: point, radius: smallRadius,
                    startAngle: .pi * 0.5, endAngle: 0, clockwise: false)

        // line to TR corner
        point.x += smallRadius
        point.y -= lowerRect.height - smallRadius
        path.addLine(to: point)

        switch expandDirection {
        case .right:

            // UPPER RECT

            // corner connecting top right of lower rect to upper rect
            point.x += largeRadius
            path.addArc(withCenter: point, radius: largeRadius,
                        startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)

            // line to BR corner
            point.x += CGFloat(button.itemIcons.count - 1) * itemWidth - largeRadius + shiftFactor
            point.y -= largeRadius
            path.addLine(to: point)

            // BR corner
            point.y -= largeRadius
            path.addArc(withCenter: point, radius: largeRadius,
                        startAngle: .pi * 0.5, endAngle: 0, clockwise: false)

            // line to UR corner
            point.x += largeRadius
            point.y -= upperRect.height - largeRadius * 2
            path.addLine(to: point)

            // UR corner
            point.x -= largeRadius
            path.addArc(withCenter: point, radius: largeRadius,
                        startAngle: 0, endAngle: .pi * 1.5, clockwise: false)

            // line to UL corner
            point.x = lowerRect.origin.x
            point.y -= largeRadius
            path.addLine(to: point)

            // UL corner
            point.y += largeRadius
            path.addArc(withCenter: point, radius: largeRadius,
                        startAngle: .pi * 1.5, endAngle: .pi, clockwise: false)

            // line to BL corner
            point.x -= largeRadius
            point.y += upperRect.height - largeRadius * 2
            path.addLine(to: point)

            // BL corner
            var cp1 = point
            cp1.y += largeRadius
            var cp2 = rect.origin
            cp2.y -= largeRadius
            path.addCurve(to: rect.origin, controlPoint1: cp1, controlPoint2: cp2)

            path.close()
            return path

        case .left:

            // UPPER RECT

            // corner connecting top right of lower rect to upper rect
            var cp1 = point
            cp1.y -= largeRadius

            point.x += largeRadius
            point.y -= largeRadius * 2

            var cp2 = point
            cp2.y += largeRadius
            path.addCurve(to: point, controlPoint1: cp1, controlPoint2: cp2)

            // line to UR corner
            point.y -= upperRect.height - largeRadius * 2
            path.addLine(to: point)

            // UR corner
            point.x -= largeRadius
            path.addArc(withCenter: point, radius: largeRadius,
                        startAngle: 0, endAngle: .pi * 1.5, clockwise: false)

            // line to UL corner
            point.x -= upperRect.width - largeRadius * 2
            point.y -= largeRadius
            path.addLine(to: point)

            // UL corner
            point.y += largeRadius
            path.addArc(withCenter: point, radius: largeRadius,
                        startAngle: .pi * 1.5, endAngle: .pi, clockwise: false)

            // line to BL corner
            point.x -= largeRadius
            point.y += upperRect.height - largeRadius * 2
            path.addLine(to: point)

            // BL corner
            point.x += largeRadius
            path.addArc(withCenter: point, radius: largeRadius,
                        startAngle: .pi, endAngle: .pi * 0.5, clockwise: false)

            // line to lower rect's TL corner
            point = lowerRect.origin
            point.x -= largeRadius
            point.y -= largeRadius
            path.addLine(to: point)

            // corner joining upper rect & lower rect
            point.y += largeRadius
            path.addArc(withCenter: point, radius: largeRadius,
                        startAngle: .pi * 1.5, endAngle: 0, clockwise: true)

            path.close()
            return path
        }
    }

    private func rectForItem(_ item: StyleKitIcon) -> CGRect? {

        let icons: [StyleKitIcon]
        switch expandDirection {
        case .left:     icons = button.itemIcons.reversed()
        case .right:    icons = button.itemIcons
        }

        guard let index = icons.firstIndex(of: item) else { return nil }

        var rect = CGRect(origin: upperRect.origin, size: CGSize(width: itemWidth, height: upperRect.height))

        // offset origin for item number
        rect.origin.x += CGFloat(index) * itemWidth
        return rect
    }

    public func updateSelectionForPoint(_ point: CGPoint) {

        switch expandDirection {
        case .left:
            let selection = button.itemIcons.enumerated()
                .filter { _, icon in point.x < rectForItem(icon)!.maxX }
                .map { index, _ in index }
                .last ?? 0
            selectedIndex = selection

        case .right:
            let selection = button.itemIcons.enumerated()
                .filter { _, icon in point.x > rectForItem(icon)!.origin.x }
                .map { index, _ in index }
                .last ?? 0
            selectedIndex = selection
        }

        setNeedsDisplay()
    }
}
