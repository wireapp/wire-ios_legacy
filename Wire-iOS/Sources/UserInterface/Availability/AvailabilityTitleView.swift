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
    
    internal var user: ZMUser
    internal var style: AvailabilityTitleViewStyle
    internal var observerToken: Any?
    
    public init(user: ZMUser, style: AvailabilityTitleViewStyle) {
        self.user = user
        self.style = style
        
        var titleColor: UIColor
        var titleColorSelected: UIColor
        
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
            titleFont = FontSpec(.normal, .semibold).font
        } else {
            titleFont = FontSpec(.small, .semibold).font
        }
        
        super.init(color: titleColor, selectedColor: titleColorSelected, font: titleFont)
        
        if let sharedSession = ZMUserSession.shared() {
            self.observerToken = UserChangeInfo.add(observer: self, for: user, userSession: sharedSession)
        }
        
        configure()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        let availability = self.user.availability
        let fontStyle: FontSize = (style == .header) ? .normal : .small
        let icon = AvailabilityStringBuilder.icon(for: availability, with: self.titleColor!, and: fontStyle)
        let interactive = (style == .selfProfile || style == .header)
        var title = ""
        
        if self.style == .header {
            title = self.user.name
        } else if self.user == ZMUser.selfUser() && availability == .none {
            title = "availability.message.set_status".localized.uppercased()
        } else if availability != .none {
            title = availability.localizedName.uppercased()
        }
        
        super.configure(icon: icon, title: title, interactive: interactive, showInteractiveIcon: style == .selfProfile)
    }
    
    override func updateAccessibilityLabel() {
        self.accessibilityLabel = "\(user.name)_is_\(user.availability.localizedName)".localized
    }
    
    func provideHapticFeedback() {
        guard #available(iOS 10, *) else {
            return
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

extension AvailabilityTitleView: ZMUserObserver {
    
    public func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.availabilityChanged else { return }
        
        provideHapticFeedback()
        configure()
    }
}

extension AvailabilityTitleView {
    
    var actionSheet: UIAlertController {
        get {
            let alert = UIAlertController(title: "availability.message.set_status".localized, message: nil, preferredStyle: .actionSheet)
            for type in Availability.allValues {
                alert.addAction(UIAlertAction(title: type.localizedName, style: .default, handler: { [weak self] (action) in
                    self?.didSelectAvailability(type)
                }))
            }
            alert.popoverPresentationController?.permittedArrowDirections = [ .up ]
            alert.addAction(UIAlertAction(title: "availability.message.cancel".localized, style: .cancel, handler: nil))
            return alert
        }
    }
    
    private func didSelectAvailability(_ availability: Availability) {
        ZMUserSession.shared()?.performChanges { [weak self] in
            ZMUser.selfUser().availability = availability
            self?.trackChanges(with: availability)
        }
    }
    
    private func trackChanges(with availability: Availability) {
        switch style {
            case .header:       do { Analytics.shared().tagAvailabilityChanged(to: availability, source: .listHeader)   }
            case .selfProfile:  do { Analytics.shared().tagAvailabilityChanged(to: availability, source: .settings)     }
            default: break
        }
    }
    
}
