//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


@objc public enum AvailabilityTitleViewStyle: Int {
    case selfProfile, otherProfile, header
}

@objc public enum AvailabilityLabelStyle: Int {
    case list, placeholder
}

extension Availability {
    var localizedName: String {
        switch self {
        case .none:         return "availability.none".localized
        case .available:    return "availability.available".localized
        case .away:         return "availability.away".localized
        case .busy:         return "availability.busy".localized
        }
    }
    
    var iconType: ZetaIconType? {
        switch self {
        case .none:         return nil
        case .available:    return .availabilityAvailable
        case .away:         return .availabilityAway
        case .busy:         return .availabilityBusy
        }
    }
    
}

extension UILabel {
    
    
    @objc static func composeStringText(availability: Availability, color: UIColor, style: AvailabilityLabelStyle, interactive: Bool, title: String) -> NSAttributedString {
        return "".attributedString // composeString(availability: availability, color: color, style: style, interactive: interactive, title: title).text
    }
    
    static func composeString(availability: Availability, color: UIColor, style: AvailabilityLabelStyle, interactive: Bool, title: String) -> (text: NSAttributedString, hasAttachments: Bool){
        
        return (text: "".attributedString, hasAttachments: false)
        
        /*
        var formattedTitle = ""
        var hasAttachment = false
        
        switch style {
        case .profiles:             formattedTitle = availability.name.uppercased()
        case .headers:              formattedTitle = title.uppercased()
        case .lists:                formattedTitle = title
        case .placeholder:          formattedTitle = "\(title)_is_\(availability.name)".localized.uppercased()
        }
        
        var attributedTitle = formattedTitle.attributedString
        
        if interactive {
            
            let arrow = NSAttributedString(attachment: .downArrow(color: color))
            
            if availability == .none {
                attributedTitle = "availability.message.set_status".localized + "  " + arrow
            } else {
                attributedTitle += "  " + arrow
            }
            
            hasAttachment = true
        }
        
        if availability != .none {
            attributedTitle = NSAttributedString(attachment: .availabilityIcon(availability, color: color)) + "  " + attributedTitle
            hasAttachment = true
        }
        
        return (text: attributedTitle && color, hasAttachments: hasAttachment)
 */
    }
}
