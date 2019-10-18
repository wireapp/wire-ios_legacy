
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
import DifferenceKit

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
        view.setNeedsLayout()
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

    /// ensures that the list selection state matches that of the model.
    func ensureCurrentSelection() {
        guard let selectedItem = listViewModel.selectedItem else { return }

        let selectedIndexPaths = collectionView.indexPathsForSelectedItems

        if let currentIndexPath = listViewModel.indexPath(for: selectedItem) {
            if selectedIndexPaths?.contains(currentIndexPath) == false {
                // This method doesn't trigger any delegate callbacks, so no worries about special handling
                collectionView.selectItem(at: currentIndexPath, animated: false, scrollPosition: [])
            }
        } else {
            // Current selection is no longer available so we should unload the conversation view
            listViewModel.select(itemToSelect: nil)
        }
    }

    @objc(scrollToCurrentSelectionAnimated:)
    func scrollToCurrentSelection(animated: Bool) {
        guard let selectedItem = listViewModel.selectedItem,
            let selectedIndexPath = listViewModel.indexPath(for: selectedItem),
            // Check if indexPath is valid for the collection view
            collectionView.numberOfSections > selectedIndexPath.section,
            collectionView.numberOfItems(inSection: selectedIndexPath.section) > selectedIndexPath.item else {
            return
        }

        if !collectionView.indexPathsForVisibleItems.contains(selectedIndexPath) {
            collectionView.scrollToItem(at: selectedIndexPath, at: [], animated: animated)
        }
    }

    func selectInboxAndFocus(onView focus: Bool) -> Bool {
        // If there is anything in the inbox, select it
        if listViewModel.numberOfItems(inSection: 0) > 0 {

            focusOnNextSelection = focus
            selectModelItem(ConversationListViewModel.contactRequestsItem)
            return true
        }
        return false
    }

    func deselectAll() {
        selectModelItem(nil)
    }

    func select(_ conversation: ZMConversation?, scrollTo message: ZMConversationMessage?, focusOnView focus: Bool, animated: Bool, completion: Completion?) -> Bool {
        focusOnNextSelection = focus
        
        selectConversationCompletion = completion
        animateNextSelection = animated
        scrollToMessageOnNextSelection = message
        
        // Tell the model to select the item
        return selectModelItem(conversation)
    }
    
    ///TODO: change type to ConvListItem after converted all callers to Swift
    @discardableResult
    @objc
    func selectModelItem(_ itemToSelect: AnyHashable?) -> Bool {
        return listViewModel.select(itemToSelect: itemToSelect)
    }
    
    // MARK: - UICollectionViewDelegate

    
    override open func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        selectionFeedbackGenerator.selectionChanged()
        
        let item = listViewModel.item(for: indexPath)
        
        focusOnNextSelection = true
        animateNextSelection = true
        selectModelItem(item)
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

        (cell as? SectionListCellType)?.sectionName = listViewModel.sectionCanonicalName(of: indexPath.section)

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

extension ConversationListContentController: ConversationListViewModelDelegate {

    func listViewModel(_ model: ConversationListViewModel?, didSelectItem item: ConversationListItem?) {
        defer {
            scrollToMessageOnNextSelection = nil
            focusOnNextSelection = false
        }

        guard let item = item else {
            // Deselect all items in the collection view
            let indexPaths = collectionView.indexPathsForSelectedItems
            (indexPaths as NSArray?)?.enumerateObjects({ obj, idx, stop in
                if let obj = obj as? IndexPath {
                    self.collectionView.deselectItem(at: obj, animated: false)
                }
            })
            ZClientViewController.shared()?.loadPlaceholderConversationController(animated: true)
            ZClientViewController.shared()?.transitionToList(animated: true, completion: nil)

            return
        }

        if let conversation = item as? ZMConversation {

            // Actually load the new view controller and optionally focus on it
            ZClientViewController.shared()?.load(conversation, scrollTo: scrollToMessageOnNextSelection, focusOnView: focusOnNextSelection, animated: animateNextSelection, completion: selectConversationCompletion)
            selectConversationCompletion = nil

            contentDelegate?.conversationList(self, didSelect: conversation, focusOnView: !focusOnNextSelection)
        } else if (item is ConversationListConnectRequestsItem) {
            ZClientViewController.shared()?.loadIncomingContactRequestsAndFocus(onView: focusOnNextSelection, animated: true)
        } else {
            assert(false, "Invalid item in conversation list view model!!")
        }
        // Make sure the correct item is selected in the list, without triggering a collection view
        // callback
        ensureCurrentSelection()
    }


    func listViewModelShouldBeReloaded() {
        reload()
    }

    func listViewModel(_ model: ConversationListViewModel?, didUpdateSectionForReload section: Int, animated: Bool) {
        // do not reload if section is not visible
        guard collectionView.indexPathsForVisibleItems.map({$0.section}).contains(section) else { return }

        let reloadClosure = {
            self.collectionView.reloadSections(IndexSet(integer: section))
            self.ensureCurrentSelection()
        }

        if animated {
            reloadClosure()
        } else {
            UIView.performWithoutAnimation {
                reloadClosure()
            }
        }
    }

    func listViewModel(_ model: ConversationListViewModel?, didChangeFolderEnabled folderEnabled: Bool) {
        collectionView.accessibilityValue = folderEnabled ? "folders" : "recent"
    }

    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        setData: (C?) -> Void
        ) {
        collectionView.reload(using: stagedChangeset, interrupt: interrupt, setData: setData)
    }
}

extension ConversationListContentController: UIViewControllerPreviewingDelegate {
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        guard let previewViewController = viewControllerToCommit as? ConversationPreviewViewController else { return }
        
        focusOnNextSelection = true
        animateNextSelection = true
        selectModelItem(previewViewController.conversation)
    }
    
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView.indexPathForItem(at: location),
              let layoutAttributes = collectionView.layoutAttributesForItem(at: indexPath),
              let conversation = listViewModel.item(for: indexPath) as? ZMConversation else {
            return nil
        }
        
        previewingContext.sourceRect = layoutAttributes.frame
        
        return ConversationPreviewViewController(conversation: conversation, presentingViewController: self)
    }

}
