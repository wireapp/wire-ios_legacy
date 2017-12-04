//
//  AvailabilityTitleView.swift
//  Wire-iOS
//
//  Created by Nicola Giancecchi on 04.12.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit
import Cartography
import Classy

public final class AvailabilityTitleView: UIView {
    
    var titleColor, titleColorSelected: UIColor?
    var titleFont: UIFont?
    let titleButton = UIButton()
    public var tapHandler: ((UIButton) -> Void)? = nil
    
    init(availability: Availability, interactive: Bool = true) {
        super.init(frame: CGRect.zero)
        self.isAccessibilityElement = true
        //self.accessibilityLabel = conversation.displayName
        self.accessibilityIdentifier = "Availability"
        createViews()
        CASStyler.default().styleItem(self)
        
        // The attachments contain images which break the centering of the text inside the button.
        // If there is an attachment in the text we need to adjust the constraints accordingly.
        let hasAttachment = configure(availability, interactive: interactive)
        frame = titleButton.bounds
        createConstraints(hasAttachment)
    }
    
    private func createViews() {
        titleButton.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
        addSubview(titleButton)
    }
    
    /// Configures the title view for the given conversation
    /// - parameter conversation: The conversation for which the view should be configured
    /// - parameter interactive: Whether the view should react to user interaction events
    /// - return: Whether the view contains any `NSTextAttachments`
    private func configure(_ availability: Availability, interactive: Bool) -> Bool {
        guard let font = titleFont, let color = titleColor, let selectedColor = titleColorSelected else { return false }
        let title = availability.name.uppercased() && font
        var hasAttachment = false
        
        let titleWithColor: (UIColor) -> NSAttributedString = {
            
            var attributed = title
            
            if interactive {
                attributed += "  " + NSAttributedString(attachment: .downArrow(color: $0))
                hasAttachment = true
            }
            
            if availability != .none {
                attributed = NSAttributedString(attachment: .availabilityIcon(availability)) + "  " + attributed
                hasAttachment = true
            }
            
            return attributed && $0
        }
        
        titleButton.titleLabel!.font = font
        titleButton.setAttributedTitle(titleWithColor(color), for: UIControlState())
        titleButton.setAttributedTitle(titleWithColor(selectedColor), for: .highlighted)
        titleButton.sizeToFit()
        titleButton.isEnabled = interactive
        updateAccessibilityValue(availability)
        setNeedsLayout()
        layoutIfNeeded()
        
        return hasAttachment
    }
    
    private func updateAccessibilityValue(_ availability: Availability) {
        /// TODO
        self.accessibilityLabel = availability.name.uppercased()
        // Other labels should be added + check on "None" case.
    }
    
    private func createConstraints(_ hasAttachment: Bool) {
        constrain(self, titleButton) { view, button in
            button.leading == view.leading
            button.trailing == view.trailing
            button.top == view.top
            button.bottom == view.bottom - (hasAttachment ? 4 : 0)
        }
    }
    
    func titleButtonTapped(_ sender: UIButton) {
        tapHandler?(sender)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

fileprivate extension NSTextAttachment {
    
    static func downArrow(color: UIColor) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(for: .downArrow, fontSize: 8, color: color)
        return attachment
    }
    
    static func availabilityIcon(_ availability: Availability) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        
        switch availability {
        default: do {
            /// TODO Check Color
            attachment.image = UIImage(for: .delete, fontSize: 12, color: .black)
            }
        }
        
        return attachment
    }
    
    static func verifiedShield() -> NSTextAttachment {
        let attachment = NSTextAttachment()
        let shield = WireStyleKit.imageOfShieldverified()!
        attachment.image = shield
        let ratio = shield.size.width / shield.size.height
        let height: CGFloat = 12
        attachment.bounds = CGRect(x: 0, y: -2, width: height * ratio, height: height)
        return attachment
    }
}

extension Availability {
    
    var name: String {
        switch self {
            case .none: return "availability.none".localized
        /// TODO: Change to ".available"
            case .vacation: return "availability.available".localized
        /// TODO: Change to ".away"
            case .sick: return "availability.away".localized
        /// TODO: Change to ".busy"
            case .workFromHome: return "availability.busy".localized
        }
    }
    
}
