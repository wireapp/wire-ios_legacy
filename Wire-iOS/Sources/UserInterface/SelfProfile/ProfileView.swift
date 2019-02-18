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


class ProfileView: UIView {
    
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
        
    }
    
    /// The user that is displayed.
    let user: ZMUser
    
    /// The view controller that displays the view.
    weak var source: UIViewController?
    
    /// The options to customize the appearance and behavior of the view.
    var options: Options {
        didSet {
            applyOptions()
        }
    }
    
    // MARKL: - Properties
    
    let stackView = UIStackView()
    
    let nameLabel = UILabel()
    let handleLabel = UILabel()
    let teamNameLabel = UILabel()
    let imageView =  UserImageView(size: .big)
    let availabilityView: AvailabilityTitleView
    
    private var userObserverToken: NSObjectProtocol?
    
    // MARK: - Initialization
    
    /**
     * Creates a profile view for the specified user and options.
     * - parameter user: The user to display the profile of.
     * - parameter options: The options for the appearance and behavior of the view.
     * - note: You can change the options later through the `options` property.
     */
    
    init(user: ZMUser, options: Options) {
        self.user = user
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
        
        imageView.accessibilityIdentifier = "user image"
        imageView.userSession = session
        imageView.user = user
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "self.profile.change_user_image.accessibility".localized
        imageView.accessibilityTraits = .button
        imageView.accessibilityElementsHidden = false
        
        availabilityView.tapHandler = { [weak self] button in
            guard let `self` = self else { return }
            guard self.options.contains(.allowEditingAvailability) else { return }
            let alert = self.availabilityView.actionSheet
            alert.popoverPresentationController?.sourceView = self
            alert.popoverPresentationController?.sourceRect = self.availabilityView.frame
            self.source?.present(alert, animated: true, completion: nil)
        }
        
        if let session = session {
            userObserverToken = UserChangeInfo.add(observer: self, for: user, userSession: session)
        }
        
        nameLabel.accessibilityLabel = "profile_view.accessibility.name".localized
        nameLabel.accessibilityIdentifier = "name"
        nameLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        nameLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        nameLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        nameLabel.font = FontSpec(.large, .medium).font!
        
        handleLabel.accessibilityLabel = "profile_view.accessibility.handle".localized
        handleLabel.accessibilityIdentifier = "username"
        handleLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        handleLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        handleLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        handleLabel.font = FontSpec(.small, .regular).font!
        
        let nameHandleStack = UIStackView(arrangedSubviews: [nameLabel, handleLabel])
        nameHandleStack.axis = .vertical
        nameHandleStack.alignment = .center
        nameHandleStack.spacing = 2
        
        teamNameLabel.accessibilityLabel = "profile_view.accessibility.team_name".localized
        teamNameLabel.accessibilityIdentifier = "team name"
        teamNameLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        teamNameLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        teamNameLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        teamNameLabel.font = FontSpec(.small, .regular).font!
        
        nameLabel.text = user.name
        nameLabel.accessibilityValue = nameLabel.text
        
        updateHandleLabel()
        updateTeamLabel()
        
        [nameHandleStack, teamNameLabel, imageView, availabilityView].forEach(stackView.addArrangedSubview)
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 32
        addSubview(stackView)
    }
    
    private func configureConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // imageView
            imageView.widthAnchor.constraint(equalToConstant: 164),
            imageView.heightAnchor.constraint(equalToConstant: 164),
            
            // stackView
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Content and Options
    
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
        if let team = user.team, let teamName = team.name, !options.contains(.hideTeamName) {
            teamNameLabel.text = teamName.localizedUppercase
            teamNameLabel.accessibilityValue = teamNameLabel.text
        } else {
            teamNameLabel.isHidden = true
        }
    }
    
    private func updateAvailabilityVisibility() {
        availabilityView.isHidden = options.contains(.hideAvailability) || !user.canDisplayAvailability(with: availabilityView.options)
    }
    
    private func applyOptions() {
        nameLabel.isHidden = options.contains(.hideUsername)
        updateHandleLabel()
        updateTeamLabel()
        
        if options.contains(.allowEditingAvailability) {
            availabilityView.options.insert(.allowSettingStatus)
        } else {
            availabilityView.options.remove(.allowSettingStatus)
        }
        
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
