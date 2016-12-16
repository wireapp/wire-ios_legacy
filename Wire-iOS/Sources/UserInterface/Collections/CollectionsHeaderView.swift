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
import Cartography

@objc final public class CollectionsHeaderView: UICollectionReusableView, Reusable {
    
    public var section: CollectionsSectionSet = .none {
        didSet {
            switch(section) {
            case CollectionsSectionSet.images:
                self.titleLabel.text = "collections.section.images.title".localized.uppercased()
            case CollectionsSectionSet.filesAndAudio:
                self.titleLabel.text = "collections.section.files.title".localized.uppercased()
            case CollectionsSectionSet.videos:
                self.titleLabel.text = "collections.section.videos.title".localized.uppercased()
            case CollectionsSectionSet.links:
                self.titleLabel.text = "collections.section.links.title".localized.uppercased()
            default: fatal("Unknown section")
            }
        }
    }
    
    public var showActionButton: Bool = true {
        didSet {
            self.actionButton.isHidden = !self.showActionButton
        }
    }
    
    public let titleLabel = UILabel()
    public let actionButton = UIButton()
    
    public var selectionAction: ((CollectionsSectionSet) -> ())? = .none
    
    public required init(coder: NSCoder) {
        fatal("init(coder: NSCoder) is not implemented")
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.titleLabel)
        
        self.actionButton.contentHorizontalAlignment = .right
        self.actionButton.accessibilityLabel = "open all"
        self.actionButton.setTitle("collections.section.all.button".localized.uppercased(), for: .normal)
        self.actionButton.addTarget(self, action: #selector(CollectionsHeaderView.didSelect(_:)), for: .touchUpInside)
        self.addSubview(self.actionButton)
        
        constrain(self, self.titleLabel, self.actionButton) { selfView, titleLabel, actionButton in
            titleLabel.leading == selfView.leading + 16
            titleLabel.centerY == selfView.centerY
            titleLabel.trailing == selfView.trailing
            
            actionButton.leading == selfView.leading
            actionButton.top == selfView.top
            actionButton.trailing == selfView.trailing - 16
            actionButton.bottom == selfView.bottom
        }
    }
    
    public func didSelect(_ button: UIButton!) {
        self.selectionAction?(self.section)
    }
}
