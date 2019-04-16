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
 * A view that displays the overview of a profile for a user.
 */


final class ProfileView: UIView, Themeable {
    
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
    
    /// The user that is displayed.
    let user: GenericUser

    /// The user who is viewing this view
    let viewer: GenericUser

    /// The view controller that displays the view.
    weak var source: UIViewController?
    
    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard colorSchemeVariant != oldValue else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }
    
    /// The options to customize the appearance and behavior of the view.
    var options: Options {
        didSet {
            applyOptions()
        }
    }
    
    // MARKL: - Properties
    
    var stackView: CustomSpacingStackView!
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.accessibilityLabel = "profile_view.accessibility.name".localized
        label.accessibilityIdentifier = "name"

        label.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)

        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        label.font = FontSpec(.large, .light).font!
        label.accessibilityTraits.insert(.header)
        label.lineBreakMode = .byTruncatingTail

        return label
    }()

    let handleLabel = UILabel()
    let teamNameLabel = UILabel()
    let imageView =  UserImageView(size: .big)
    let availabilityView: AvailabilityTitleView
    
    let guestIndicatorStack = UIStackView()
    let guestIndicator = GuestLabelIndicator()
    let remainingTimeLabel = UILabel()
    
    private var userObserverToken: NSObjectProtocol?
    
    // MARK: - Initialization
    
    /**
     * Creates a profile view for the specified user and options.
     * - parameter user: The user to display the profile of.
     * - parameter options: The options for the appearance and behavior of the view.
     * - note: You can change the options later through the `options` property.
     */
    
    init(user: GenericUser,
         viewer: GenericUser,
         options: Options) {
        self.user = user
        self.viewer = viewer
        self.options = options
        self.availabilityView = AvailabilityTitleView(user: user, options: [])
        super.init(frame: .zero)
        configureSubviews()
        configureConstraints()
        applyOptions()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSubviews() {
        let session = SessionManager.shared?.activeUserSession

        imageView.isAccessibilityElement = true
        imageView.accessibilityElementsHidden = false
        imageView.accessibilityIdentifier = "user image"
        imageView.initialsFont = UIFont.systemFont(ofSize: 55, weight: .semibold).monospaced()
        imageView.userSession = session
        imageView.user = user

        availabilityView.tapHandler = { [weak self] button in
            guard let `self` = self, let presentingViewController = self.source else { return }
            guard self.options.contains(.allowEditingAvailability) else { return }
            let alert = self.availabilityView.actionSheet(presentingViewController: presentingViewController)
            alert.popoverPresentationController?.sourceView = self
            alert.popoverPresentationController?.sourceRect = self.availabilityView.frame
            presentingViewController.present(alert, animated: true, completion: nil)
        }
        
        if let session = session {
            userObserverToken = UserChangeInfo.add(observer: self, for: user, userSession: session)
        }

        handleLabel.accessibilityLabel = "profile_view.accessibility.handle".localized
        handleLabel.accessibilityIdentifier = "username"
        handleLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        handleLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        handleLabel.font = FontSpec(.small, .regular).font!
        
        let nameHandleStack = UIStackView(arrangedSubviews: [nameLabel, handleLabel])
        nameHandleStack.axis = .vertical
        nameHandleStack.alignment = .center
        nameHandleStack.spacing = 2
        
        teamNameLabel.accessibilityLabel = "profile_view.accessibility.team_name".localized
        teamNameLabel.accessibilityIdentifier = "team name"
        teamNameLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        teamNameLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        teamNameLabel.font = FontSpec(.small, .regular).font!
        
        nameLabel.text = user.name
        nameLabel.accessibilityValue = nameLabel.text
        
        remainingTimeLabel.font = UIFont.mediumSemiboldFont
        
        guestIndicatorStack.addArrangedSubview(guestIndicator)
        guestIndicatorStack.addArrangedSubview(remainingTimeLabel)
        guestIndicatorStack.spacing = 12
        guestIndicatorStack.axis = .vertical
        guestIndicatorStack.alignment = .center
        guestIndicatorStack.isHidden = true
        
        updateHandleLabel()
        updateTeamLabel()
        
        stackView = CustomSpacingStackView(customSpacedArrangedSubviews: [nameHandleStack, teamNameLabel, imageView, availabilityView, guestIndicatorStack])
        
        stackView.alignment = .center
        stackView.axis = .vertical
        
        stackView.wr_addCustomSpacing(32, after: nameHandleStack)
        stackView.wr_addCustomSpacing(32, after: teamNameLabel)
        stackView.wr_addCustomSpacing(24, after: imageView)

        addSubview(stackView)
        applyColorScheme(colorSchemeVariant)
    }
    
    private func configureConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let leadingSpaceConstraint = stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40)
        let topSpaceConstraint = stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20)
        let trailingSpaceConstraint = stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40)
        let bottomSpaceConstraint = stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)

        leadingSpaceConstraint.priority = .defaultLow
        topSpaceConstraint.priority = .defaultLow
        trailingSpaceConstraint.priority = .defaultLow
        bottomSpaceConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            // imageView
            imageView.widthAnchor.constraint(equalToConstant: 164),
            imageView.heightAnchor.constraint(equalToConstant: 164),
            
            // stackView
            leadingSpaceConstraint, topSpaceConstraint, trailingSpaceConstraint, bottomSpaceConstraint
        ])
    }
    
    // MARK: - Content and Options
    
    func prepareForDisplay(in conversation: ZMConversation?, context: ProfileViewControllerContext) {
        let guestIndicatorHidden: Bool
        switch context {
            case .profileViewer:
                guestIndicatorHidden = !viewer.isTeamMember || viewer.canAccessCompanyInformation(of: user)
            default:
                guestIndicatorHidden = conversation.map(user.isGuest) != true
        }

        guestIndicatorStack.isHidden = guestIndicatorHidden

        let remainingTimeString = user.expirationDisplayString
        remainingTimeLabel.text = remainingTimeString
        remainingTimeLabel.isHidden = remainingTimeString == nil
    }
    
    func applyColorScheme(_ variant: ColorSchemeVariant) {
        availabilityView.colorSchemeVariant = variant
        guestIndicator.colorSchemeVariant = variant
        
        handleLabel.textColor = UIColor.from(scheme: .textForeground, variant: variant)
        nameLabel.textColor = UIColor.from(scheme: .textForeground, variant: variant)
        teamNameLabel.textColor = UIColor.from(scheme: .textForeground, variant: variant)
        remainingTimeLabel.textColor = ColorScheme.default.color(named: .textForeground, variant: variant)
    }
    
    private func updateHandleLabel() {
        if let handle = user.handle, !handle.isEmpty, !options.contains(.hideHandle) {
            handleLabel.text = "@" + handle
            handleLabel.accessibilityValue = handleLabel.text
        }
        else {
            handleLabel.isHidden = true
        }
    }
    
    private func updateTeamLabel() {
        if let teamName = user.teamName, !options.contains(.hideTeamName) {
            teamNameLabel.text = teamName.localizedUppercase
            teamNameLabel.accessibilityValue = teamNameLabel.text
            teamNameLabel.isHidden = false
        } else {
            teamNameLabel.isHidden = true
        }
    }
    
    private func updateAvailabilityVisibility() {
        if options.contains(.allowEditingAvailability) {
            availabilityView.options.insert(.allowSettingStatus)
        } else {
            availabilityView.options.remove(.allowSettingStatus)
        }

        availabilityView.isHidden = options.contains(.hideAvailability) || !user.canDisplayAvailability(with: availabilityView.options)
    }

    private func updateImageButton() {
        if options.contains(.allowEditingProfilePicture) {
            imageView.accessibilityLabel = "self.accessibility.profile_photo_edit_button".localized
            imageView.accessibilityTraits = [.image, .button]
            imageView.isUserInteractionEnabled = true
        } else {
            imageView.accessibilityLabel = "self.accessibility.profile_photo_image".localized
            imageView.accessibilityTraits = [.image]
            imageView.isUserInteractionEnabled = false
        }
    }
    
    private func applyOptions() {
        nameLabel.isHidden = options.contains(.hideUsername)
        updateHandleLabel()
        updateTeamLabel()
        updateImageButton()
        updateAvailabilityVisibility()
    }
    
}

// MARK: - ZMUserObserver

extension ProfileView: ZMUserObserver {
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
