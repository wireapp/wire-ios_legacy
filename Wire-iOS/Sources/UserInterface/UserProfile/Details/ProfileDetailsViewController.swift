//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
 * A view controller that displays the details for a user.
 */

class ProfileDetailsViewController: UIViewController, Themeable {

    /// The user whose profile is displayed.
    let user: GenericUser

    /// The user that views the profile.
    let viewer: GenericUser

    /// The conversation where the profile is displayed.
    let conversation: ZMConversation?

    /**
     * The object that calculates and controls the content to display in the user
     * details screen. It is also responsible for reacting to user profile updates
     * that impact the details.
     * - note: It should be the delegate and data source of the table view.
     */

    let contentController: ProfileDetailsContentController

    // MARK: - UI Properties

    private let profileView: ProfileView
    private let profileViewContainer = UIView()
    private let tableView = UITableView(frame: .zero, style: .grouped)

    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard colorSchemeVariant != oldValue else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }
    
    // MARK: - Initialization

    /**
     * Creates a new profile details screen for the specified configuration.
     * - parameter user: The user whose profile is displayed.
     * - parameter viewer: The user that views the profile.
     * - parameter conversation: The conversation where the profile is displayed.
     */
    
    init(user: GenericUser, viewer: GenericUser, conversation: ZMConversation?) {
        self.user = user
        self.viewer = viewer
        self.conversation = conversation
        self.profileView = ProfileView(user: user, options: [.hideUsername, .hideHandle, .hideTeamName])
        self.contentController = ProfileDetailsContentController(user: user, viewer: viewer, conversation: conversation)
        super.init(nibName: nil, bundle: nil)
        self.contentController.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configureConstraints()
    }
    
    private func configureSubviews() {
        tableView.dataSource = contentController
        tableView.delegate = contentController
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 56
        tableView.contentInset.bottom = 88
        view.addSubview(tableView)
        
        // Create the profile header
        if user.isSelfUser || !contentController.viewerCanAccessRichProfile {
            profileView.options.insert(.hideAvailability)
        }
        
        profileView.prepareForDisplay(in: conversation)
        profileView.availabilityView.options = .profileDetails
        profileView.imageView.isAccessibilityElement = false
        profileView.imageView.isUserInteractionEnabled = false
        profileViewContainer.addSubview(profileView)
        tableView.tableHeaderView = profileViewContainer
        
        tableView.backgroundColor = .clear
        applyColorScheme(colorSchemeVariant)
    }
    
    private func configureConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        profileView.translatesAutoresizingMaskIntoConstraints = false
        profileViewContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // tableView
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // profileView
            profileViewContainer.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            profileView.leadingAnchor.constraint(equalTo: profileViewContainer.leadingAnchor),
            profileView.topAnchor.constraint(equalTo: profileViewContainer.topAnchor),
            profileView.trailingAnchor.constraint(equalTo: profileViewContainer.trailingAnchor),
            profileView.bottomAnchor.constraint(equalTo: profileViewContainer.bottomAnchor)
        ])
    }
    
    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        view.backgroundColor = UIColor.from(scheme: .contentBackground, variant: colorSchemeVariant)
        tableView.separatorColor = UIColor.from(scheme: .separator, variant: colorSchemeVariant)
    }
        
    // MARK: - Layout
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update the header by recalculating its frame
        guard let headerView = tableView.tableHeaderView else {
            return
        }
        
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            // We need to reassign the header view on iOS 10 to resize the header properly.
            tableView.tableHeaderView = headerView
            tableView.layoutIfNeeded()
        }
    }
    
}

// MARK: - ProfileDetailsContentController

extension ProfileDetailsViewController: ProfileDetailsContentControllerDelegate {
    
    func profileDetailsContentDidChange() {
        tableView.reloadData()
    }
    
}
