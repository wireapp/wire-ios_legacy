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
    convenience init(rotationSpeed: CFTimeInterval,
                     beginTime: CFTimeInterval,
                     delegate: CAAnimationDelegate? = nil) {
        self.init(keyPath: #keyPath(CALayer.transform))
        valueFunction = CAValueFunction(name: CAValueFunctionName.rotateZ)
        
        fillMode = .forwards
        self.delegate = delegate
        
        // Do a series of 5 quarter turns for a total of a 1.25 turns
        // (2PI is a full turn, so pi/2 is a quarter turn)
        toValue = Float.pi / 2
        repeatCount = .infinity
        
        duration = rotationSpeed / 4
        self.beginTime = beginTime
        isCumulative = true
        timingFunction = CAMediaTimingFunction(name: .linear)
    }
}
