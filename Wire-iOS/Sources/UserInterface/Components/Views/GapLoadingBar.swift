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

class GapLoadingBar: UIView {

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

    private let GapLoadingAnimationKey: String = "gapLoadingAnimation"

    let gapLayer: GapLayer
    var gapSize: CGFloat = 0.0
    var animationDuration: TimeInterval = 0.0

    var isAnimationRunning: Bool {
        return gapLayer.animation(forKey: GapLoadingAnimationKey) != nil
    }

    init(gapSize: CGFloat, animationDuration duration: TimeInterval) {
        gapLayer = GapLayer()
        animating = false

        super.init(frame: .zero)

        gapLayer.gapSize = gapSize
        layer.mask = gapLayer

        self.gapSize = gapSize
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
        gapLayer.bounds = CGRect(origin: .zero, size: bounds.size)
        gapLayer.position = CGPoint(x: self.bounds.size.width / 2, y: self.bounds.size.height / 2)
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
        let anim = CABasicAnimation(keyPath: NSStringFromSelector(#selector(getter: GapLayer.gapPosition)))
        anim.fromValue = -gapSize
        anim.toValue = bounds.size.width + gapSize
        anim.isRemovedOnCompletion = false
        anim.autoreverses = false
        anim.fillMode = kCAFillModeForwards
        anim.repeatCount = .infinity
        anim.duration = animationDuration
        anim.timingFunction = CAMediaTimingFunction.easeInOutQuart()
        gapLayer.add(anim, forKey: GapLoadingAnimationKey)
    }

    func stopAnimation() {
        gapLayer.removeAnimation(forKey: GapLoadingAnimationKey)
    }

    static public func withDefaultGapSizeAndAnimationDuration() -> GapLoadingBar {
        ///FIXME: do not use magic
        let gapSize: CGFloat = WAZUIMagic.cgFloat(forIdentifier: "system_status_bar.loading_gap_size")
        let animationDuration: TimeInterval = TimeInterval(WAZUIMagic.cgFloat(forIdentifier: "system_status_bar.loading_gap_animation_duration"))
        return GapLoadingBar(gapSize: gapSize, animationDuration: animationDuration)
    }

}

