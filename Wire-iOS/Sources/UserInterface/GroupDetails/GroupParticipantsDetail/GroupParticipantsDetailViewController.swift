//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

final class GroupParticipantsDetailViewController: UIViewController {

    private let collectionView = UICollectionView(forGroupedSections: ())
    private let searchViewController = SearchHeaderViewController(userSelection: .init(), variant: ColorScheme.default.variant)
    private let viewModel: GroupParticipantsDetailViewModel
    private let collectionViewController: SectionCollectionViewController
    
    // used for scrolling and fading selected cells
    private var firstLayout = true
    private var firstLoad = true
    
    private var sections: [CollectionViewSectionController] = []
    
    weak var delegate: GroupDetailsUserDetailPresenter?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }
    
    init(participants: [UserType], ///TODO: no need to pass this 
         selectedParticipants: [UserType],
         conversation: ZMConversation) {
        
        var allParticipants = conversation.sortedOtherParticipants
        allParticipants = allParticipants.sorted { $0.displayName < $1.displayName }
        if let selfUser = ZMUser.selfUser() {
            allParticipants.insert(selfUser, at: 0)
        }

        
        viewModel = GroupParticipantsDetailViewModel(
            participants: allParticipants,
            selectedParticipants: selectedParticipants,
            conversation: conversation
        )
        collectionViewController = SectionCollectionViewController()
        
        super.init(nibName: nil, bundle: nil)
        sections = computeSections()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if firstLayout {
            firstLayout = false
//            scrollToFirstHighlightedUser()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstLoad = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        collectionViewController.collectionView?.reloadData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionViewController.collectionView?.collectionViewLayout.invalidateLayout()
        })
    }
    
    private func setupViews() {
        addToSelf(searchViewController)
        searchViewController.view.translatesAutoresizingMaskIntoConstraints = false
        searchViewController.delegate = viewModel
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        collectionViewController.collectionView = collectionView
        collectionViewController.sections = sections
        viewModel.participantsDidChange = self.participantsDidChange
        
        collectionView.accessibilityIdentifier = "group_details.full_list"
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        title = "participants.all.title".localized(uppercased: true)
        view.backgroundColor = UIColor.from(scheme: .contentBackground)
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            searchViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            searchViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: searchViewController.view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func participantsDidChange() {
        collectionViewController.sections = computeSections()
        collectionViewController.collectionView?.reloadData()
    }
    
    private func scrollToFirstHighlightedUser() {
        if let idx = viewModel.indexOfFirstSelectedParticipant {
            let indexPath = IndexPath(row: idx, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        }
    }
    
    private func computeSections() -> [CollectionViewSectionController] {
        let adminsSection = ParticipantsSectionController(participants: viewModel.admins, conversation: viewModel.conversation, teamRole: .admin, isRowsComputed: false, delegate: self)
        let membersSection = ParticipantsSectionController(participants: viewModel.members, conversation: viewModel.conversation, teamRole: .member, isRowsComputed: false, delegate: self)

        sections = (viewModel.admins.isEmpty && viewModel.members.isEmpty) ? [] : [adminsSection, membersSection]
        return sections
    }
}

private class SelectedUserCell: UserCell {

    func configureContentBackground(preselected: Bool, animated: Bool) {
        contentView.backgroundColor = .clear
        guard preselected else { return }
        
        let changes: () -> () = {
            self.contentView.backgroundColor = UIColor.from(scheme: .cellSeparator)
        }
        
        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0.5,
                options: .curveLinear,
                animations: changes
            )
        } else {
            changes()
        }
    }
}

extension GroupParticipantsDetailViewController: GroupDetailsSectionControllerDelegate {
    
    func presentDetails(for user: ZMUser) {
        let viewController = UserDetailViewControllerFactory.createUserDetailViewController(
            user: user,
            conversation: viewModel.conversation,
            profileViewControllerDelegate: self,
            viewControllerDismisser: self
        )
        if !user.isSelfUser {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func presentFullParticipantsList(for users: [UserType], in conversation: ZMConversation) {
        presentParticipantsDetails(with: users, selectedUsers: [], animated: true)
    }
    
    @objc(presentParticipantsDetailsWithUsers:selectedUsers:animated:)
    func presentParticipantsDetails(with users: [UserType], selectedUsers: [UserType], animated: Bool) {
        let detailsViewController = GroupParticipantsDetailViewController(
            participants: users,
            selectedParticipants: selectedUsers,
            conversation: viewModel.conversation
        )
        
        detailsViewController.delegate = self
        navigationController?.pushViewController(detailsViewController, animated: animated)
    }
    
}

extension GroupParticipantsDetailViewController: ViewControllerDismisser, ProfileViewControllerDelegate {
    
    func dismiss(viewController: UIViewController, completion: (() -> ())?) {
        navigationController?.popViewController(animated: true, completion: completion)
    }
    
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        dismiss(animated: true) {
            ZClientViewController.shared()?.load(conversation, scrollTo: nil, focusOnView: true, animated: true)
        }
    }
    
}
