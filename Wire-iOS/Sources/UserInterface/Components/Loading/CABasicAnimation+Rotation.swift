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


extension CABasicAnimation {
    class func rotateAnimation(with rotationSpeed: CGFloat, beginTime: CGFloat, delegate: CAAnimationDelegate? = nil) -> CABasicAnimation {
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.fillMode = .forwards
        rotate.delegate = delegate
        
        // Do a series of 5 quarter turns for a total of a 1.25 turns
        // (2PI is a full turn, so pi/2 is a quarter turn)
        rotate.toValue = NSNumber(value: Float.pi / 2)
        rotate.repeatCount = MAXFLOAT
        
        rotate.duration = CFTimeInterval(rotationSpeed / 4)
        rotate.beginTime = CFTimeInterval(beginTime)
        rotate.isCumulative = true
        rotate.timingFunction = CAMediaTimingFunction(name: .linear)
        
        return rotate
    }
}
