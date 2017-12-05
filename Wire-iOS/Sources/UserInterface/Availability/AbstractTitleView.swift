//
//  AbstractTitleView.swift
//  Wire-iOS
//
//  Created by Nicola Giancecchi on 04.12.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit
import Cartography
import Classy

protocol AbstractTitleViewTemplate {
    func updateAccessibilityLabel()
    func generateAttributedTitle(interactive: Bool, color: UIColor) -> (text: NSAttributedString, hasAttachments: Bool)
    func tappableCondition(interactive: Bool) -> Bool
    func colorsStrategy()
}

@objc public class AbstractTitleView: UIView, AbstractTitleViewTemplate {
    
    var titleColor, titleColorSelected: UIColor?
    var titleFont: UIFont?
    let titleButton = UIButton()
    public var tapHandler: ((UIButton) -> Void)? = nil
    
    init(interactive: Bool) {
        super.init(frame: CGRect.zero)
        self.isAccessibilityElement = true
        self.accessibilityIdentifier = "Name"
        self.updateAccessibilityLabel()
        
        createViews()
        colorsStrategy()
        
        let hasAttachment = configure(interactive: interactive)
        frame = titleButton.bounds
        createConstraints(hasAttachment)
    }
    
    private func createConstraints(_ hasAttachment: Bool) {
        constrain(self, titleButton) { view, button in
            button.leading == view.leading
            button.trailing == view.trailing
            button.top == view.top
            button.bottom == view.bottom - (hasAttachment ? 4 : 0)
        }
    }
    
    private func createViews() {
        titleButton.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
        addSubview(titleButton)
    }
    
    func titleButtonTapped(_ sender: UIButton) {
        tapHandler?(sender)
    }
    
    /// Configures the title view for the given conversation
    /// - parameter conversation: The conversation for which the view should be configured
    /// - parameter interactive: Whether the view should react to user interaction events
    /// - return: Whether the view contains any `NSTextAttachments`
    private func configure(interactive: Bool) -> Bool {
    
        guard let font = titleFont, let color = titleColor, let selectedColor = titleColorSelected else { return false }
        let tappable = tappableCondition(interactive: interactive)
        let normalLabel = generateAttributedTitle(interactive: tappable, color: color)
        let selectedLabel = generateAttributedTitle(interactive: tappable, color: selectedColor)
        
        titleButton.titleLabel!.font = font
        titleButton.setAttributedTitle(normalLabel.text, for: UIControlState())
        titleButton.setAttributedTitle(selectedLabel.text, for: .highlighted)
        titleButton.sizeToFit()
        titleButton.isEnabled = tappable
        updateAccessibilityLabel()
        setNeedsLayout()
        layoutIfNeeded()
        
        return normalLabel.hasAttachments
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateAccessibilityLabel() {
    }
    
    func colorsStrategy() {
        fatalError("This method should be implemented by its subclasses")
    }
    
    func tappableCondition(interactive: Bool) -> Bool {
        return interactive
    }
    
    func generateAttributedTitle(interactive: Bool, color: UIColor) -> (text: NSAttributedString, hasAttachments: Bool) {
        fatalError("This method should be implemented by its subclasses")
    }
}

extension NSTextAttachment {
    static func downArrow(color: UIColor) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(for: .downArrow, fontSize: 8, color: color)
        return attachment
    }
}
