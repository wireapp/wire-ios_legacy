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
import UIKit

@objcMembers
final class SketchColorCollectionViewCell: UICollectionViewCell {
    var sketchColor: UIColor? {
        didSet {
            if sketchColor == oldValue {
                return
            }

            if let sketchColor = sketchColor {
                knobView.knobColor = sketchColor
            }
        }
    }

    var brushWidth: Int = 0 {
        didSet {
            if brushWidth == oldValue {
                return
            }

            knobView.knobDiameter = CGFloat(brushWidth)
            knobView.setNeedsLayout()
        }
    }

    override var isSelected: Bool {
        didSet {
            knobView.knobColor = sketchColor
            knobView.isSelected = isSelected
        }
    }

    private var knobView: ColorKnobView!
    private var initialContraintsCreated = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        knobView = ColorKnobView()
        addSubview(knobView)

        brushWidth = 6

        setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        if initialContraintsCreated {
            return
        }

        knobView.centerInSuperview()
        knobView.setDimensions(length: 25)

        initialContraintsCreated = true
    }
}
