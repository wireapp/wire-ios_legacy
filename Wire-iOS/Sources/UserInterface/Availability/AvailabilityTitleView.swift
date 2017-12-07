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

@objc public class AvailabilityTitleView: TitleView {
    
    private var user: ZMUser
    private var style: AvailabilityTitleViewStyle
    
    public init(user: ZMUser, style: AvailabilityTitleViewStyle) {
        self.user = user
        self.style = style
        
        var titleColor: UIColor?
        var titleColorSelected: UIColor?
        
        if style == .selfProfile || style == .header {
            let variant = ColorSchemeVariant.dark
            titleColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground, variant: variant)
            titleColorSelected = ColorScheme.default().color(withName: ColorSchemeColorTextDimmed, variant: variant)
        } else {
            //otherwise, take the default variant
            titleColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground)
            titleColorSelected = ColorScheme.default().color(withName: ColorSchemeColorTextDimmed)
        }
        
        var titleFont : UIFont?
        if style == .header {
            titleFont = FontSpec(.medium, .semibold).font
        } else {
            titleFont = FontSpec(.small, .semibold).font
        }
        
        super.init(color: titleColor!, selectedColor: titleColorSelected!, font: titleFont!)
        
        configure()
        
        /// TODO change!
        tapHandler = { button in
            
            let alert = UIAlertController(title: "availability.message.title", message: nil, preferredStyle: .actionSheet)
            
            for type in Availability.allValues {
                alert.addAction(UIAlertAction(title: type.localizedName, style: .default, handler: { [weak self] (action) in
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
    
    func configure() {
        let icon = self.availabilityIcon(self.user.availability, color: self.titleColor!)
        let interactive = (style == .selfProfile || style == .header)
        var title = ""
        
        if self.style == .header {
            title = self.user.name.uppercased()
        } else if self.user == ZMUser.selfUser() && self.user.availability == .none {
            title = "availability.message.set_status".localized
        } else {
            title = self.user.availability.localizedName.uppercased()
        }
        
        _ = super.configure(icon: icon, title: title, interactive: interactive)
    }
    
    override func updateAccessibilityLabel() {
        self.accessibilityLabel = "\(user.name)_is_\(user.availability.localizedName)".localized
    }
    
}

extension AvailabilityTitleView {
    func availabilityIcon(_ availability: Availability, color: UIColor) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        if let iconType = availability.iconType, let image = UIImage(for: iconType, fontSize: 10, color: color) {
            attachment.image = image
            let ratio = image.size.width / image.size.height
            let height: CGFloat = 10
            attachment.bounds = CGRect(x: 0, y: 0, width: height * ratio, height: height)
        }
        return attachment
    }
}
