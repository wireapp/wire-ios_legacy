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

protocol IconImageStyle {
    var icon: StyleKitIcon? { get }
    var tintColor: UIColor? { get }
    var accessibilityIdentifier: String { get }
    var accessibilityPrefix: String { get }
    var accessibilitySuffix: String { get }
}

extension IconImageStyle {
    var accessibilityPrefix: String {
        return "img"
    }
    
    var accessibilityIdentifier: String {
        return "\(accessibilityPrefix).\(accessibilitySuffix)"
    }
    
    var tintColor: UIColor? {
        return nil
    }
}

class PulsatingIconImageView: IconImageView {
    var pulsatingLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(pulsatingLayer)
        pulsatingLayer.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func set(style: IconImageStyle? = nil, size: StyleKitIcon.Size? = nil, color: UIColor? = nil) {
        super.set(style: style, size: size, color: color)
        setLayer()
    }

    private func setLayer() {
        let size = self.size.rawValue
        let path = UIBezierPath(
            arcCenter: .zero ,
            radius: size / 2 + 2,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        
        pulsatingLayer.path = path.cgPath
        pulsatingLayer.strokeColor = UIColor.clear.cgColor
        pulsatingLayer.lineWidth = 1
        pulsatingLayer.fillColor = color.withAlphaComponent(0.2).cgColor
        pulsatingLayer.position = CGPoint(x: size / 2 , y: size / 2)
    }
    
    private var pulsatingAnimation: CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = 1.5
        animation.duration = 1
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.autoreverses = true
        animation.repeatCount = .infinity
        return animation
    }
    
    func startPulsing() {
        pulsatingLayer.isHidden = false
        pulsatingLayer.add(pulsatingAnimation, forKey: "pulsating")
    }
    
    func stopPulsing() {
        pulsatingLayer.isHidden = true
        pulsatingLayer.removeAnimation(forKey: "pulsating")
    }
}

class IconImageView: UIImageView {
    private(set) var size: StyleKitIcon.Size = .tiny
    private(set) var color: UIColor = UIColor.from(scheme: .iconGuest)
    private(set) var style: IconImageStyle?

    override init(frame: CGRect) {
        super.init(frame: frame)
        image = UIImage()
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var accessibilityIdentifier: String? {
        get {
            return style?.accessibilityIdentifier
        }
        set {
            // no-op
        }
    }
    
    func set(style: IconImageStyle? = nil,
             size: StyleKitIcon.Size? = nil,
             color: UIColor? = nil) {
        // save size and color if needed
        set(size: size, color: color)

        guard
            let style = style ?? self.style,
            let icon = style.icon
        else {
            isHidden = true
            return
        }
        
        isHidden = false
        let color = style.tintColor ?? self.color
        self.setIcon(icon, size: self.size, color: color)
        self.style = style
    }
    
    private func set(size: StyleKitIcon.Size?, color: UIColor?) {
        guard let size = size, let color = color else {
            return
        }
        
        self.size = size
        self.color = color
    }
}
