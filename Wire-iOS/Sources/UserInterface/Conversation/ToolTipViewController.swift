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
import Cartography

extension UIImage {
   static func arrowImageWithColor(_ color: UIColor) -> UIImage {
        
        let result : UIImage
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 16, height: 8), false, UIScreen.main.scale) //without this option, default scale is 1
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0.0, y: 8.0))
        bezierPath.addLine(to: CGPoint(x: 8, y: 0.0))
        bezierPath.addLine(to: CGPoint(x: 16, y: 8.0))
        bezierPath.close()
       
        color.setFill()
        color.setStroke()
        bezierPath.lineWidth = 0
        bezierPath.stroke()
        bezierPath.fill()
        
        result = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return result
    }
}

@objc final class ToolTip: NSObject {
    
    let title, descriptionText: String
    let tapHandler: (()->())?
    
    init(title: String, description: String,  handler: @escaping (()->())? = nil) {
        self.title = title
        descriptionText = description
        tapHandler = handler
    }
}

@objc final class ToolTipViewController: UIViewController {
    
    let contentView = UIView()
    let arrowView = UIImageView()
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    var arrowConstraint : Cartography.ConstraintGroup? = nil
    let padding: CGFloat = 5
    
    fileprivate var accentColorChangeHandler : AccentColorChangeHandler? = nil
    
    fileprivate var titleColor: UIColor? {
        didSet {
            guard let color = titleColor else { return }
            titleLabel.textColor = color
        }
    }
    
    var toolTip: ToolTip {
        didSet {
            configure(toolTip)
        }
    }
    
    fileprivate lazy var arrowImage : UIImage = {
        return UIImage.arrowImageWithColor(UIColor.white)
    }()
    
    
    init(toolTip: ToolTip) {
        self.toolTip = toolTip
        super.init(nibName: nil, bundle: nil)
        accentColorChangeHandler = AccentColorChangeHandler.addObserver(self) { [weak self] color, _ in
            self?.titleColor = color
        }
        createViews()
        createConstraints()
        createGestureRecognizer()
        CASStyler.default().styleItem(self)
        configure(toolTip) // swift does not call didSet/willSet in init, manually configure
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createViews() {
        arrowView.image = arrowImage
        [titleLabel, descriptionLabel].forEach { $0.numberOfLines = 0 }
        [contentView, arrowView].forEach(view.addSubview)
        [titleLabel, descriptionLabel].forEach(contentView.addSubview)
        titleLabel.textColor = UIColor.accent()
    }
    
    func createGestureRecognizer() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ToolTipViewController.didTapView(_:)))
        view.addGestureRecognizer(tapRecognizer)
    }
    
    func createConstraints() {
        let contentPadding : CGFloat = 16
        
        constrain(view, arrowView, contentView, titleLabel, descriptionLabel) {view, arrow, contentView, title, description in
            
            arrow.top == view.top
            
            contentView.top == arrow.bottom
            contentView.left == view.left + padding
            contentView.right == view.right - padding
            contentView.bottom == view.bottom - padding
            
            
            title.top == contentView.top + contentPadding
            title.left == contentView.left + contentPadding
            title.right == contentView.right - contentPadding
            
            description.top == title.bottom + contentPadding / 2
            description.left == title.left
            description.right == title.right
            description.bottom == contentView.bottom - contentPadding
        }
    }
    
    func makeTipPointToView(_ view: UIView) {
        if let arrowConstraint = self.arrowConstraint {
            
            self.arrowConstraint = constrain(arrowView, view, replace: arrowConstraint) { arrowView, view in
                arrowView.centerX == view.centerX
            }
        } else {
            arrowConstraint = constrain(arrowView, view) { arrowView, view in
                arrowView.centerX == view.centerX
            }
        }
    }
    
    fileprivate func configure(_ toolTip: ToolTip) {
        titleLabel.text = toolTip.title
        descriptionLabel.text = toolTip.descriptionText
    }
    
    func didTapView(_ recognizer: UITapGestureRecognizer) {
        toolTip.tapHandler()
    }
}

