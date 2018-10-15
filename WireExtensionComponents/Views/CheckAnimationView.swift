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

class CheckAnimationView: UIView
{

    // MARK: - Initialization

    init()
    {
        super.init(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        self.setupLayers()
    }

    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.setupLayers()
    }

    // MARK: - Setup Layers

    private func setupLayers()
    {
        // Colors
        //
        let fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        let strokeColor = UIColor(red: 0.999639, green: 1, blue: 0.999756, alpha: 1)

        // Paths
        //
        let rectanglePath = CGMutablePath()
        rectanglePath.move(to: CGPoint(x: 0.127, y: 0))
        rectanglePath.addLine(to: CGPoint(x: 45.126999, y: 0))
        rectanglePath.addLine(to: CGPoint(x: 45.126999, y: 29))
        rectanglePath.addLine(to: CGPoint(x: 27.224001, y: 28.764999))
        rectanglePath.addLine(to: CGPoint(x: 0.127, y: 29))
        rectanglePath.addLine(to: CGPoint(x: 0, y: 14.977))
        rectanglePath.addLine(to: CGPoint(x: 0.127, y: 0))
        rectanglePath.closeSubpath()
        rectanglePath.move(to: CGPoint(x: 0.127, y: 0))

        // CheckAnimation
        //
        let checkAnimationLayer = CALayer()
        checkAnimationLayer.name = "CheckAnimation"
        checkAnimationLayer.bounds = CGRect(x: 0, y: 0, width: 48, height: 48)
        checkAnimationLayer.position = CGPoint(x: -1, y: -3)
        checkAnimationLayer.anchorPoint = CGPoint(x: 0, y: 0)
        checkAnimationLayer.contentsGravity = .center

            // CheckAnimation Sublayers
            //

            // Rectangle 2
            //
            let rectangleLayer = CAShapeLayer()
            rectangleLayer.name = "Rectangle 2"
            rectangleLayer.bounds = CGRect(x: 0, y: 0, width: 45.127417, height: 29)
            rectangleLayer.position = CGPoint(x: 20.69676, y: 35.932799)
            rectangleLayer.anchorPoint = CGPoint(x: 0, y: 1)
            rectangleLayer.contentsGravity = .center
            rectangleLayer.transform = CATransform3D( m11: 0.565685, m12: -0.565685, m13: 0, m14: 0,
                                                  m21: 0.565685, m22: 0.565685, m23: 0, m24: 0,
                                                  m31: 0, m32: 0, m33: 1, m34: 0,
                                                  m41: 0, m42: 0, m43: 0, m44: 1 )

                // Rectangle 2 Animations
                //

                // strokeDraw
                //
                let strokeDrawAnimation = CABasicAnimation()
                strokeDrawAnimation.beginTime = self.layer.convertTime(CACurrentMediaTime(), from: nil) + 0.15
                strokeDrawAnimation.duration = 1.719
                strokeDrawAnimation.speed = 2.5
                strokeDrawAnimation.fillMode = .forwards
                strokeDrawAnimation.isRemovedOnCompletion = false
                strokeDrawAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.7, 0.002841, 0.3, 1)
                strokeDrawAnimation.keyPath = "strokeStart"
                strokeDrawAnimation.toValue = 0.62
                strokeDrawAnimation.fromValue = 0.9
                strokeDrawAnimation.byValue = 0

                rectangleLayer.add(strokeDrawAnimation, forKey: "strokeDrawAnimation")

                // transform.scale.y
                //
                let transformScaleYAnimation = CABasicAnimation()
                transformScaleYAnimation.beginTime = self.layer.convertTime(CACurrentMediaTime(), from: nil) + 0.005
                transformScaleYAnimation.duration = 0.812599
                transformScaleYAnimation.fillMode = .forwards
                transformScaleYAnimation.isRemovedOnCompletion = false
                transformScaleYAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                transformScaleYAnimation.keyPath = "transform.scale.y"
                transformScaleYAnimation.toValue = 1

                rectangleLayer.add(transformScaleYAnimation, forKey: "transformScaleYAnimation")

                // transform.scale.x
                //
                let transformScaleXAnimation = CABasicAnimation()
                transformScaleXAnimation.beginTime = self.layer.convertTime(CACurrentMediaTime(), from: nil) + 0.005
                transformScaleXAnimation.duration = 0.812599
                transformScaleXAnimation.fillMode = .forwards
                transformScaleXAnimation.isRemovedOnCompletion = false
                transformScaleXAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                transformScaleXAnimation.keyPath = "transform.scale.x"
                transformScaleXAnimation.toValue = 1

                rectangleLayer.add(transformScaleXAnimation, forKey: "transformScaleXAnimation")
            rectangleLayer.path = rectanglePath
            rectangleLayer.fillColor = fillColor.cgColor
            rectangleLayer.strokeColor = strokeColor.cgColor
            rectangleLayer.fillRule = .evenOdd
            rectangleLayer.lineWidth = 4
            rectangleLayer.strokeStart = 0.9
            rectangleLayer.strokeEnd = 0.9

            checkAnimationLayer.addSublayer(rectangleLayer)

        self.layer.addSublayer(checkAnimationLayer)

    }

    // MARK: - Responder

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let location = touches.first?.location(in: self.superview),
              let hitLayer = self.layer.presentation()?.hitTest(location) else { return }

        print("Layer \(hitLayer.name ?? String(describing: hitLayer)) was tapped.")
    }
}
