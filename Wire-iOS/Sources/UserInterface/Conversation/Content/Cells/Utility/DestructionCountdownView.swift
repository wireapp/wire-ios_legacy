//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cartography

@objcMembers public final class DestructionCountdownView: UIView {

    private let remainingTimeLayer = CAShapeLayer()
    private let elapsedTimeLayer = CAShapeLayer()
    private let elapsedTimeAnimationKey = "elapsedTime"

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureSublayers()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSublayers()
    }

    private func configureSublayers() {
        layer.addSublayer(remainingTimeLayer)
        layer.addSublayer(elapsedTimeLayer)

        elapsedTimeLayer.strokeEnd = 0
        elapsedTimeLayer.isOpaque = false
        remainingTimeLayer.isOpaque = false

        let background = UIColor.from(scheme: .contentBackground)

        elapsedTimeColor = UIColor.lightGraphite
            .withAlphaComponent(0.24)
            .removeAlphaByBlending(with: background)

        remainingTimeColor = UIColor.lightGraphite.withAlphaComponent(0.64).removeAlphaByBlending(with: .white)
    }

    // MARK: - Layout

    public override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        elapsedTimeLayer.frame = bounds
        elapsedTimeLayer.path = makePath(for: bounds)
        elapsedTimeLayer.fillColor = nil
        elapsedTimeLayer.lineWidth = min(bounds.width, bounds.height) / 2 + 0.25

        remainingTimeLayer.frame = bounds
        remainingTimeLayer.path = CGPath(ellipseIn: bounds, transform: nil)
    }

    private func makePath(for bounds: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.addArc(center: CGPoint(x: bounds.midX, y: bounds.midY), radius: min(bounds.height, bounds.width) / 4, startAngle: -.pi / 2, endAngle: 3 * .pi / 2, clockwise: false)
        return path
    }

    // MARK: - Animation

    @objc public var isAnimatingProgress: Bool {
        return elapsedTimeLayer.animation(forKey: elapsedTimeAnimationKey) != nil
    }

    @objc public var remainingTimeColor: UIColor? {
        get {
            return remainingTimeLayer.fillColor.flatMap(UIColor.init)
        }
        set {
            remainingTimeLayer.fillColor = newValue?.cgColor
        }
    }

    @objc public var elapsedTimeColor: UIColor? {
        get {
            return elapsedTimeLayer.strokeColor.flatMap(UIColor.init)
        }
        set {
            elapsedTimeLayer.strokeColor = newValue?.withAlphaComponent(1).cgColor
            elapsedTimeLayer.opacity = Float(newValue?.alpha ?? CGFloat(0))
        }
    }

    @objc public func startAnimating(duration: TimeInterval, currentProgress: CGFloat) {

        let elapsedTimeAnimation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
        elapsedTimeAnimation.duration = duration
        elapsedTimeAnimation.fromValue = currentProgress
        elapsedTimeAnimation.toValue = 1
        elapsedTimeAnimation.fillMode = .forwards
        elapsedTimeAnimation.isRemovedOnCompletion = false

        elapsedTimeLayer.add(elapsedTimeAnimation, forKey: elapsedTimeAnimationKey)

    }

    @objc public func stopAnimating() {
        elapsedTimeLayer.removeAllAnimations()
    }

    @objc public func setProgress(_ newValue: CGFloat) {
        elapsedTimeLayer.strokeEnd = newValue
    }

}
