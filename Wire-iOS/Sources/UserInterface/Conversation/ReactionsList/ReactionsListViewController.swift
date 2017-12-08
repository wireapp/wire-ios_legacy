//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireSyncEngine
import Cartography
import Classy

@objc open class ReactionsListViewController: UIViewController {
    open let message: ZMConversationMessage
    open let reactionsUsers: [ZMUser]
    fileprivate let collectionViewLayout = UICollectionViewFlowLayout()
    fileprivate var collectionView: UICollectionView!
    fileprivate let topBar: ModalTopBar
    open let dismissButton = IconButton.iconButtonDefault()
    open let titleLabel = UILabel()
    
    public init(message: ZMConversationMessage, showsStatusBar: Bool) {
        self.message = message
        topBar = ModalTopBar(forUseWithStatusBar: showsStatusBar)
        self.reactionsUsers = self.message.likers()
        super.init(nibName: .none, bundle: .none)
        self.modalPresentationStyle = .formSheet
        topBar.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "content.reactions_list.likers".localized.uppercased()
        self.topBar.title = self.title
        
        self.collectionViewLayout.scrollDirection = .vertical
        self.collectionViewLayout.minimumLineSpacing = 0
        self.collectionViewLayout.minimumInteritemSpacing = 0
        self.collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        self.collectionView.register(ReactionCell.self, forCellWithReuseIdentifier: ReactionCell.reuseIdentifier)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.allowsSelection = true
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.isScrollEnabled = true
        self.collectionView.backgroundColor = UIColor.clear
        self.view.addSubview(self.collectionView)
        self.view.addSubview(self.topBar)
        
        constrain(self.view, self.collectionView, self.topBar) { selfView, collectionView, topBar in
            topBar.top == selfView.top
            topBar.left == selfView.left
            topBar.right == selfView.right

            collectionView.left == selfView.left
            collectionView.right == selfView.right
            collectionView.bottom == selfView.bottom
            collectionView.top == topBar.bottom
        }

        CASStyler.default().styleItem(self)
    }
    
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return self.wr_supportedInterfaceOrientations
    }
}

extension ReactionsListViewController: ModalTopBarDelegate {
    public func modelTopBarWantsToBeDismissed(_ topBar: ModalTopBar) {
        dismiss(animated: true, completion: .none)
    }
}

extension ReactionsListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.reactionsUsers.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReactionCell.reuseIdentifier, for: indexPath) as! ReactionCell
        cell.user = self.reactionsUsers[indexPath.item]
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 52)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}
