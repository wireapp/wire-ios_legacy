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

import Foundation
import UIKit

final class ProgressSpinner: UIView {

    var didBecomeActiveNotificationToken: NSObjectProtocol?
    var didEnterBackgroundNotificationToken: NSObjectProtocol?

    var color: UIColor = .white {
        didSet {
            updateSpinnerIcon()
        }
    }

    var iconSize: CGFloat = 32 {
        didSet {
            updateSpinnerIcon()
        }
    }

    var hidesWhenStopped: Bool = false {
        didSet {
            isHidden = hidesWhenStopped && !isAnimationRunning
        }
    }

    var isAnimating = false {
        didSet {
            guard oldValue != isAnimating else {
                return
            }

            isAnimating ? startAnimationInternal() : stopAnimationInternal()
        }
    }

    private let spinner: UIImageView = UIImageView()

    private var isAnimationRunning: Bool {
        return spinner.layer.animation(forKey: "rotateAnimation") != nil
    }

    init() {
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        createSpinner()
        setupConstraints()

        hidesWhenStopped = true

        didBecomeActiveNotificationToken = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.applicationDidBecomeActive()
        }

        didEnterBackgroundNotificationToken = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.applicationDidEnterBackground()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let frame = spinner.layer.frame
        spinner.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        spinner.layer.frame = frame
    }

    override func didMoveToWindow() {
        if window == nil {
            // CABasicAnimation delegate is strong so we stop all animations when the view is removed.
            stopAnimationInternal()
        } else if isAnimating {
            startAnimationInternal()
        }
    }

    private func createSpinner() {
        spinner.contentMode = .center
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)

        updateSpinnerIcon()
    }

    override var intrinsicContentSize: CGSize {
        return spinner.image?.size ?? super.intrinsicContentSize
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

    private func stopAnimationInternal() {
        spinner.layer.removeAllAnimations()
    }

    func updateSpinnerIcon() {
        spinner.image = UIImage.imageForIcon(.spinner, size: iconSize, color: color)
    }

    @objc
    func startAnimation() {
        isAnimating = true
    }

    @objc
    func stopAnimation() {
        isAnimating = false
    }

    private func applicationDidBecomeActive() {
        if isAnimating && !isAnimationRunning {
            startAnimationInternal()
        }
    }

    private func applicationDidEnterBackground() {
        if isAnimating {
            stopAnimationInternal()
        }
    }
}

extension ProgressSpinner: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if hidesWhenStopped {
            isHidden = true
        }
    }
}
