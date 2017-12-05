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
import WireExtensionComponents

//Temporary enum replacement, waiting for the official implementation
@objc public enum Availability: Int {
    case none, available, away, busy
    static let allValues = [none, available, away, busy]
}

@objc public class AvailabilityTitleView: AbstractTitleView {
    
    private var availability: Availability
    private var user: ZMUser
    private var variant: ColorSchemeVariant
    //private var container: UIViewController
    
    public init(user: ZMUser, availability: Availability, variant: ColorSchemeVariant, interactive: Bool = true) {
        self.user = user
        self.availability = availability
        self.variant = variant
        //self.container = container
        super.init(interactive: interactive)
        
        tapHandler = { button in
            
            let alert = UIAlertController(title: "availability.message.title", message: nil, preferredStyle: .actionSheet)
            
            for type in Availability.allValues {
                alert.addAction(UIAlertAction(title: type.name, style: .default, handler: { [weak self] (action) in
                    self?.didSelectAvailability(type)
                }))
            }
            
            alert.addAction(UIAlertAction(title: "availability.message.cancel", style: .destructive, handler: nil))
            //container.present(alert, animated: true, completion: nil)
        }
    }
    
    func didSelectAvailability(_ availability: Availability) {
        print("Selected availability: \(availability)")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func generateAttributedTitle(interactive: Bool, color: UIColor) -> (text: NSAttributedString, hasAttachments: Bool) {
        
        var title = availability.name.uppercased().attributedString
        var hasAttachment = false
        
        if interactive {
            
            let arrow = NSAttributedString(attachment: .downArrow(color: color))
            
            if availability == .none {
                title = "availability.message.set_status".localized + "  " + arrow
            } else {
                title += "  " + arrow
            }
            
            hasAttachment = true
        }

        if availability != .none {
            title = NSAttributedString(attachment: .availabilityIcon(availability, color: color)) + "  " + title
            hasAttachment = true
        }

        return (text: title && color, hasAttachments: hasAttachment)
    }

    override func updateAccessibilityLabel() {
        self.accessibilityLabel = "\(user.displayName) is \(availability.name)".localized
    }
    
    override func colorsStrategy() {
        self.titleColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground, variant: variant)
        self.titleColorSelected = ColorScheme.default().color(withName: ColorSchemeColorTextDimmed, variant: variant)
        self.titleFont = UIFont(magicIdentifier: "style.text.small.font_spec_bold")
    }
    
}

extension Availability {
    var name: String {
        switch self {
            case .none:         return ""
            case .available:    return "availability.available".localized
            case .away:         return "availability.away".localized
            case .busy:         return "availability.busy".localized
        }
    }
    
    var imageEnum: ZetaIconType? {
        switch self {
            case .none:         return nil
            case .available:    return .availabilityAvailable
            case .away:         return .availabilityAway
            case .busy:         return .availabilityBusy
        }
    }
}

extension NSTextAttachment {
    static func availabilityIcon(_ availability: Availability, color: UIColor) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        if let imageEnum = availability.imageEnum, let image = UIImage(for: imageEnum, fontSize: 10, color: color) {
            attachment.image = image
            let ratio = image.size.width / image.size.height
            let height: CGFloat = 10
            attachment.bounds = CGRect(x: 0, y: 0, width: height * ratio, height: height)
        }
        return attachment
    }
}
