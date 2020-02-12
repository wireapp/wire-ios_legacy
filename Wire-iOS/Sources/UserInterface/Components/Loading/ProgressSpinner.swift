//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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


final class ProgressSpinner: UIView {
    var color: UIColor?
    var iconSize: CGFloat = 0.0
    var hidesWhenStopped: Bool = false {
        didSet {
            isHidden = hidesWhenStopped && !isAnimationRunning
        }
    }

    var animating = false
    
    private let spinner: UIImageView = UIImageView()
    
    private var isAnimationRunning = false

    override init() {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        iconSize = 32
        color = UIColor.white
        
        createSpinner()
        setupConstraints()
        
        hidesWhenStopped = true
        
        ///TODO: closure
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let frame = spinner.layer.frame
        spinner.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        spinner.layer.frame = frame
    }
    
    private func createSpinner() {
        spinner.contentMode = .center
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)
        
        updateSpinnerIcon()
    }
    
    override var intrinsicContentSize: CGSize {
        return spinner.image.size
    }

    
    private func setupConstraints() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerInSuperview()
    }
    
    private func startAnimationInternal() {
        isHidden = false
        stopAnimationInternal()
        if window != nil {
            spinner.layer.add(CABasicAnimation(rotationSpeed: 1.4, beginTime: 0, delegate: self), forKey: "rotateAnimation")
        }
    }
    
    func setColor(_ color: UIColor?) {
        if self.color == color {
            return
        }
        self.color = color
        
        updateSpinnerIcon()
    }
    
    var iconSize: Int {
        get {
            return super.iconSize
        }
        set(iconSize) {
            self.iconSize = iconSize
            updateSpinnerIcon()
        }
    }
    
    
    func setAnimating(_ animating: Bool) {
        if self.animating == animating {
            return
        }
        self.animating = animating
        
        if animating {
            startAnimationInternal()
        } else {
            stopAnimationInternal()
        }
    }
    
    private func stopAnimationInternal() {
        spinner.layer.removeAllAnimations()
    }
    
    func updateSpinnerIcon() {
        spinner.image = UIImage(for: WRStyleKitIconSpinner, size: iconSize, color: color)
    }
    
    func startAnimation(_ sender: Any?) {
        animating = true
    }
    
    func stopAnimation(_ sender: Any?) {
        animating = false
    }
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if hidesWhenStopped {
            hidden = true
        }
    }
    
    @objc
    func applicationDidBecomeActive(_ sender: Any?) {
        if animating && !isAnimationRunning() {
            startAnimationInternal()
        }
    }
    
    @objc
    func applicationDidEnterBackground(_ sender: Any?) {
        if animating {
            stopAnimationInternal()
        }
    }
    
    func didMoveToWindow() {
        if window == nil {
            // CABasicAnimation delegate is strong so we stop all animations when the view is removed.
            stopAnimationInternal()
        } else if animating {
            startAnimationInternal()
        }
    }
    
    func isAnimationRunning() -> Bool {
        return spinner.layer.animation(forKey: "rotateAnimation") != nil
    }

}

extension ProgressSpinner: CAAnimationDelegate {
}
