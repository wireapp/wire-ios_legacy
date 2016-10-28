//
//  ImageToolbarView.swift
//  Wire-iOS
//
//  Created by Jacob on 28/10/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit
import Cartography


@objc enum ImageToolbarConfiguration : UInt {
    case conversation
    case preview
}

class ImageToolbarView: UIView {
    
    let gradientLayer = CAGradientLayer()
    let buttonContainer = UIView()
    let sketchButton = IconButton()
    let emojiButton = IconButton()
    let textButton = IconButton()
    let expandButton = IconButton()
    var buttons : [IconButton] = []
    
    var isPlacedOnImage : Bool = false {
        didSet {
            gradientLayer.isHidden = !isPlacedOnImage
            cas_styleClass = isPlacedOnImage ? "on-image" : "on-background"
        }
    }
    
    @objc public init(withConfiguraton configuration: ImageToolbarConfiguration) {
        super.init(frame: CGRect.zero)
        
        switch configuration {
        case .conversation:
            buttons = [sketchButton, emojiButton, textButton, expandButton]
        case .preview:
            buttons = [sketchButton, emojiButton, textButton]
        }
        
        cas_styleClass = "on-background"
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.init(white: 0, alpha: 0.40).cgColor]
        gradientLayer.isHidden = true
        layer.addSublayer(gradientLayer)
        
        addSubview(buttonContainer)
        buttons.forEach(buttonContainer.addSubview)
        
        createConstrains()
        configureButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.frame = bounds
    }
    
    func createConstrains() {
        constrain(self, buttonContainer) { container, buttonContainer in
            buttonContainer.centerX == container.centerX
            buttonContainer.top == container.top
            buttonContainer.bottom == container.bottom
        }
        
        if let firstButton = buttons.first {
            constrain(buttonContainer, firstButton) { container, firstButton in
                firstButton.left == container.left
            }
        }
        
        if let lastButton = buttons.last {
            constrain(buttonContainer, lastButton) { container, lastButton in
                lastButton.right == container.right
            }
        }
        
        for button in buttons {
            constrain(buttonContainer, button) { container, button in
                button.width == 48
                button.height == 48
                button.centerY == container.centerY
            }
        }
        
        for i in 1..<buttons.count {
            let previousButton = buttons[i-1]
            let button = buttons[i]
            
            constrain(self, button, previousButton) { container, button, previousButton in
                button.left == previousButton.right
            }
        }
    }
    
    func configureButtons() {
        let hitAreaPadding = CGSize(width: 0, height: 0)
        
        sketchButton.setIcon(.brush, with: .tiny, for: .normal)
        sketchButton.hitAreaPadding = hitAreaPadding
        
        emojiButton.setIcon(.emoji, with: .tiny, for: .normal)
        emojiButton.hitAreaPadding = hitAreaPadding
        
        textButton.setIcon(.pencil, with: .tiny, for: .normal)
        textButton.hitAreaPadding = hitAreaPadding
        
        expandButton.setIcon(.fullScreen, with: .tiny, for: .normal)
        expandButton.hitAreaPadding = hitAreaPadding
    }
}
