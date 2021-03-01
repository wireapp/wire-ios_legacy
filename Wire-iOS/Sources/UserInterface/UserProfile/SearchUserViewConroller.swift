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

import Foundation
import UIKit
import WireDataModel
import WireSyncEngine

final class SearchUserViewConroller: UIViewController, SpinnerCapable {
    var dismissSpinner: SpinnerCompletion?

    private var searchDirectory: SearchDirectory!
    private weak var profileViewControllerDelegate: ProfileViewControllerDelegate?
    private let userId: UUID
    private var pendingSearchTask: SearchTask?

    /// flag for handleSearchResult. Only allow to display the result once
    private var resultHandled = false

    public init(userId: UUID, profileViewControllerDelegate: ProfileViewControllerDelegate?) {
        self.userId = userId
        self.profileViewControllerDelegate = profileViewControllerDelegate

        super.init(nibName: nil, bundle: nil)

        if let session = ZMUserSession.shared() {
            searchDirectory = SearchDirectory(userSession: session)
        }

        view.backgroundColor = UIColor.from(scheme: .contentBackground)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        searchDirectory?.tearDown()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let cancelItem = UIBarButtonItem(icon: .cross, target: self, action: #selector(cancelButtonTapped))
        cancelItem.accessibilityIdentifier = "CancelButton"
        cancelItem.accessibilityLabel = "general.cancel".localized
        navigationItem.rightBarButtonItem = cancelItem

        isLoadingViewVisible = true

        if let task = searchDirectory?.lookup(userId: userId) {
            task.onResult({ [weak self] in
                self?.handleSearchResult(searchResult: $0, isCompleted: $1)
            })
            task.start()

            pendingSearchTask = task
        }

    }

    private func handleSearchResult(searchResult: SearchResult, isCompleted: Bool) {
        guard !resultHandled,
              isCompleted
            else { return }

        let profileUser: UserType?
        if let searchUser = searchResult.directory.first {
            profileUser = searchUser
        } else if let memberUser = searchResult.teamMembers.first?.user {
            profileUser = memberUser
        } else {
            profileUser = nil
        }

        if let profileUser = profileUser {
            let profileViewController = ProfileViewController(user: profileUser, viewer: ZMUser.selfUser(), context: .profileViewer)
            profileViewController.delegate = profileViewControllerDelegate

            navigationController?.setViewControllers([profileViewController], animated: true)
            resultHandled = true
        } else if isCompleted {
            presentInvalidUserProfileLinkAlert(okActionHandler: { [weak self] (_) in
                self?.dismiss(animated: true)
            })
        }
    }

    // MARK: - Actions

    @objc private func cancelButtonTapped(sender: AnyObject?) {
        pendingSearchTask?.cancel()
        pendingSearchTask = nil

        dismiss(animated: true)
    }
}
