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
import WireDataModel
import WireSyncEngine
import WireCommonComponents

/**
 * A title view subclass that displays the availability of the user.
 */

final class AvailabilityTitleView: TitleView, Themeable, ZMUserObserver {

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

        /// The default options for using the view in a title bar.
        static var header: Options = [.allowSettingStatus, .hideActionHint, .displayUserName, .useLargeFont]

    }

    // MARK: - Properties

    private let user: UserType
    private var observerToken: Any?
    private var options: Options

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard colorSchemeVariant != oldValue else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }

    // MARK: - Initialization

    /**
     * Creates a view for the specific user and options.
     * - parameter user: The user to display the availability of.
     * - parameter options: The options to display the availability.
     */

    init(user: UserType, options: Options) {
        self.options = options
        self.user = user

        super.init()

        if let sharedSession = ZMUserSession.shared() {
            self.observerToken = UserChangeInfo.add(observer: self, for: user, in: sharedSession)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)

        updateConfiguration()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        updateConfiguration()
    }

    /// Refreshes the content and appearance of the view.
    func updateConfiguration() {
        updateAppearance()
        updateContent()
    }

    /// Refreshes the content of the view, based on the user data and the options.
    private func updateContent() {
        typealias AvailabilityStatusStrings = L10n.Accessibility.AccountPage.AvailabilityStatus

        let availability = user.availability
        let fontStyle: FontSize = options.contains(.useLargeFont) ? .normal : .small
        let icon = AvailabilityStringBuilder.icon(
            for: availability,
            with: AvailabilityStringBuilder.color(for: availability),
            and: fontStyle)
        let isInteractive = options.contains(.allowSettingStatus)
        var title = ""

        if options.contains(.displayUserName) {
            title = user.name ?? ""
            accessibilityLabel = title
        } else if availability == .none && options.contains(.allowSettingStatus) {
            title = L10n.Localizable.Availability.Message.setStatus
            accessibilityLabel = title
        } else if availability != .none {
            title = availability.localizedName.localized
            accessibilityLabel = AvailabilityStatusStrings.description
        }

        let showInteractiveIcon = isInteractive && !options.contains(.hideActionHint)
        super.configure(icon: icon, title: title, interactive: isInteractive, showInteractiveIcon: showInteractiveIcon)

        accessibilityValue = availability != .none ? availability.localizedName : ""
        if options.contains(.allowSettingStatus) {
            accessibilityTraits = .button
            accessibilityHint = AvailabilityStatusStrings.hint
        }
    }

    /// Refreshes the appearance of the view, based on the options.
    private func updateAppearance() {
        if options.contains(.useLargeFont) {
            titleFont = .headerSemiboldFont
        } else {
            titleFont = .smallRegularFont
        }

        titleColor = SemanticColors.Label.textDefault
    }

    // MARK: - Events

    @objc private func applicationDidBecomeActive() {
        updateConfiguration()
    }

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.availabilityChanged || changeInfo.nameChanged else { return }
        updateConfiguration()
    }

}
