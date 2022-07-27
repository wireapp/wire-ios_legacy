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

public class TimedCircularProgressView: CircularProgressView {
    public typealias Completion = () -> Void
    public var duration: CFTimeInterval = 5
    private var completion: Completion?
    public func animate(with completion: @escaping Completion) {
        self.completion = completion

        let stroke = CABasicAnimation(keyPath: "strokeEnd")
        stroke.fromValue = shapeLayer.strokeEnd
        stroke.toValue = 1
        stroke.duration = duration
        stroke.fillMode = .forwards
        stroke.isRemovedOnCompletion = false
        stroke.delegate = self
        shapeLayer.add(stroke, forKey: nil)
    }
}

extension TimedCircularProgressView: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        completion?()
    }
}
