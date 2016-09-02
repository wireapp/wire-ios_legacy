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
import zmessaging
import Cartography

@objc public class ReactionsListViewController: UIViewController {
    public let message: ZMMessage
    public let reactionsUsers: [ZMUser]
    private let collectionViewLayout = UICollectionViewFlowLayout()
    private var collectionView: UICollectionView!
    public let topBar = UIView()
    public let separatorView = UIView()
    public let dismissButton = IconButton.iconButtonDefault()
    public let titleLabel = UILabel()
    
    public init(message: ZMMessage) {
        self.message = message

        self.reactionsUsers = self.message.likers()
        super.init(nibName: .None, bundle: .None)
        self.modalPresentationStyle = UIModalPresentationStyle.FormSheet
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "content.reactions_list.likers".localized.uppercaseString
        self.titleLabel.text = self.title
        
        self.separatorView.cas_styleClass = "separator"
        
        dismissButton.setIcon(.X, withSize: .Tiny, forState: .Normal)
        dismissButton.addTarget(self, action: #selector(dismissPressed), forControlEvents: .TouchUpInside)
        dismissButton.accessibilityIdentifier = "BackButton"
        dismissButton.hitAreaPadding = CGSizeMake(20, 20)
        
        self.collectionViewLayout.scrollDirection = .Vertical
        self.collectionViewLayout.minimumLineSpacing = 0
        self.collectionViewLayout.minimumInteritemSpacing = 0
        self.collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: collectionViewLayout)
        self.collectionView.registerClass(ReactionCell.self, forCellWithReuseIdentifier: ReactionCell.reuseIdentifier)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.allowsSelection = true
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.scrollEnabled = true
        self.collectionView.backgroundColor = UIColor.clearColor()
        self.view.addSubview(self.collectionView)
        
        self.topBar.addSubview(titleLabel)
        self.topBar.addSubview(separatorView)
        self.topBar.addSubview(dismissButton)
        self.view.addSubview(self.topBar)
        
        constrain(self.view, self.collectionView, self.topBar) { selfView, collectionView, topBar in
            topBar.top == selfView.top + 20
            topBar.left == selfView.left
            topBar.right == selfView.right
            topBar.height == 44
        
            collectionView.left == selfView.left
            collectionView.right == selfView.right
            collectionView.bottom == selfView.bottom
            collectionView.top == topBar.bottom
        }
        
        constrain(self.topBar, self.titleLabel, self.dismissButton, self.separatorView) { topBar, titleLabel, dismissButton, separatorView in
            separatorView.bottom == topBar.bottom
            separatorView.right == topBar.right
            separatorView.left == topBar.left
            separatorView.height == 1

            titleLabel.center == topBar.center
            titleLabel.trailing <= dismissButton.leading - 4
            
            dismissButton.centerY == topBar.centerY
            dismissButton.trailing == topBar.trailing - 16
        }
        
        CASStyler.defaultStyler().styleItem(self)
    }
    
    @objc public func dismissPressed(button: AnyObject!) {
        self.dismissViewControllerAnimated(true, completion: .None)
    }
}

extension ReactionsListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.reactionsUsers.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ReactionCell.reuseIdentifier, forIndexPath: indexPath) as! ReactionCell
        cell.user = self.reactionsUsers[indexPath.item]
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.bounds.width, 52)
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
}
