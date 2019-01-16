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


import Foundation

@objcMembers open class CircularProgressView: UIView {
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    fileprivate func setup() {
        setupShapeLayer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(CircularProgressView.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    fileprivate func setupShapeLayer() {
        self.createPath()
        self.shapeLayer.lineWidth = CGFloat(lineWidth)
        self.shapeLayer.lineCap = .square
        self.shapeLayer.strokeStart = 0.0
        self.shapeLayer.strokeEnd = CGFloat(self.progress)
        self.shapeLayer.fillColor = UIColor.clear.cgColor
        self.shapeLayer.strokeColor = self.tintColor.cgColor
    }
    
    override open func didMoveToWindow() {
        updateSpinningAnimation()
    }
    
    override open var tintColor: UIColor! {
        didSet {
            self.shapeLayer.strokeColor = self.tintColor.cgColor
        }
    }
    
    @objc open var lineWidth : Float = 2 {
        didSet {
            setNeedsLayout()
        }
    }
    
    @objc open var deterministic : Bool = true {
        didSet {
            updateSpinningAnimation()
        }
    }
    
    fileprivate func createPath() {
        self.shapeLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.bounds.width/2).cgPath
    }
    
    override open class var layerClass : AnyClass {
        return CAShapeLayer.self
    }
    
    @objc open var shapeLayer: CAShapeLayer {
        get {
            if let shapeLayer = self.layer as? CAShapeLayer {
                return shapeLayer
            }
            fatalError("shapeLayer is missing: \(self.layer)")
        }
    }
    
    @objc open fileprivate(set) var progress : Float = 0.0
        
    @objc open func setProgress(_ progress: Float, animated: Bool) {
        self.progress = progress
        
        if (animated) {
            let stroke = CABasicAnimation(keyPath: "strokeEnd")
            stroke.fromValue = self.shapeLayer.strokeEnd
            stroke.toValue = progress
            stroke.duration = 0.35
            stroke.fillMode = .forwards
            
            self.shapeLayer.add(stroke, forKey: nil)
        } else {
            let stroke = CABasicAnimation(keyPath: "strokeEnd")
            stroke.fromValue = CGFloat(progress)
            self.shapeLayer.add(stroke, forKey: nil)
        }
        
        CATransaction.setDisableActions(true)
        self.shapeLayer.strokeEnd = CGFloat(progress)
        CATransaction.setDisableActions(false)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.setupShapeLayer()
    }
    
    /// pragma mark - Spinning animation
    
    @objc let SpinningAnimationKey = "com.wire.animations.spin"
    
    fileprivate func updateSpinningAnimation() {
        if !deterministic {
            startSpinningAnimation()
        } else {
            stopSpinningAnimation()
        }
    }
    
    fileprivate func startSpinningAnimation() {
        let rotate = CABasicAnimation.init(keyPath: "transform.rotation.z")
        rotate.fillMode = .forwards
        rotate.toValue = 2 * CGFloat.pi
        rotate.repeatCount = .infinity
        rotate.duration = 1.0
        rotate.isCumulative = true
        rotate.timingFunction = CAMediaTimingFunction(name: .linear)
        
        self.shapeLayer.add(rotate, forKey: SpinningAnimationKey);
    }
    
    fileprivate func stopSpinningAnimation() {
        self.shapeLayer.removeAnimation(forKey: SpinningAnimationKey)
    }
}

extension CircularProgressView {
    @objc func applicationDidBecomeActive(_ notification : Notification) {
        updateSpinningAnimation()
    }
}
