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

extension ProgressSpinner {
    @objc
    func setupConstraints() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerInSuperview()
    }
    
    @objc
    func startAnimationInternal() {
        isHidden = false
        stopAnimationInternal()
        if window != nil {
            spinner.layer.add(CABasicAnimation(rotationSpeed: 1.4, beginTime: 0, delegate: self), forKey: "rotateAnimation")
        }
    }
}
