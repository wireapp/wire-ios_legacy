
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

        listViewModel = ConversationListViewModel() ///TODO: inject session
        listViewModel.delegate = self
        setupViews()

        if UIApplication.shared.keyWindow?.traitCollection.forceTouchCapability == .available {

            registerForPreviewing(with: self, sourceView: collectionView)
        }
    }

    // MARK: - section header

    open override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        switch (kind) {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ConversationListHeaderView.reuseIdentifier, for: indexPath) as! ConversationListHeaderView
            header.desiredWidth = collectionView.frame.width
            header.desiredHeight = sectionHeaderHeight(indexPath: indexPath)
            header.titleLabel.text = listViewModel.sectionHeaderTitle(sectionIndex: indexPath.section)

            return header
        default:
            fatal("No supplementary view for \(kind)")
        }
    }

    @objc
    func registerSectionHeader() {
        collectionView?.register(ConversationListHeaderView.self, forSupplementaryViewOfKind:
            UICollectionView.elementKindSectionHeader, withReuseIdentifier: ConversationListHeaderView.reuseIdentifier)

    }

    var headerDesiredHeight: CGFloat {
        return listViewModel.folderEnabled ? 48:0
    }

    func sectionHeaderHeight(indexPath: IndexPath? = nil) -> CGFloat {
        guard let indexPath = indexPath else {
            return headerDesiredHeight
        }

        return listViewModel.numberOfItems(inSection: UInt(indexPath.section)) <= 0 ? 0 : headerDesiredHeight
    }

    @objc
    func updateSectionHeaderHeight() {
        (collectionView.collectionViewLayout as? BoundsAwareFlowLayout)?.headerReferenceSize = CGSize(width: collectionView.frame.size.width, height: headerDesiredHeight)
    }

    @objc
    func refresh() {
        collectionView.reloadData()
        ensureCurrentSelection()

        updateSectionHeaderHeight()

        // we MUST call layoutIfNeeded here because otherwise bad things happen when we close the archive, reload the conv
        // and then unarchive all at the same time
        view.layoutIfNeeded()
    }
}

final class ConversationListHeaderView: UICollectionReusableView {
    var desiredWidth: CGFloat = 0
    var desiredHeight: CGFloat = 0

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .smallSemiboldFont ///TODO: define style
        label.textColor = .white

        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)

        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                                     titleLabel.topAnchor.constraint(equalTo: topAnchor),
                                     titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
                                     titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)])
    }

    override public var intrinsicContentSize: CGSize {
        get {
            return CGSize(width: desiredWidth,
                          height: desiredHeight)
        }
    }
}

