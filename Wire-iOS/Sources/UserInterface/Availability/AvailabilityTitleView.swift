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


import UIKit
import Cartography
import Classy
import WireExtensionComponents
import WireDataModel

@objc public class AvailabilityTitleView: AbstractTitleView {
    
    private var availability: Availability
    private var user: ZMUser
    private var variant: ColorSchemeVariant
    private var style: AvailabilityStyle
    //private var container: UIViewController
    
    public init(user: ZMUser, availability: Availability, variant: ColorSchemeVariant, style: AvailabilityStyle, interactive: Bool = true) {
        self.user = user
        self.availability = availability
        self.variant = variant
        self.style = style
        //self.container = container
        super.init(interactive: interactive)
        
        tapHandler = { button in
            
            let alert = UIAlertController(title: "availability.message.title", message: nil, preferredStyle: .actionSheet)
            
            for type in Availability.allValues {
                alert.addAction(UIAlertAction(title: type.name, style: .default, handler: { [weak self] (action) in
                    self?.didSelectAvailability(type)
                }))
            }
            
            alert.addAction(UIAlertAction(title: "availability.message.cancel", style: .cancel, handler: nil))
            
            if let root = UIApplication.shared.keyWindow?.rootViewController {
                root.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func didSelectAvailability(_ availability: Availability) {
        print("Selected availability: \(availability)")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func generateAttributedTitle(interactive: Bool, color: UIColor) -> (text: NSAttributedString, hasAttachments: Bool) {
        let title = UILabel.composeString(availability: availability, color: color, style: style, interactive: interactive, title: user.name)
        return (text: title.text && color, hasAttachments: title.hasAttachments)
    }

    override func updateAccessibilityLabel() {
        self.accessibilityLabel = "\(user.displayName) is \(availability.name)".localized
    }
    
    override func colorsStrategy() {
        self.titleColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground, variant: variant)
        self.titleColorSelected = ColorScheme.default().color(withName: ColorSchemeColorTextDimmed, variant: variant)
        
        if style == .headers {
            self.titleFont = FontSpec(.medium, .semibold).font
        } else {
            self.titleFont = FontSpec(.small, .semibold).font
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
