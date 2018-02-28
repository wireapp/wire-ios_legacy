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
    
    fileprivate let collectionViewController: CollectionViewController
    fileprivate let conversation: ZMConversation
    fileprivate let footerView = GroupDetailsFooterView()
    fileprivate let bottomSpacer = UIView()
    fileprivate var token: NSObjectProtocol?
    fileprivate var actionController: ConversationActionController?
    fileprivate var renameSectionController : RenameSectionController?
    fileprivate let emptyView = UIImageView()
    private var emptyViewVerticalConstraint: NSLayoutConstraint?

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
        title = "participants.title".localized.uppercased()
        view.backgroundColor = .wr_color(fromColorScheme: ColorSchemeColorContentBackground)
        
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumInteritemSpacing = 12
        collectionViewLayout.minimumLineSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear
        collectionView.allowsMultipleSelection = false
        collectionView.keyboardDismissMode = .onDrag
        collectionView.bounces = true
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0)
        
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        
        [emptyView, collectionView, footerView, bottomSpacer].forEach(view.addSubview)
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
    
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = true
        
        let backgroundColor = ColorScheme.default().color(withName: ColorSchemeColorBackground)
        let emptyViewColor = backgroundColor.mix(ColorScheme.default().color(withName: ColorSchemeColorTextForeground), amount: 0.16)
        emptyView.image = UIImage(for: .person, fontSize: 160, color: emptyViewColor)
        emptyView.contentMode = .center
        emptyView.accessibilityIdentifier = "img.groupdetails.empty"
        emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emptyViewVerticalConstraint = emptyView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor, constant: 0)
        emptyViewVerticalConstraint?.isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
        updateEmptyViewVisibility()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateEmptyViewVisibility()
    }
    
    private func updateEmptyViewVisibility() {
        collectionViewController.collectionView?.setNeedsLayout()
        collectionViewController.collectionView?.layoutIfNeeded()
        emptyViewVerticalConstraint?.constant = collectionViewController.collectionView.map { $0.contentInset.top / 2 + $0.contentSize.height / 2 } ?? 0
        emptyView.isHidden = collectionViewController.sections.any { $0 is ParticipantsSectionController || $0 is ServicesSectionController }
    }

    func computeVisibleSections() -> [_CollectionViewSectionController] {
        var sections = [_CollectionViewSectionController]()
        let renameSectionController = RenameSectionController(conversation: conversation)
        sections.append(renameSectionController)
        self.renameSectionController = renameSectionController
        
        if nil != ZMUser.selfUser().team {
            let optionsController = GuestOptionsSection(conversation: conversation, delegate: self)
            sections.append(optionsController)
        }
        let (participants, serviceUsers) = (conversation.sortedOtherParticipants, conversation.sortedServiceUsers)
        if !participants.isEmpty {
            let participantsSectionController = ParticipantsSectionController(participants: participants, delegate: self)
            sections.append(participantsSectionController)
        }
        if !serviceUsers.isEmpty {
            let servicesSection = ServicesSectionController(serviceUsers: serviceUsers, delegate: self)
            sections.append(servicesSection)
        }
        
        return sections
    }
    
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard changeInfo.participantsChanged || changeInfo.nameChanged || changeInfo.allowGuestsChanged else { return }
        collectionViewController.sections = computeVisibleSections()
        updateEmptyViewVisibility()
    }
    
    func detailsView(_ view: GroupDetailsFooterView, performAction action: GroupDetailsFooterView.Action) {
        switch action {
        case .invite:
            let addParticipantsViewController = AddParticipantsViewController(conversation: conversation)
            present(addParticipantsViewController.wrapInNavigationController(), animated: true)
        case .more:
            actionController = ConversationActionController(conversation: conversation, target: self)
            actionController?.renameDelegate = self
            actionController?.presentMenu()
        }
    }
    
    func dismissButtonTapped() {
        dismiss(animated: true)
    }
    
}

extension GroupDetailsViewController: ConversationActionControllerRenameDelegate {
    func controllerWantsToRenameConversation(_ controller: ConversationActionController) {
        collectionViewController.collectionView?.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        renameSectionController?.focus()
    }
}

extension GroupDetailsViewController: ViewControllerDismissable, UINavigationControllerDelegate, ProfileViewControllerDelegate {
    
    func viewControllerWants(toBeDismissed controller: UIViewController!, completion: (() -> Void)!) {
        navigationController?.popViewController(animated: true)
    }
    
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        dismiss(animated: true) {
            ZClientViewController.shared()?.load(conversation, focusOnView: true, animated: true)
        }
    }
    
}

