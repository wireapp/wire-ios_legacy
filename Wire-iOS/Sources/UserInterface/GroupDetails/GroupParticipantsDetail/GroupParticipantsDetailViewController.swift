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

final class GroupParticipantsDetailViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    private let collectionView = UICollectionView(forUserList: ())
    private let searchViewController = SearchHeaderViewController(userSelection: .init(), variant: ColorScheme.default.variant)
    private let viewModel: GroupParticipantsDetailViewModel
    
    // used for scrolling and fading selected cells
    private var firstLayout = true
    private var firstLoad = true
    
    weak var delegate: GroupDetailsUserDetailPresenter?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }
    
    init(participants: [UserType], selectedParticipants: [UserType], conversation: ZMConversation) {
        viewModel = GroupParticipantsDetailViewModel(
            participants: participants,
            selectedParticipants: selectedParticipants,
            conversation: conversation
        )

        super.init(nibName: nil, bundle: nil)
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
            scrollToFirstHighlightedUser()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstLoad = false
    }
    
    private func setupViews() {
        addToSelf(searchViewController)
        searchViewController.view.translatesAutoresizingMaskIntoConstraints = false
        searchViewController.delegate = viewModel
        viewModel.participantsDidChange = collectionView.reloadData
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SelectedUserCell.self, forCellWithReuseIdentifier: SelectedUserCell.reuseIdentifier)
        title = "participants.all.title".localized.uppercased()
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
    
    private func scrollToFirstHighlightedUser() {
        if let idx = viewModel.indexOfFirstSelectedParticipant {
            let indexPath = IndexPath(row: idx, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout & UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.participants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectedUserCell.reuseIdentifier, for: indexPath) as! SelectedUserCell
        let user = viewModel.participants[indexPath.row]
        
        cell.configure(
            with: .user(user),
            conversation: viewModel.conversation,
            showSeparator: viewModel.participants.count - 1 != indexPath.row
        )
        
        cell.configureContentBackground(preselected: viewModel.isUserSelected(user), animated: firstLoad)

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let user = viewModel.participants[indexPath.row] as? ZMUser else { return }
        delegate?.presentDetails(for: user)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.bounds.size.width, height: 56)
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
