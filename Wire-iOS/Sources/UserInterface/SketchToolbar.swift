//
//  SketchToolbar.swift
//  Wire-iOS
//
//  Created by Jacob on 21/10/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit
import Cartography

class SketchToolbar : UIView {
    
    private let buttonSpacing : CGFloat = 10.0
    
    let leftButton : UIButton!
    let rightButton : UIButton!
    let centerButtons : [UIButton]
    let centerButtonContainer = UIView()
    let separatorLine = UIView()
    
    public init(buttons: [UIButton]) {
        
        guard buttons.count >= 2 else {  fatalError("SketchToolbar needs to be initialized with at least two buttons") }
        
        var unassignedButtons = buttons
        
        leftButton = unassignedButtons.removeFirst()
        rightButton = unassignedButtons.removeLast()
        centerButtons = unassignedButtons
        separatorLine.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorSeparator)
        
        super.init(frame: CGRect.zero)
        
        setupSubviews()
        createButtonContraints(buttons: buttons)
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSubviews() {
        backgroundColor = .white
        centerButtons.forEach(centerButtonContainer.addSubview)
        [leftButton, centerButtonContainer, rightButton, separatorLine].forEach(addSubview)
    }
    
    func createButtonContraints(buttons: [UIButton]) {
        for button in buttons {
            constrain(button) { button in
                button.width == 28
                button.height == 28
            }
        }
    }
    
    func createConstraints() {
        constrain(self, leftButton, rightButton, centerButtonContainer, separatorLine) { container, leftButton, rightButton, centerButtonContainer, separatorLine in
            container.height == 48
            
            leftButton.left == container.left + buttonSpacing
            leftButton.centerY == container.centerY
            
            rightButton.right == container.right - buttonSpacing
            rightButton.centerY == container.centerY
            
            centerButtonContainer.centerX == container.centerX
            centerButtonContainer.top == container.top
            centerButtonContainer.bottom == container.bottom
            
            separatorLine.top == container.top
            separatorLine.left == container.left
            separatorLine.right == container.right
            separatorLine.height == 0.5
        }
        
        createCenterButtonConstraints()
    }
    
    func createCenterButtonConstraints() {
        guard !centerButtons.isEmpty else { return }
        
        let leftButton = centerButtons.first!
        let rightButton = centerButtons.last!
        
        constrain(centerButtonContainer, leftButton, rightButton) { container, leftButton, rightButton in
            leftButton.left == container.left + buttonSpacing
            leftButton.centerY == container.centerY
            
            rightButton.right == container.right - buttonSpacing
            rightButton.centerY == container.centerY
        }
        
        for i in 1..<centerButtons.count {
            let previousButton = centerButtons[i-1]
            let button = centerButtons[i]
            
            constrain(centerButtonContainer, button, previousButton) { container, button, previousButton in
                button.left == previousButton.right + buttonSpacing
                button.centerY == container.centerY
            }
        }
    }
    
}
