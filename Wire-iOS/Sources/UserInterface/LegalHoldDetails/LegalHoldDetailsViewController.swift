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


class LegalHoldDetailsViewController: UIViewController {
    
    fileprivate let collectionView = UICollectionView(forUserList: ())
    fileprivate let collectionViewController: SectionCollectionViewController
    fileprivate let conversation: ZMConversation
    
    convenience init?(user: UserType) {
        guard let conversation = user.oneToOneConversation else { return nil }
        self.init(conversation: conversation)
    }
        
    init(conversation: ZMConversation) {
        self.conversation = conversation
        self.collectionViewController = SectionCollectionViewController()
        self.collectionViewController.collectionView = collectionView
        
        super.init(nibName: nil, bundle: nil)
        
        setupViews()
        createConstraints()
        collectionViewController.sections = computeVisibleSections()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "legalhold.header.title".localized.localizedUppercase
        view.backgroundColor = UIColor.from(scheme: .contentBackground)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
    }
    
    fileprivate func setupViews() {
        
        view.addSubview(collectionView)

        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
    }
    
    fileprivate func createConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    fileprivate func computeVisibleSections() -> [CollectionViewSectionController] {
        let headerSection = SingleViewSectionController(view: LegalHoldHeaderView(frame: .zero))
        let legalHoldParticipantsSection = LegalHoldParticipantsSectionController(participants: conversation.sortedActiveParticipants, conversation: conversation)
        legalHoldParticipantsSection.delegate = self
        
        return [headerSection, legalHoldParticipantsSection]
    }
    
}

extension LegalHoldDetailsViewController: LegalHoldParticipantsSectionControllerDelegate {
    
    func legalHoldParticipantsSectionWantsToPresentUserProfile(for user: UserType) {
        let profileViewController = ProfileViewController(user: user, viewer: ZMUser.selfUser(), context: .deviceList)
        show(profileViewController, sender: nil)
    }
    
}
