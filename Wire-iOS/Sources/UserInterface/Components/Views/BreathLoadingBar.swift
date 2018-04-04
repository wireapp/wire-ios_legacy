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
import Cartography

protocol BreathLoadingBarDelegate: class {
    func animationDidStarted()
    func animationDidStopped()
}

class BreathLoadingBar: UIView {
    public weak var delegate: BreathLoadingBarDelegate?

    var heightConstraint: NSLayoutConstraint?

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

    private var _state: NetworkStatusViewState = .online

    var state: NetworkStatusViewState {
        set {
            update(state: newValue, animated: false)
        }
        get {
            return _state
        }
    }

    func update(state: NetworkStatusViewState, animated: Bool) {
        guard self.state != state else { return }

        _state = state

        updateView(animated: animated)
    }

    private func updateView(animated: Bool = true) {
        switch state {
        case .online:
            heightConstraint?.constant = 0
            alpha = 0
            layer.cornerRadius = 0
        case .onlineSynchronizing:
            heightConstraint?.constant = CGFloat.SyncBar.height
            alpha = 1
            layer.cornerRadius = CGFloat.SyncBar.cornerRadius
        case .offlineExpanded:
            heightConstraint?.constant = CGFloat.OfflineBar.expandedHeight
            alpha = 0
            layer.cornerRadius = CGFloat.OfflineBar.cornerRadius
        }

        self.layoutIfNeeded()
    }

    private let BreathLoadingAnimationKey: String = "breathLoadingAnimation"

    var animationDuration: TimeInterval = 0.0

    var isAnimationRunning: Bool {
        return layer.animation(forKey: BreathLoadingAnimationKey) != nil
    }

    init(animationDuration duration: TimeInterval) {
        animating = false

        super.init(frame: .zero)
        layer.cornerRadius = CGFloat.SyncBar.cornerRadius

        animationDuration = duration

        createConstraints()
        updateView(animated: false)

        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func createConstraints() {
        constrain(self) { selfView in
            heightConstraint = selfView.height == 0
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

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
        delegate?.animationDidStarted()

        let anim = CAKeyframeAnimation(keyPath: "opacity")
        anim.values = [0.64, 1, 0.64]
        anim.isRemovedOnCompletion = false
        anim.autoreverses = false
        anim.fillMode = kCAFillModeForwards
        anim.repeatCount = .infinity
        anim.duration = animationDuration
        anim.timingFunction = CAMediaTimingFunction.easeInOutQuart()
        self.layer.add(anim, forKey: BreathLoadingAnimationKey)
    }

    func stopAnimation() {
        delegate?.animationDidStopped()

        self.layer.removeAnimation(forKey: BreathLoadingAnimationKey)
    }

    static public func withDefaultAnimationDuration() -> BreathLoadingBar {
        let animationDuration: TimeInterval = 1
        return BreathLoadingBar(animationDuration: animationDuration)
    }

}
