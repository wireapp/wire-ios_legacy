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
import QuartzCore

class BreathLoadingBar: UIView {

    public var animating: Bool = false {
        didSet {
            guard animating != oldValue else { return}

            if animating {
                startAnimation()
            } else {
                stopAnimation()
            }

        }
    }

    private let BreathLoadingAnimationKey: String = "breathLoadingAnimation"

    let breathLayer: CALayer
    var animationDuration: TimeInterval = 0.0

    var isAnimationRunning: Bool {
        return breathLayer.animation(forKey: BreathLoadingAnimationKey) != nil
    }

    init(animationDuration duration: TimeInterval) {
        breathLayer = CALayer()
        animating = false

        super.init(frame: .zero)

        layer.mask = breathLayer

        animationDuration = duration
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        breathLayer.bounds = CGRect(origin: .zero, size: bounds.size)
        breathLayer.position = CGPoint(x: self.bounds.size.width / 2, y: self.bounds.size.height / 2)
        // restart animation
        if animating {
            startAnimation()
        }
    }

    func applicationDidBecomeActive(_ sender: Any) {
        if animating && !isAnimationRunning {
            startAnimation()
        }
    }

    func applicationDidEnterBackground(_ sender: Any) {
        if animating {
            stopAnimation()
        }
    }

    func startAnimation() {
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = 0.4
        anim.toValue = 1
        anim.isRemovedOnCompletion = false
        anim.autoreverses = false
        anim.fillMode = kCAFillModeForwards
        anim.repeatCount = .infinity
        anim.duration = animationDuration
        anim.timingFunction = CAMediaTimingFunction.easeInOutQuart()
        breathLayer.add(anim, forKey: BreathLoadingAnimationKey)
    }

    func stopAnimation() {
        breathLayer.removeAnimation(forKey: BreathLoadingAnimationKey)
    }

    static public func withDefaultBreathSizeAndAnimationDuration() -> BreathLoadingBar {
        let animationDuration: TimeInterval = 1
        return BreathLoadingBar(animationDuration: animationDuration)
    }

}
