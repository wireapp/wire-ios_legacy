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

public struct AudioEffectCellBorders : OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let None   = AudioEffectCellBorders(rawValue: 0)
    public static let Right  = AudioEffectCellBorders(rawValue: 1 << 0)
    public static let Bottom = AudioEffectCellBorders(rawValue: 1 << 1)
}

@objc public final class AudioEffectCell: UICollectionViewCell {
    fileprivate let iconView = IconButton()
    fileprivate let borderRightView = UIView()
    fileprivate let borderBottomView = UIView()
    
    public var borders: AudioEffectCellBorders = [.None] {
        didSet {
            self.updateBorders()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        self.contentView.backgroundColor = UIColor.clear
        self.clipsToBounds = false
        
        self.iconView.isUserInteractionEnabled = false
        [self.iconView, self.borderRightView, self.borderBottomView].forEach(self.contentView.addSubview)

        [self.borderRightView, self.borderBottomView].forEach { v in
            v.backgroundColor = UIColor(white: 1, alpha: 0.16)
        }
        
        constrain(self.contentView, self.iconView) { contentView, iconView in
            iconView.edges == contentView.edges
        }
        
        constrain(self.contentView, self.borderRightView, self.borderBottomView) { contentView, borderRightView, borderBottomView in

            borderRightView.bottom == contentView.bottom
            borderRightView.top == contentView.top
            borderRightView.right == contentView.right + 0.5
            borderRightView.width == 0.5
            
            borderBottomView.left == contentView.left
            borderBottomView.bottom == contentView.bottom + 0.5
            borderBottomView.right == contentView.right
            borderBottomView.height == 0.5
        }
        
        self.updateForSelectedState()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static let reuseIdentifier: String = "AudioEffectCell"
    
    public override var reuseIdentifier: String? {
        get {
            return type(of: self).reuseIdentifier
        }
    }
    
    override public var isSelected: Bool {
        didSet {
            self.updateForSelectedState()
        }
    }
    
    fileprivate func updateBorders() {
        self.borderRightView.isHidden = !self.borders.contains(.Right)
        self.borderBottomView.isHidden = !self.borders.contains(.Bottom)
    }
    
    fileprivate func updateForSelectedState() {
        self.iconView.setIconColor(self.isSelected ? UIColor.accentColor : UIColor.white, for: .normal)
    }
    
    public var effect: AVSAudioEffectType = .none {
        didSet {
            self.iconView.setIcon(icon: effect.icon, with: .small, for: .normal)
            self.accessibilityLabel = effect.description
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.effect = .none
        self.borders = .None
        self.updateForSelectedState()
    }
}
