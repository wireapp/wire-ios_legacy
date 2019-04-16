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

/**
 * A title view subclass that displays the availability of the user.
 */

class AvailabilityTitleView: TitleView, Themeable, ZMUserObserver {
    
    /// The available options for this view.
    struct Options: OptionSet {
        let rawValue: Int
        
        /// Whether we allow the user to update the status by tapping this view.
        static let allowSettingStatus = Options(rawValue: 1 << 0)
        
        /// Whether to hide the action hint (down arrow) next to the status.
        static let hideActionHint = Options(rawValue: 1 << 1)
        
        /// Whether to display the user name instead of the availability.
        static let displayUserName = Options(rawValue: 1 << 2)
        
        /// Whether to use a large text font instead of the default small one.
        static let useLargeFont = Options(rawValue: 1 << 3)
        
        /// The default options for using the view inside the header of the home page.
        static var header: Options = [.allowSettingStatus, .hideActionHint, .displayUserName, .useLargeFont]
        
        /// The default option for using the view inside the profile screen of the settings.
        static var selfProfile: Options = [.allowSettingStatus]
        
        /// The default option for using the view inside the profile details screen of a conversation.
        static var profileDetails: Options = [.hideActionHint]
        
    }
    
    // MARK: - Properties
    
    private let user: GenericUser
    private var observerToken: Any?
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard colorSchemeVariant != oldValue else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }
    
    /// The options to apply to this view.
    var options: Options {
        didSet {
            updateConfiguration()
        }
    }
    
    // MARK: - Initialization
    
    @objc(profileDetailsAvailabilityTitleViewForUser:)
    static func makeProfileDetailsAvailabilityTitleView(for user: ZMUser) -> AvailabilityTitleView {
        return AvailabilityTitleView(user: user, options: .profileDetails)
    }
    
    /**
     * Creates a view for the specific user and options.
     * - parameter user: The user to display the availability of.
     * - parameter options: The options to display the availability.
     * - note: You can change the options later, through the `options` property.
     */
    
    init(user: GenericUser, options: Options) {
        self.options = options
        self.user = user
        super.init()
        
        if let sharedSession = ZMUserSession.shared() {
            self.observerToken = UserChangeInfo.add(observer: self, for: user, userSession: sharedSession)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        
        updateConfiguration()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    
    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        updateConfiguration()
    }
    
    /// Refreshes the content and appearance of the view.
    private func updateConfiguration() {
        updateAppearance()
        updateContent()
    }
    
    /// Refreshes the content of the view, based on the user data and the options.
    private func updateContent() {
        let availability = user.availability
        let fontStyle: FontSize = options.contains(.useLargeFont) ? .normal : .small
        let icon = AvailabilityStringBuilder.icon(for: availability, with: self.titleColor!, and: fontStyle)
        let isInteractive = options.contains(.allowSettingStatus)
        var title = ""
        
        if options.contains(.displayUserName) {
            title = user.name ?? ""
            accessibilityLabel = title
            accessibilityValue = title
        } else if availability == .none && options.contains(.allowSettingStatus) {
            title = "availability.message.set_status".localized(uppercased: true)
        } else if availability != .none {
            title = availability.localizedName.localizedUppercase
        }
        
        let showInteractiveIcon = isInteractive && !options.contains(.hideActionHint)
        super.configure(icon: icon, title: title, interactive: isInteractive, showInteractiveIcon: showInteractiveIcon)
    }
    
    /// Refreshes the appearance of the view, based on the options.
    private func updateAppearance() {
        if options.contains(.useLargeFont) {
            titleFont = FontSpec(.normal, .semibold).font
        } else {
            titleFont = FontSpec(.small, .semibold).font
        }
        
        titleColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        titleColorSelected = UIColor.from(scheme: .textDimmed, variant: colorSchemeVariant)
    }
    
    // MARK: - Events
    
    @objc private func applicationDidBecomeActive() {
        updateConfiguration()
    }
    
    override func updateAccessibilityLabel() {
        self.accessibilityLabel = "\(user.name ?? "")_is_\(user.availability.localizedName)".localized
    }
    
    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.availabilityChanged || changeInfo.nameChanged else { return }
        updateConfiguration()
    }
    
    // MARK: - Actions
    
    func actionSheet(presentingViewController: UIViewController) -> UIAlertController {
        let alert = UIAlertController(title: "availability.message.set_status".localized, message: nil, preferredStyle: .actionSheet)
        
        for availability in Availability.allValues {
            alert.addAction(UIAlertAction(title: availability.localizedName, style: .default, handler: { [weak self] (action) in
                self?.didSelectAvailability(availability)
                
                if Settings.shared()?.shouldRemindUserWhenChanging(availability) == true {
                    presentingViewController.present(UIAlertController.availabilityExplanation(availability), animated: true)
                }
            }))
        }
        
        alert.popoverPresentationController?.permittedArrowDirections = [ .up ]
        alert.addAction(UIAlertAction(title: "availability.message.cancel".localized, style: .cancel, handler: nil))
        
        return alert
    }
    
    private func didSelectAvailability(_ availability: Availability) {
        let changes = { [weak self] in
            self?.user.availability = availability
            self?.provideHapticFeedback()
        }
        
        if let session = ZMUserSession.shared() {
            session.performChanges(changes)
        } else {
            changes()
        }
    }
    
    private func provideHapticFeedback() {
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    
}

extension UserType {
    
    /// Returns if the user's availability can be displayed.
    func canDisplayAvailability(with options: AvailabilityTitleView.Options) -> Bool {
        return availability != .none
            || options.contains(.displayUserName)
            || availability == .none && options.contains(.allowSettingStatus)
    }
    
}