extension GroupDetailsViewController: ParticipantsSectionControllerDelegate {
    
    func presentDetailsView(for user: ZMUser) {
        let viewController = UserDetailViewControllerFactory.createUserDetailViewController(user: user,
                                                                                            conversation: conversation,
                                                                                            profileViewControllerDelegate: self,
                                                                                            viewControllerDismissable: self)
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func presentOptionsMenu() {
        let menu = ConversationOptionsViewController(conversation: conversation, userSession: ZMUserSession.shared()!)
        navigationController?.pushViewController(menu, animated: true)
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        sections[indexPath.section].collectionView?(collectionView, didSelectItemAt: indexPath)
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

protocol ParticipantsSectionControllerDelegate: class {
    
    func presentDetailsView(for user: ZMUser)
    func presentOptionsMenu()
    
}

class DefaultSectionController: NSObject, _CollectionViewSectionController {
    
    var sectionTitle: String {
        return ""
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
        return CGSize(width: collectionView.bounds.size.width, height: 64)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fatal("Must be overridden")
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatal("Must be overridden")
    }
    
}

class ParticipantsSectionController: DefaultSectionController {
    
    private weak var delegate: ParticipantsSectionControllerDelegate?
    private let participants: [ZMBareUser]
    
    init(participants: [ZMBareUser], delegate: ParticipantsSectionControllerDelegate) {
        self.participants = participants
        self.delegate = delegate
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
        cell.separator.isHidden = (participants.count - 1) == indexPath.row
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let user = participants[indexPath.row] as? ZMUser else { return }
        delegate?.presentDetailsView(for: user)
    }
    
}

class ServicesSectionController: DefaultSectionController {
    
    private weak var delegate: ParticipantsSectionControllerDelegate?
    private let serviceUsers: [ZMBareUser]
    
    init(serviceUsers: [ZMBareUser], delegate: ParticipantsSectionControllerDelegate) {
        self.serviceUsers = serviceUsers
        self.delegate = delegate
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
        cell.separator.isHidden = (serviceUsers.count - 1) == indexPath.row
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let user = serviceUsers[indexPath.row] as? ZMUser else { return }
        delegate?.presentDetailsView(for: user)
    }
    
}

class GuestOptionsSection: DefaultSectionController {

    private weak var delegate: ParticipantsSectionControllerDelegate?
    private let conversation: ZMConversation
    
    init(conversation: ZMConversation, delegate: ParticipantsSectionControllerDelegate) {
        self.delegate = delegate
        self.conversation = conversation
    }
    
    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        collectionView?.register(GroupDetailsGuestOptionsCell.self, forCellWithReuseIdentifier: GroupDetailsGuestOptionsCell.zm_reuseIdentifier)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 32)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupDetailsGuestOptionsCell.zm_reuseIdentifier, for: indexPath) as! GroupDetailsGuestOptionsCell
        cell.isOn = conversation.allowGuests
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.presentOptionsMenu()
    }
    
}

class RenameSectionController: NSObject, _CollectionViewSectionController {
    
    fileprivate var validName : String? = nil
    fileprivate var conversation: ZMConversation
    fileprivate var renameCell : GroupDetailsRenameCell?
    
    init(conversation: ZMConversation) {
        self.conversation = conversation
    }
    
    func focus() {
        renameCell?.titleTextField.becomeFirstResponder()
    }
    
    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView?.register(GroupDetailsRenameCell.self, forCellWithReuseIdentifier: GroupDetailsRenameCell.zm_reuseIdentifier)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupDetailsRenameCell.zm_reuseIdentifier, for: indexPath) as! GroupDetailsRenameCell
        cell.titleTextField.text = conversation.displayName
        cell.titleTextField.textFieldDelegate = self
        renameCell = cell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        focus()
    }
    
}

extension RenameSectionController: SimpleTextFieldDelegate {
    
    func textFieldReturnPressed(_ textField: SimpleTextField) {
        guard let value = textField.value else { return }
        
        switch  value {
        case .valid(let name):
            validName = name
            textField.endEditing(true)
        case .error:
            // TODO show error
            textField.endEditing(true)
        }
    }
    
    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value) {
        
    }
    
    func textFieldDidEndEditing(_ textField: SimpleTextField) {
        if let newName = validName {
            ZMUserSession.shared()?.enqueueChanges {
                self.conversation.userDefinedName = newName
            }
        } else {
            textField.text = conversation.displayName
        }
    }
    
}
