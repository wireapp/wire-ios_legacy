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

final class ColorKnobView: UIView {
    var isSelected = false {
        didSet {
            borderCircleLayer.borderColor = knobBorderColor?.cgColor
            borderCircleLayer.borderWidth = isSelected ? 1 : 0
        }
    }

    var knobColor: UIColor? {
        didSet {
            innerCircleLayer.backgroundColor = knobColor?.cgColor
            innerCircleLayer.borderColor = knobBorderColor?.cgColor
            borderCircleLayer.borderColor = knobBorderColor?.cgColor
        }
    }

    var knobDiameter: CGFloat = 6

    /// The actual circle knob, filled with the color
    private var innerCircleLayer: CALayer = CALayer()
    /// Just a layer, used for the thin border around the selected knob
    private var borderCircleLayer: CALayer = CALayer()

    init() {
        super.init(frame: .zero)

        layer.addSublayer(innerCircleLayer)
        layer.addSublayer(borderCircleLayer)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let frame = self.frame
        let centerPos = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)

        let knobDiameter: CGFloat = self.knobDiameter + 1
        innerCircleLayer.bounds = CGRect(origin: .zero, size: CGSize(width: knobDiameter, height: knobDiameter))
        innerCircleLayer.position = centerPos
        innerCircleLayer.cornerRadius = knobDiameter / 2
        innerCircleLayer.borderWidth = 1

        let knobBorderDiameter = knobDiameter + 6
        borderCircleLayer.bounds = CGRect(origin: .zero, size: CGSize(width: knobBorderDiameter, height: knobBorderDiameter))
        borderCircleLayer.position = centerPos
        borderCircleLayer.cornerRadius = knobBorderDiameter / 2
    }

    // MARK: - Helpers
    var knobBorderColor: UIColor? {
        if (knobColor == .white && ColorScheme.default.variant == .light) ||
            (knobColor == .black && ColorScheme.default.variant == .dark) {
            return .lightGray
        }
        return knobColor
    }
}
