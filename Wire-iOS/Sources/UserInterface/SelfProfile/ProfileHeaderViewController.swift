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
import WireSyncEngine
import WireCommonComponents

final class ProfileHeaderViewController: UIViewController, Themeable {

    /**
     * The options to customize the appearance and behavior of the view.
     */

    struct Options: OptionSet {

        let rawValue: Int

        /// Whether to hide the username of the user.
        static let hideUsername = Options(rawValue: 1 << 0)

        /// Whether to hide the handle of the user.
        static let hideHandle = Options(rawValue: 1 << 1)

        /// Whether to hide the availability status of the user.
        static let hideAvailability = Options(rawValue: 1 << 2)

        /// Whether to hide the team name of the user.
        static let hideTeamName = Options(rawValue: 1 << 3)

        /// Whether to allow the user to change their availability.
        static let allowEditingAvailability = Options(rawValue: 1 << 4)

        /// Whether to allow the user to change their availability.
        static let allowEditingProfilePicture = Options(rawValue: 1 << 5)

    }

    /// The options to customize the appearance and behavior of the view.
    var options: Options {
        didSet {
            applyOptions()
        }
    }

    /// Associated conversation, if displayed in the context of a conversation
    let conversation: ZMConversation?

    /// The user that is displayed.
    let user: UserType

    /// The user who is viewing this view
    let viewer: UserType

    /// The current group admin status.
    var isAdminRole: Bool {
        didSet {
            groupRoleIndicator.isHidden = !self.isAdminRole
        }
    }

    dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard colorSchemeVariant != oldValue else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }

    var stackView: CustomSpacingStackView!

    typealias AccountPageStrings = L10n.Accessibility.AccountPage

    let nameLabel: UILabel = {
        let label = DynamicFontLabel(fontSpec: .largeSemiboldFont, color: .textForeground)
        label.accessibilityLabel = AccountPageStrings.Name.description
        label.accessibilityIdentifier = "name"

        label.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)

        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        label.accessibilityTraits.insert(.header)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 3
        label.textAlignment = .center

        return label
    }()
    let handleLabel = DynamicFontLabel(fontSpec: .smallRegularFont, color: .textForeground)
    let teamNameLabel = DynamicFontLabel(fontSpec: .smallRegularFont, color: .textForeground)
    let imageView =  UserImageView(size: .big)
    let availabilityTitleViewController: AvailabilityTitleViewController

    let guestIndicatorStack = UIStackView()
    let guestIndicator = LabelIndicator(context: .guest)
    let remainingTimeLabel = UILabel()
    let groupRoleIndicator = LabelIndicator(context: .groupRole)
    let externalIndicator = LabelIndicator(context: .external)
    let federatedIndicator = LabelIndicator(context: .federated)

    private var tokens: [Any?] = []
    private var teamObserver: NSObjectProtocol?

    /**
     * Creates a profile view for the specified user and options.
     * - parameter user: The user to display the profile of.
     * - parameter options: The options for the appearance and behavior of the view.
     * - note: You can change the options later through the `options` property.
     */

    init(user: UserType, viewer: UserType = SelfUser.current, conversation: ZMConversation? = nil, options: Options) {
        self.user = user
        isAdminRole = conversation.map(self.user.isGroupAdmin) ?? false
        self.viewer = viewer
        self.conversation = conversation
        self.options = options
        self.availabilityTitleViewController = AvailabilityTitleViewController(user: user, options: options.contains(.allowEditingAvailability) ? [.allowSettingStatus] : [.hideActionHint])

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        let session = SessionManager.shared?.activeUserSession

        imageView.isAccessibilityElement = true
        imageView.accessibilityElementsHidden = false
        imageView.accessibilityIdentifier = "user image"
        imageView.setImageConstraint(resistance: 249, hugging: 750)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        imageView.initialsFont = UIFont.systemFont(ofSize: 55, weight: .semibold).monospaced()
        imageView.userSession = session
        imageView.user = user

        if !ProcessInfo.processInfo.isRunningTests,
           let session = session {
            tokens.append(UserChangeInfo.add(observer: self, for: user, in: session))
        }

        handleLabel.accessibilityLabel = AccountPageStrings.Handle.description
        handleLabel.accessibilityIdentifier = "username"
        handleLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        handleLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)

        let nameHandleStack = UIStackView(arrangedSubviews: [nameLabel, handleLabel])
        nameHandleStack.axis = .vertical
        nameHandleStack.alignment = .center
        nameHandleStack.spacing = 2

        teamNameLabel.accessibilityLabel = AccountPageStrings.TeamName.description
        teamNameLabel.accessibilityIdentifier = "team name"
        teamNameLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        teamNameLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)

        nameLabel.text = user.name
        nameLabel.accessibilityValue = nameLabel.text

        let remainingTimeString = user.expirationDisplayString
        remainingTimeLabel.font = UIFont.mediumSemiboldFont
        remainingTimeLabel.text = remainingTimeString
        remainingTimeLabel.isHidden = remainingTimeString == nil

        guestIndicatorStack.addArrangedSubview(guestIndicator)
        guestIndicatorStack.addArrangedSubview(remainingTimeLabel)
        guestIndicatorStack.spacing = 12
        guestIndicatorStack.axis = .vertical
        guestIndicatorStack.alignment = .center

        updateGuestIndicator()
        updateExternalIndicator()
        updateFederatedIndicator()
        updateGroupRoleIndicator()
        updateHandleLabel()
        updateTeamLabel()

        addChild(availabilityTitleViewController)

        stackView = CustomSpacingStackView(customSpacedArrangedSubviews: [nameHandleStack,
                                                                          teamNameLabel,
                                                                          imageView,
                                                                          availabilityTitleViewController.view,
                                                                          guestIndicatorStack,
                                                                          externalIndicator,
                                                                          federatedIndicator,
                                                                          groupRoleIndicator])

        stackView.alignment = .center
        stackView.axis = .vertical

        stackView.wr_addCustomSpacing(32, after: nameHandleStack)
        stackView.wr_addCustomSpacing(32, after: teamNameLabel)
        stackView.wr_addCustomSpacing(24, after: imageView)
        stackView.wr_addCustomSpacing(20, after: guestIndicatorStack)
        stackView.wr_addCustomSpacing(20, after: externalIndicator)
        stackView.wr_addCustomSpacing(20, after: federatedIndicator)

        view.addSubview(stackView)
        applyColorScheme(colorSchemeVariant)
        configureConstraints()
        applyOptions()

        availabilityTitleViewController.didMove(toParent: self)

        if let team = (user as? ZMUser)?.team {
            teamObserver = TeamChangeInfo.add(observer: self, for: team)
        }
        view.backgroundColor = UIColor.clear
    }

    private func configureConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let leadingSpaceConstraint = stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40)
        let topSpaceConstraint = stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20)
        let trailingSpaceConstraint = stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        let bottomSpaceConstraint = stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)

        let widthImageConstraint = imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 164)
        NSLayoutConstraint.activate([
            // stackView
            widthImageConstraint, leadingSpaceConstraint, topSpaceConstraint, trailingSpaceConstraint, bottomSpaceConstraint
            ])
    }

    func applyColorScheme(_ variant: ColorSchemeVariant) {
        availabilityTitleViewController.availabilityTitleView?.colorSchemeVariant = variant

        let labelColor = SemanticColors.Label.textDefault
        [handleLabel, nameLabel, teamNameLabel, remainingTimeLabel].forEach { $0.textColor = labelColor}
        view.backgroundColor = UIColor.clear
    }

    private func updateGuestIndicator() {
        if let conversation = conversation {
            guestIndicatorStack.isHidden = !user.isGuest(in: conversation)
        } else {
            guestIndicatorStack.isHidden = !viewer.isTeamMember || viewer.canAccessCompanyInformation(of: user)
        }
    }

    private func updateExternalIndicator() {
        externalIndicator.isHidden = !user.isExternalPartner
    }

    private func updateFederatedIndicator() {
        federatedIndicator.isHidden = !user.isFederated
    }

    private func updateGroupRoleIndicator() {
        let groupRoleIndicatorHidden: Bool
        switch conversation?.conversationType {
        case .group?:
            groupRoleIndicatorHidden = !(conversation.map(user.isGroupAdmin) ?? false)
        default:
            groupRoleIndicatorHidden = true
        }
        groupRoleIndicator.isHidden = groupRoleIndicatorHidden

    }

    private func applyOptions() {
        nameLabel.isHidden = options.contains(.hideUsername)
        updateHandleLabel()
        updateTeamLabel()
        updateImageButton()
        updateAvailabilityVisibility()
    }

    private func updateHandleLabel() {
        if let handle = user.handle, !handle.isEmpty, !options.contains(.hideHandle) {
            handleLabel.text = "@" + handle
            handleLabel.accessibilityValue = handleLabel.text
        } else {
            handleLabel.isHidden = true
        }
    }

    private func updateTeamLabel() {
        if let teamName = user.teamName, !options.contains(.hideTeamName) {
            teamNameLabel.text = teamName.localized
            teamNameLabel.accessibilityValue = teamNameLabel.text
            teamNameLabel.isHidden = false
        } else {
            teamNameLabel.isHidden = true
        }
    }

    private func updateAvailabilityVisibility() {
        let isHidden = options.contains(.hideAvailability) || !options.contains(.allowEditingAvailability) && user.availability == .none
        availabilityTitleViewController.view?.isHidden = isHidden
    }

    private func updateImageButton() {
        if options.contains(.allowEditingProfilePicture) {
            imageView.accessibilityLabel = AccountPageStrings.ProfilePicture.description
            imageView.accessibilityHint = AccountPageStrings.ProfilePicture.hint
            imageView.accessibilityTraits = .button
            imageView.isUserInteractionEnabled = true
        } else {
            imageView.accessibilityLabel = AccountPageStrings.ProfilePicture.description
            imageView.accessibilityTraits = [.image]
            imageView.isUserInteractionEnabled = false
        }
    }
}

// MARK: - ZMUserObserver

extension ProfileHeaderViewController: ZMUserObserver {

    func userDidChange(_ changeInfo: UserChangeInfo) {

        if changeInfo.nameChanged {
            nameLabel.text = changeInfo.user.name
        }
        if changeInfo.handleChanged {
            updateHandleLabel()
        }

        if changeInfo.availabilityChanged {
            updateAvailabilityVisibility()
        }
    }
}

extension ProfileHeaderViewController: TeamObserver {
    func teamDidChange(_ changeInfo: TeamChangeInfo) {
        if changeInfo.nameChanged {
            updateTeamLabel()
        }
    }
}
