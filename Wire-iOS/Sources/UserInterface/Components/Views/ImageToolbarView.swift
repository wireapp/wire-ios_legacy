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
    case cell
    case compactCell
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
    
    var configuration : ImageToolbarConfiguration {
        didSet {
            guard oldValue != configuration else { return }
            
            updateButtonConfiguration()
        }
    }
    
    var isPlacedOnImage : Bool = false {
        didSet {
            gradientLayer.isHidden = !isPlacedOnImage
            cas_styleClass = isPlacedOnImage ? "on-image" : "on-background"
            buttons.forEach(CASStyler.default().styleItem)
        }
    }
    
    @objc public init(withConfiguraton configuration: ImageToolbarConfiguration) {
        self.configuration = configuration
        
        super.init(frame: CGRect.zero)
        
        cas_styleClass = "on-background"
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.init(white: 0, alpha: 0.40).cgColor]
        gradientLayer.isHidden = true
        layer.addSublayer(gradientLayer)
        
        addSubview(buttonContainer)
        
        constrain(self, buttonContainer) { container, buttonContainer in
            buttonContainer.centerX == container.centerX
            buttonContainer.top == container.top
            buttonContainer.bottom == container.bottom
            buttonContainer.left >= container.left
            buttonContainer.right <= container.right
        }
        
        setupButtons()
        updateButtonConfiguration()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.frame = bounds
    }
    
    func updateButtonConfiguration() {
        buttons.forEach({ $0.removeFromSuperview() })
        
        switch configuration {
        case .cell:
            buttons = [sketchButton, emojiButton, expandButton]
        case .compactCell:
            buttons = [sketchButton, expandButton]
        case .preview:
            buttons = [sketchButton, emojiButton]
        }
        
        buttons.forEach(buttonContainer.addSubview)
        
        createButtonConstraints()
    }
    
    func createButtonConstraints() {
        let spacing : CGFloat = 16
        
        if let firstButton = buttons.first {
            constrain(buttonContainer, firstButton) { container, firstButton in
                firstButton.left == container.left + spacing
            }
        }
        
        if let lastButton = buttons.last {
            constrain(buttonContainer, lastButton) { container, lastButton in
                lastButton.right == container.right - spacing
            }
        }
        
        for button in buttons {
            constrain(buttonContainer, button) { container, button in
                button.width == 16
                button.height == 16
                button.centerY == container.centerY
            }
        }
        
        for i in 1..<buttons.count {
            let previousButton = buttons[i-1]
            let button = buttons[i]
            
            constrain(self, button, previousButton) { container, button, previousButton in
                button.left == previousButton.right + spacing * 2
            }
        }
    }
    
    func setupButtons() {
        let hitAreaPadding = CGSize(width: 16, height: 16)
        
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
