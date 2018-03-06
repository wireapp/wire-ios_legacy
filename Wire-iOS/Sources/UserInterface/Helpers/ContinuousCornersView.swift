//
//  ContinuousCornersView.swift
//  Wire-iOS
//
//  Created by Alexis Aubry on 06.03.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
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
