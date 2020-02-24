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


final class ColorKnobView: UIView {
    var isSelected = false {
        didSet {
            borderCircleLayer.borderColor = knobBorderColor()?.cgColor
            borderCircleLayer.borderWidth = selected ? 1.0 : 0.0
        }
    }
    var knobColor: UIColor? {
        didSet {
            innerCircleLayer.backgroundColor = knobFillColor()?.cgColor
            innerCircleLayer.borderColor = knobBorderColor()?.cgColor
            borderCircleLayer.borderColor = knobBorderColor()?.cgColor
        }
    }

    var knobDiameter: CGFloat = 0.0

    /// The actual circle knob, filled with the color
    private var innerCircleLayer: CALayer?
    /// Just a layer, used for the thin border around the selected knob
    private var borderCircleLayer: CALayer?
    
    init() {
        super.init()
        knobDiameter = 6
        
        let innerCircleLayer = CALayer()
        self.innerCircleLayer = innerCircleLayer
        if let innerCircleLayer = self.innerCircleLayer {
            layer.addSublayer(innerCircleLayer)
        }
        
        let borderCircleLayer = CALayer()
        self.borderCircleLayer = borderCircleLayer
        if let borderCircleLayer = self.borderCircleLayer {
            layer.addSublayer(borderCircleLayer)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let frame = self.frame
        let centerPos = [frame.size.width / 2, frame.size.height / 2]
        
        let knobDiameter: CGFloat = self.knobDiameter + 1
        innerCircleLayer.bounds = [
            [0, 0],
            [knobDiameter, knobDiameter]
        ]
        innerCircleLayer.position = centerPos
        innerCircleLayer.cornerRadius = knobDiameter / 2
        innerCircleLayer.borderWidth = 1.0
        
        let knobBorderDiameter = knobDiameter + 6.0
        borderCircleLayer.bounds = [
            [0, 0],
            [knobBorderDiameter, knobBorderDiameter]
        ]
        borderCircleLayer.position = centerPos
        borderCircleLayer.cornerRadius = knobBorderDiameter / 2
    }
    
    // MARK: - Helpers
    func knobBorderColor() -> UIColor? {
        if (knobColor == UIColor.white && ColorScheme.default().variant == ColorSchemeVariantLight) || (knobColor == UIColor.black && ColorScheme.default().variant == ColorSchemeVariantDark) {
            return UIColor.lightGray
        }
        return knobColor
    }
    
    func knobFillColor() -> UIColor? {
        return knobColor
    }

}
