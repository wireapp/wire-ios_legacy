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


import Foundation


final class DraftsRootViewController: UISplitViewController {

    let persistence: MessageDraftStorage

    init() {
        persistence = try! MessageDraftStorage(sharedContainerURL: ZMUserSession.shared()!.sharedContainerURL)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        let navigationController = DraftNavigationController(rootViewController: DraftListViewController(persistence: persistence))
        viewControllers = [navigationController]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if persistence.numberOfStoredDrafts() == 0 || traitCollection.horizontalSizeClass != .compact {
            let initialComposeViewController = MessageComposeViewController(draft: nil)
            let detail = DraftNavigationController(rootViewController: initialComposeViewController)
            UIView.performWithoutAnimation {
                showDetailViewController(detail, sender: nil)
            }
        }
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(false)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default().statusBarStyle
    }

}
