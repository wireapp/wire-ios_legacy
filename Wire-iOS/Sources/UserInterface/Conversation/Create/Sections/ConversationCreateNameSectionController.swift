////
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
import WireDataModel

class ConversationCreateNameSectionController: NSObject, CollectionViewSectionController {
    
    typealias Cell = ConversationCreateNameCell
    
    var isHidden: Bool {
        return false
    }
    
    var value: SimpleTextField.Value? {
        return nameCell?.textField.value
    }
    
    private weak var nameCell: Cell?
    private weak var textFieldDelegate: SimpleTextFieldDelegate?
    private var footer = SectionFooter(frame: .zero)
    
    private lazy var footerText: String = {
        return "participants.section.name.footer".localized(args: ZMConversation.maxParticipants)
    }()
    
    init(delegate: SimpleTextFieldDelegate? = nil) {
        textFieldDelegate = delegate
    }
    
    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView.flatMap(Cell.register)
        collectionView?.register(SectionFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "SectionFooter")
    }
    
    func becomeFirstResponder() {
        nameCell?.textField.becomeFirstResponder()
    }
    
    func resignFirstResponder() {
        nameCell?.textField.resignFirstResponder()
    }
}

extension ConversationCreateNameSectionController {
    
    func collectionView(_ collectionView: UICollectionView,numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: Cell.self, for: indexPath)
        cell.textField.textFieldDelegate = textFieldDelegate
        nameCell = cell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "SectionFooter", for: indexPath)
        (view as? SectionFooter)?.titleLabel.text = footerText
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard ZMUser.selfUser().hasTeam else { return .zero }
        footer.titleLabel.text = footerText
        footer.size(fittingWidth: collectionView.bounds.width)
        return footer.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        nameCell?.textField.becomeFirstResponder()
    }
}
