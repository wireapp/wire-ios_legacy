//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import Cartography
import Classy

class SearchResultsView : UIView {
    
    let emptyResultContainer = UIView()
    let collectionView : UICollectionView
    let collectionViewLayout : UICollectionViewFlowLayout
    let accessoryContainer = UIView()
    var lastLayoutBounds : CGRect = CGRect.zero
    var accessoryViewBottomOffsetConstraint : NSLayoutConstraint?
    var isContainedInPopover : Bool = false
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    init() {
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumInteritemSpacing = 12
        collectionViewLayout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.allowsMultipleSelection = true
        collectionView.keyboardDismissMode = .onDrag
        collectionView.bounces = true
        collectionView.alwaysBounceVertical = true
        
        super.init(frame: CGRect.zero)
        
        [emptyResultContainer, collectionView, accessoryContainer].forEach(addSubview)
        
        createConstraints()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameDidChange(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createConstraints() {
        constrain(self, collectionView, accessoryContainer, emptyResultContainer) { container, collectionView, accessoryContainer, emptyResultContainer in
            
            collectionView.top == container.top
            collectionView.left == container.left
            collectionView.right == container.right
            
            accessoryContainer.top == collectionView.bottom
            accessoryContainer.left == container.left
            accessoryContainer.right == container.right
            accessoryViewBottomOffsetConstraint = accessoryContainer.bottom == container.bottom
            
            emptyResultContainer.top == container.top + 64
            emptyResultContainer.centerX == container.centerX
            emptyResultContainer.leading >= container.leading
            emptyResultContainer.trailing <= container.trailing
        }
    }
    
    override func layoutSubviews() {
        if !lastLayoutBounds.equalTo(bounds) {
            collectionView.collectionViewLayout.invalidateLayout()
        }
        
        lastLayoutBounds = bounds
        
        super.layoutSubviews()
    }
    
    var accessoryView : UIView? {
        didSet {
            guard oldValue != accessoryView else { return }
            
            oldValue?.removeFromSuperview()
            
            if let accessoryView = accessoryView {
                accessoryContainer.addSubview(accessoryView)
                
                constrain(accessoryContainer, accessoryView) { container, accessoryView in
                    accessoryView.edges == container.edges
                }
            }
        }
    }
    
    var emptyResultView : UIView? {
        didSet {
            guard oldValue != emptyResultView else { return }
            
            oldValue?.removeFromSuperview()
            
            if let emptyResultView = emptyResultView {
                emptyResultContainer.addSubview(emptyResultView)
                
                constrain(emptyResultContainer, emptyResultView) { container, emptyResultView in
                    emptyResultView.edges == container.edges
                }
            }
        }
    }
    
    func keyboardFrameDidChange(notification: Notification) {
        guard !isContainedInPopover else {
            return
        }
        
        let firstResponder = UIResponder.wr_currentFirst()
        let inputAccessoryHeight = firstResponder?.inputAccessoryView?.bounds.size.height ?? 0
        
        UIView.animate(withKeyboardNotification: notification, in: self, animations: { (keyboardFrameInView) in
            let keyboardHeight = keyboardFrameInView.size.height - inputAccessoryHeight
            self.accessoryViewBottomOffsetConstraint?.constant = -keyboardHeight
            self.layoutIfNeeded()
        }, completion: nil)
    }
    
}
