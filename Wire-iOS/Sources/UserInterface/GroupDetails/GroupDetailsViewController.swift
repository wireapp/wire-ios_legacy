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
import Cartography

class GroupDetailsViewController: UIViewController, ZMConversationObserver, GroupDetailsFooterViewDelegate {
    
    private let collectionViewController: CollectionViewController
    private let conversation: ZMConversation
    private let footerView = GroupDetailsFooterView()
    private let bottomSpacer = UIView()
    private var token: NSObjectProtocol?
    private var actionController: ConversationActionController?
    
    public init(conversation: ZMConversation) {
        self.conversation = conversation
        collectionViewController = CollectionViewController()
        super.init(nibName: nil, bundle: nil)
        collectionViewController.sections = computeVisibleSections()
        token = ConversationChangeInfo.add(observer: self, for: conversation)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumInteritemSpacing = 12
        collectionViewLayout.minimumLineSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorContentBackground)
        collectionView.allowsMultipleSelection = true
        collectionView.keyboardDismissMode = .onDrag
        collectionView.bounces = true
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0)
        
        [collectionView, footerView, bottomSpacer].forEach(view.addSubview)
        bottomSpacer.backgroundColor = .wr_color(fromColorScheme: ColorSchemeColorBackground)
        
        constrain(view, collectionView, footerView, bottomSpacer) { container, collectionView, footerView, bottomSpacer in
            collectionView.top == container.top
            collectionView.leading == container.leading
            collectionView.trailing == container.trailing
            collectionView.bottom == footerView.top
            footerView.leading == container.leading
            footerView.trailing == container.trailing
            footerView.bottom == bottomSpacer.top
            
            if #available(iOS 11, *) {
                bottomSpacer.top == container.safeAreaLayoutGuide.bottom
            } else {
                bottomSpacer.top == container.bottom
            }
            
            bottomSpacer.bottom == container.bottom
            bottomSpacer.leading == container.leading
            bottomSpacer.trailing == container.trailing
        }
        
        collectionViewController.collectionView = collectionView
        footerView.delegate = self
    }

    func computeVisibleSections() -> [_CollectionViewSectionController] {
        var sections = [_CollectionViewSectionController]()
        if nil != ZMUser.selfUser().team {
            let optionsController = GuestOptionsSection()
            sections.append(optionsController)
        }
        if conversation.mutableOtherActiveParticipants.count > 0 {
            let participantsSectionController = ParticipantsSectionController(conversation: conversation)
            sections.append(participantsSectionController)
        }
        if conversation.includesServiceUser {
            let servicesSection = ServicesSectionController(conversation: conversation)
            sections.append(servicesSection)
        }
        return sections
    }
    
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        // TODO: Check if `teamOnly` changed.
        guard changeInfo.participantsChanged || changeInfo.nameChanged else { return }
        collectionViewController.sections = computeVisibleSections()
    }
    
    func detailsView(_ view: GroupDetailsFooterView, performAction action: GroupDetailsFooterView.Action) {
        switch action {
        case .invite: break
        case .more:
            actionController = ConversationActionController(conversation: conversation, target: self)
            actionController?.presentMenu()
        }
    }

}

class CollectionViewController: NSObject, UICollectionViewDelegate {
    
    var collectionView : UICollectionView? = nil {
        didSet {
            collectionView?.dataSource = self
            collectionView?.delegate = self
            
            sections.forEach {
                $0.prepareForUse(in: collectionView)
            }
            
            collectionView?.reloadData()
        }
    }
    
    var sections: [_CollectionViewSectionController] {
        didSet {
            sections.forEach {
                $0.prepareForUse(in: collectionView)
            }
            
            collectionView?.reloadData()
        }
    }
    
    init(sections : [_CollectionViewSectionController] = []) {
        self.sections = sections
    }
    
}

extension CollectionViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].collectionView(collectionView, numberOfItemsInSection: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return sections[indexPath.section].collectionView(collectionView, cellForItemAt:indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return sections[indexPath.section].collectionView!(collectionView, viewForSupplementaryElementOfKind:kind, at:indexPath)
    }
    
}

extension CollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return sections[section].collectionView?(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section) ?? CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return sections[indexPath.section].collectionView?(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath) ?? CGSize.zero
    }
    
}

protocol _CollectionViewSectionController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func prepareForUse(in collectionView : UICollectionView?)
    
}

class DefaultSectionController: NSObject, _CollectionViewSectionController {
    
    var sectionTitle : String {
        return "Header"
    }
    
    var variant : ColorSchemeVariant = ColorScheme.default().variant
    
    func prepareForUse(in collectionView : UICollectionView?) {
        collectionView?.register(GroupDetailsSectionHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "SectionHeader")
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "SectionHeader", for: indexPath)
        
        if let sectionHeaderView = supplementaryView as? GroupDetailsSectionHeader {
            sectionHeaderView.variant = variant
            sectionHeaderView.titleLabel.text = sectionTitle
        }
        
        return supplementaryView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 48)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fatal("Must be overridden")
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatal("Must be overridden")
    }
    
}

class ParticipantsSectionController: DefaultSectionController {
    
    private let participants: [ZMBareUser]
    
    init(conversation: ZMConversation) {
        participants = conversation.sortedOtherParticipants
    }
    
    override func prepareForUse(in collectionView : UICollectionView?) {
        super.prepareForUse(in: collectionView)
        
        collectionView?.register(GroupDetailsParticipantCell.self, forCellWithReuseIdentifier: GroupDetailsParticipantCell.zm_reuseIdentifier)
    }
    
    override var sectionTitle: String {
        return "participants.section.participants".localized(args: participants.count).uppercased()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return participants.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let user = participants[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupDetailsParticipantCell.zm_reuseIdentifier, for: indexPath) as! GroupDetailsParticipantCell
        
        cell.configure(with: user)
        cell.separator.isHidden = participants.count - 1 == indexPath.row
        return cell
    }
    
}

class ServicesSectionController: DefaultSectionController {
    
    private let serviceUsers: [ZMBareUser]
    
    init(conversation: ZMConversation) {
        serviceUsers = conversation.sortedServiceUsers
    }
    
    override func prepareForUse(in collectionView : UICollectionView?) {
        super.prepareForUse(in: collectionView)
        
        collectionView?.register(GroupDetailsParticipantCell.self, forCellWithReuseIdentifier: GroupDetailsParticipantCell.zm_reuseIdentifier)
    }
    
    override var sectionTitle: String {
        return "participants.section.services".localized(args: serviceUsers.count).uppercased()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return serviceUsers.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let user = serviceUsers[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupDetailsParticipantCell.zm_reuseIdentifier, for: indexPath) as! GroupDetailsParticipantCell
        
        cell.configure(with: user)
        cell.separator.isHidden = serviceUsers.count - 1 == indexPath.row
        return cell
    }
    
}

class GuestOptionsSection: NSObject, _CollectionViewSectionController {
    
    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView?.register(GroupDetailsGuestOptionsCell.self, forCellWithReuseIdentifier: GroupDetailsGuestOptionsCell.zm_reuseIdentifier)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupDetailsGuestOptionsCell.zm_reuseIdentifier, for: indexPath) as! GroupDetailsGuestOptionsCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }
    
}
