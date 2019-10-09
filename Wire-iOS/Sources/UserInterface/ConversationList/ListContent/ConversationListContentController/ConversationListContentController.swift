
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

extension ConversationListContentController {
    override open func loadView() {
        super.loadView()

        layoutCell = ConversationListCell()

        listViewModel = ConversationListViewModel()
        listViewModel.delegate = self
        
        setupViews()

        if UIApplication.shared.keyWindow?.traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: collectionView)
        }
    }

    @objc
    func reload() {
        collectionView.reloadData()
        ensureCurrentSelection()

        // we MUST call layoutIfNeeded here because otherwise bad things happen when we close the archive, reload the conv
        // and then unarchive all at the same time
        view.layoutIfNeeded()
    }

    // MARK: - section header

    open override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ConversationListHeaderView.reuseIdentifier, for: indexPath) as? ConversationListHeaderView {
                header.title = listViewModel.sectionHeaderTitle(sectionIndex: indexPath.section)?.uppercased()

                header.collapsed = listViewModel.collapsed(at: indexPath.section)

                header.tapHandler = {[weak self] collapsed in
                    self?.listViewModel.setCollapsed(sectionIndex: indexPath.section, collapsed: collapsed)
                }
                
                return header
            } else {
                fatal("Unknown supplementary view for \(kind)")
            }
        default:
            fatal("No supplementary view for \(kind)")
        }
    }

    @objc
    func registerSectionHeader() {
        collectionView?.register(ConversationListHeaderView.self, forSupplementaryViewOfKind:
            UICollectionView.elementKindSectionHeader, withReuseIdentifier: ConversationListHeaderView.reuseIdentifier)

    }

    // MARK: - UICollectionViewDataSource

    override open func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = listViewModel.item(for: indexPath)
        let cell: UICollectionViewCell

        if item is ConversationListConnectRequestsItem,
            let labelCell = collectionView.dequeueReusableCell(withReuseIdentifier: CellReuseIdConnectionRequests, for: indexPath) as? ConnectRequestsCell {
            cell = labelCell
        } else if item is ZMConversation,
            let listCell = collectionView.dequeueReusableCell(withReuseIdentifier: CellReuseIdConversation, for: indexPath) as? ConversationListCell {

            listCell.delegate = self
            listCell.mutuallyExclusiveSwipeIdentifier = "ConversationList"
            listCell.conversation = item as? ZMConversation

            cell = listCell
        } else {
            fatal("Unknown cell type")
        }

        (cell as? SectionListCellType)?.sectionName = listViewModel.sectionName(of: indexPath.section)

        cell.autoresizingMask = .flexibleWidth

        return cell
    }


}


extension ConversationListContentController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: listViewModel.sectionHeaderVisible(section: section) ? CGFloat.ConversationListSectionHeader.height: 0)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return layoutCell.size(inCollectionViewSize: collectionView.bounds.size)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: section == 0 ? 12 : 0, left: 0, bottom: 0, right: 0)
    }
}
