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

import Foundation
import UIKit
import WireDataModel
import WireSyncEngine

final class RenameGroupSectionController: NSObject, CollectionViewSectionController {
    
    fileprivate var validName: String? = nil
    fileprivate var conversation: ZMConversation
    fileprivate var renameCell: GroupDetailsRenameCell?
    fileprivate var token: AnyObject?
    private var sizingFooter = SectionFooter(frame: .zero)
    
    var isHidden: Bool {
        return false
    }
    
    init(conversation: ZMConversation) {
        self.conversation = conversation
        super.init()
        self.token = ConversationChangeInfo.add(observer: self, for: conversation)
    }
    
    func focus() {
        guard conversation.isSelfAnActiveMember else { return }
        renameCell?.titleTextField.becomeFirstResponder()
    }
    
    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView.flatMap(GroupDetailsRenameCell.register)
        collectionView?.register(SectionFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "SectionFooter")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: GroupDetailsRenameCell.self, for: indexPath)
        cell.configure(for: conversation, editable: ZMUser.selfUser()?.canModifyTitle(in: conversation) ?? false)
        cell.titleTextField.textFieldDelegate = self
        renameCell = cell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "SectionFooter", for: indexPath)
        (view as? SectionFooter)?.titleLabel.text = "participants.section.name.footer".localized(args: ZMConversation.maxParticipants)
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard ZMUser.selfUser().hasTeam else { return .zero }
        sizingFooter.titleLabel.text = "participants.section.name.footer".localized(args: ZMConversation.maxParticipants)
        sizingFooter.size(fittingWidth: collectionView.bounds.width)
        return sizingFooter.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        focus()
    }
    
}

extension RenameGroupSectionController : ZMConversationObserver {
    
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard changeInfo.securityLevelChanged || changeInfo.nameChanged else { return }
        
        renameCell?.configure(for: conversation, editable: ZMUser.selfUser()?.canModifyTitle(in: conversation) ?? false)
    }
    
}

extension RenameGroupSectionController: SimpleTextFieldDelegate {
    
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
    
    func textFieldDidBeginEditing(_ textField: SimpleTextField) {
        renameCell?.accessoryIconView.isHidden = true
    }
    
    func textFieldDidEndEditing(_ textField: SimpleTextField) {
        if let newName = validName {
            ZMUserSession.shared()?.enqueue {
                self.conversation.userDefinedName = newName
            }
        } else {
            textField.text = conversation.displayName
        }
        
        renameCell?.accessoryIconView.isHidden = false
    }
    
}
