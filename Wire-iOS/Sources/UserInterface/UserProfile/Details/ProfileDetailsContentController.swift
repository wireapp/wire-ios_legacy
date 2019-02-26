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
 * An object that receives notifications from a profile details content controller.
 */

protocol ProfileDetailsContentControllerDelegate: class {
    
    /// Called when the profile details change.
    func profileDetailsContentDidChange()
}

/**
 * An object that controls the content to display in the user details screen.
 */

class ProfileDetailsContentController: NSObject, UITableViewDataSource, UITableViewDelegate, ZMUserObserver {
    
    /**
     * The type of content that can be displayed in the profile details.
     */
    
    enum Content: Equatable {
        /// Display extended user metadata from SCIM.
        case extendedMetadata([[String: String]])
        
        /// Display the status of read receipts for a 1:1 conversation.
        case readReceiptsStatus(enabled: Bool)
    }
    
    /// The user to display the details of.
    let user: GenericUser
    
    /// The user that will see the details.
    let viewer: GenericUser
    
    /// The conversation where the profile details will be displayed.
    let conversation: ZMConversation?
        
    // MARK: - Accessing the Content
    
    /// The contents to display for the current configuration.
    private(set) var contents: [Content] = []
    
    /// The object that will receive notifications in case of content change.
    weak var delegate: ProfileDetailsContentControllerDelegate?

    // MARK: - Properties
    
    private var observerToken: Any?
    private let userPropertyCellID = "UserPropertyCell"
    
    // MARK: - Initialization
    
    /**
     * Creates the controller to display the profile details for the specified user,
     * in the scope of the given conversation.
     * - parameter user: The user to display the details of.
     * - parameter viewer: The user that will see the details. Most commonly, the self user.
     * - parameter conversation: The conversation where the profile details will be displayed.
     */
    
    init(user: GenericUser, viewer: GenericUser, conversation: ZMConversation?) {
        self.user = user
        self.viewer = viewer
        self.conversation = conversation
        super.init()
        configureObservers()
        updateContent()
    }
    
    // MARK: - Calculating the Content
    
    /// Whether the viewer can access the extended metadata of the displayed user.
    var viewerCanAccessExtendedMetadata: Bool {
        return viewer.canAccessCompanyInformation(of: user)
    }
    
    /// Starts observing changes in the user profile.
    private func configureObservers() {
        if let userSession = ZMUserSession.shared() {
            observerToken = UserChangeInfo.add(observer: self, for: user, userSession: userSession)
        }
    }
    
    /// Updates the content for the current configuration.
    private func updateContent() {
        switch conversation?.conversationType {
        case .group?:
            let _extendedMetadata: [[String: String]]? = useDefaultData ? defaultData : user.extendedMetadata
            if let extendedMetadata = _extendedMetadata, viewerCanAccessExtendedMetadata, !extendedMetadata.isEmpty {
                // If there is extended metadata and the user is allowed to see it, display it.
                contents = [.extendedMetadata(extendedMetadata)]
            } else {
                // If there is no extended metadata, show nothing.
                contents = []
            }

        case .oneOnOne?:
            let readReceiptsEnabled = viewer.readReceiptsEnabled
            let _extendedMetadata: [[String: String]]? = useDefaultData ? defaultData : user.extendedMetadata
            if let extendedMetadata = _extendedMetadata, viewerCanAccessExtendedMetadata, !extendedMetadata.isEmpty {
                // If there is extended metadata and the user is allowed to see it, display it and the read receipts status.
                contents = [.extendedMetadata(extendedMetadata), .readReceiptsStatus(enabled: readReceiptsEnabled)]
            } else {
                // If there is no extended metadata, show the read receipts.
                contents = [.readReceiptsStatus(enabled: readReceiptsEnabled)]
            }

        default:
            contents = []
        }
        
        delegate?.profileDetailsContentDidChange()
    }

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.readReceiptsEnabledChanged || changeInfo.extendedMetadataChanged else { return }
        updateContent()
    }
    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch contents[section] {
        case .extendedMetadata(let fields):
            return fields.count
        case .readReceiptsStatus:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = SectionTableHeader()

        switch contents[section] {
        case .extendedMetadata:
            header.titleLabel.text = "profile.extended_metadata.header".localized(uppercased: true)
            header.accessibilityIdentifier = "InformationHeader"
        case .readReceiptsStatus(let enabled):
            header.accessibilityIdentifier = "ReadReceiptsStatusHeader"
            if enabled {
                header.titleLabel.text = "profile.read_receipts_enabled_memo.header".localized(uppercased: true)
            } else {
                header.titleLabel.text = "profile.read_receipts_disabled_memo.header".localized(uppercased: true)
            }
        }

        return header
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch contents[indexPath.section] {
        case .extendedMetadata(let fields):
            let field = fields[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: userPropertyCellID) as? UserPropertyCell ?? UserPropertyCell(style: .default, reuseIdentifier: userPropertyCellID)
            cell.propertyName = field["key"]
            cell.propertyValue = field["value"]
            cell.showSeparator = indexPath.row < fields.count - 1
            return cell

        case .readReceiptsStatus:
            fatalError("We do not create cells for the readReceiptsStatus section.")
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch contents[section] {
        case .extendedMetadata:
            return nil
        case .readReceiptsStatus:
            let footer = SectionTableFooter()
            footer.titleLabel.text = "profile.read_receipts_memo.body".localized
            footer.accessibilityIdentifier = "ReadReceiptsStatusFooter"
            return footer
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

// NOTE: The following data is a set of sample fields that are required to create
// builds manually for QA, as we don't have backend support yet. This will be removed
// in a subsequent PR, when we have proper support from the BE.

extension ProfileDetailsContentController {
    
    var useDefaultData: Bool {
        // Set this to true to use the sample extended fields instead of the data
        // saved in the user model.
        return AutomationHelper.sharedHelper.shouldUseMockRichProfile
    }
    
    var defaultData: [[String: String]] {
        return [
        ["key": "Title", "value": "Chief Design Officer"],
        ["key": "Entity", "value": "ACME/OBS/EQUANT/CSO/IBO/OEC/SERVICE OP/CS MGT/CSM EEMEA"],
        ["key": "Email", "value": "user@acme.com"],
        ["key": "Phone", "value": "01234567890"],
        ["key": "Personal Page", "value": "https://acme.com/chief_design_officer"],
        ["key": "Favorite Quote", "value": "Monads are just giant burritos 🌯"],
        ["key": "Title2", "value": "Chief Design Officer"],
        ["key": "Entity2", "value": "ACME/OBS/EQUANT/CSO/IBO/OEC/SERVICE OP/CS MGT/CSM EEMEA"],
        ["key": "Email2", "value": "user@acme.com"],
        ["key": "Phone2", "value": "01234567890"],
        ["key": "Personal Page2", "value": "https://acme.com/chief_design_officer"],
        ["key": "Favorite Quote2", "value": "Monads are just giant burritos 🌯"],
        ]
    }
    
}
