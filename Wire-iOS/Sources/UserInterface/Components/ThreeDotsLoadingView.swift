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

import UIKit
import Foundation

final class ThreeDotsLoadingView: UIView {

    let loadingAnimationKey = "loading"
    let dotRadius = 2
    let activeColor = UIColor.from(scheme: .loadingDotActive)
    let inactiveColor = UIColor.from(scheme: .loadingDotInactive)

    let dot1 = UIView()
    let dot2 = UIView()
    let dot3 = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(dot1)
        addSubview(dot2)
        addSubview(dot3)

        setupViews()
        setupConstraints()
        startProgressAnimation()

        NotificationCenter.default.addObserver(self, selector: #selector(ThreeDotsLoadingView.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        [dot1, dot2, dot3].forEach { (dot) in
            dot.layer.cornerRadius = CGFloat(dotRadius)
            dot.backgroundColor = inactiveColor
        }
    }

    func setupConstraints() {

        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          leadingDot.leftAnchor.constraint(equalTo: container.leftAnchor),
          trailingDot.rightAnchor.constraint(equalTo: container.rightAnchor)
        ])

        [dot1, dot2, dot3].forEach { (dot) in
            [<#views#>].prepareForLayout()
            NSLayoutConstraint.activate([
              dot.topAnchor.constraint(equalTo: container.topAnchor),
              dot.bottomAnchor.constraint(equalTo: container.bottomAnchor),
              dot.widthAnchor.constraint(equalToConstant: CGFloat(dotRadius * 2)),
              dot.heightAnchor.constraint(equalToConstant: CGFloat(dotRadius * 2))
            ])
        }

        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([

        ])
    }

    override var isHidden: Bool {
        didSet {
            updateLoadingAnimation()
        }
    }

    func updateLoadingAnimation() {
        if isHidden {
            stopProgressAnimation()
        } else {
            startProgressAnimation()
        }
    }

    func startProgressAnimation() {
        let stepDuration = 0.350
        let colorShift = CAKeyframeAnimation(keyPath: "backgroundColor")
        colorShift.values = [activeColor.cgColor, inactiveColor.cgColor, inactiveColor.cgColor, activeColor.cgColor]
        colorShift.keyTimes = [0, 0.33, 0.66, 1]
        colorShift.duration = 4 * stepDuration
        colorShift.repeatCount = Float.infinity
        colorShift.speed = -1

        let colorShift1 = colorShift.copy() as! CAKeyframeAnimation
        colorShift1.timeOffset = 0
        dot1.layer.add(colorShift1, forKey: loadingAnimationKey)

        let colorShift2 = colorShift.copy()  as! CAKeyframeAnimation
        colorShift2.timeOffset = 1 * stepDuration
        dot2.layer.add(colorShift2, forKey: loadingAnimationKey)

        let colorShift3 = colorShift.copy()  as! CAKeyframeAnimation
        colorShift3.timeOffset = 2 * stepDuration
        dot3.layer.add(colorShift3, forKey: loadingAnimationKey)
    }

    func stopProgressAnimation() {
        [dot1, dot2, dot3].forEach { $0.layer.removeAnimation(forKey: loadingAnimationKey) }
    }

}

extension ThreeDotsLoadingView {
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        updateLoadingAnimation()
    }
}
