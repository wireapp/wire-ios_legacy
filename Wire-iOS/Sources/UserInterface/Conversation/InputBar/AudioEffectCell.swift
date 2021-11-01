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
import avs

struct AudioEffectCellBorders: OptionSet {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let None   = AudioEffectCellBorders([])
    static let Right  = AudioEffectCellBorders(rawValue: 1 << 0)
    static let Bottom = AudioEffectCellBorders(rawValue: 1 << 1)
}

final class AudioEffectCell: UICollectionViewCell {
    fileprivate let iconView = IconButton()
    fileprivate let borderRightView = UIView()
    fileprivate let borderBottomView = UIView()

    var borders: AudioEffectCellBorders = [.None] {
        didSet {
            updateBorders()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        clipsToBounds = false

        iconView.isUserInteractionEnabled = false
        [iconView, borderRightView, borderBottomView].forEach(contentView.addSubview)

        [borderRightView, borderBottomView].forEach { v in
            v.backgroundColor = UIColor(white: 1, alpha: 0.16)
        }

        constrain(contentView, iconView) { contentView, iconView in
            iconView.edges == contentView.edges
        }

        constrain(contentView, borderRightView, borderBottomView) { contentView, borderRightView, borderBottomView in

            borderRightView.bottom == contentView.bottom
            borderRightView.top == contentView.top
            borderRightView.right == contentView.right + 0.5
            borderRightView.width == .hairline

            borderBottomView.left == contentView.left
            borderBottomView.bottom == contentView.bottom + 0.5
            borderBottomView.right == contentView.right
            borderBottomView.height == .hairline
        }

        updateForSelectedState()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            updateForSelectedState()
        }
    }

    fileprivate func updateBorders() {
        borderRightView.isHidden = !borders.contains(.Right)
        borderBottomView.isHidden = !borders.contains(.Bottom)
    }

    fileprivate func updateForSelectedState() {
        let color: UIColor = isSelected ? UIColor.accent() : UIColor.white
        iconView.setIconColor(color, for: .normal)
    }

    var effect: AVSAudioEffectType = .none {
        didSet {
            iconView.setIcon(effect.icon, size: .small, for: .normal)
            accessibilityLabel = effect.description
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        effect = .none
        borders = .None
        updateForSelectedState()
    }
}
