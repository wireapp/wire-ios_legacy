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

enum Availability {
    case none, available, away, busy
}

class AvailabilityTitleView: AbstractTitleView {
    
    private var availability: Availability
    private var user: ZMUser
    
    init(user: ZMUser, availability: Availability, interactive: Bool = true) {
        self.user = user
        self.availability = availability
        super.init(interactive: interactive)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func generateAttributedTitle(interactive: Bool, color: UIColor) -> (text: NSAttributedString, hasAttachments: Bool) {
        
        var title = user.displayName.uppercased().attributedString
        var hasAttachment = false
            
        if interactive {
            title += "  " + NSAttributedString(attachment: .downArrow(color: color))
            hasAttachment = true
        }

        if availability != .none {
            title = NSAttributedString(attachment: .availabilityIcon(availability)) + "  " + title
            hasAttachment = true
        }
            
        return (text: title, hasAttachments: hasAttachment)
    }

    override func updateAccessibilityLabel() {
        self.accessibilityLabel = "\(user.displayName) is \(availability.name)".localized
    }
    
}

extension Availability {
    var name: String {
        switch self {
            case .none, .available: return "availability.available".localized
            case .away: return "availability.away".localized
            case .busy: return "availability.busy".localized
        }
    }
    
    var imageEnum: ZetaIconType? {
        switch self {
            case .none, .available: return nil
            case .away: return .contactsCircle
            case .busy: return .delete
        }
    }
}

extension NSTextAttachment {
    static func availabilityIcon(_ availability: Availability) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        if let imageEnum = availability.imageEnum {
             /// TODO check colors
            attachment.image = UIImage(for: imageEnum, fontSize: 12, color: .black)
        }
        return attachment
    }
}
