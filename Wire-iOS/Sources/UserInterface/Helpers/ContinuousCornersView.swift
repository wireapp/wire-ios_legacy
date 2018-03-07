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

class ContinuousCornersView: UIView {
    
    let maskLayer: CAShapeLayer
    
    var cornerRadius: CGFloat {
        didSet {
            refreshMask()
        }
    }
    
    init(cornerRadius: CGFloat) {
        self.maskLayer = CAShapeLayer()
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
        
        layer.mask = maskLayer
        refreshMask()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        refreshMask()
    }
    
    private func refreshMask() {
        maskLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }
    
}
