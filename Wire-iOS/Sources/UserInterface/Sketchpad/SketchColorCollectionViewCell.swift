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

final class SketchColorCollectionViewCell: UICollectionViewCell {
    var sketchColor: UIColor? {
        didSet {
            guard sketchColor != oldValue else {
                return
            }

            if let sketchColor = sketchColor {
                knobView.knobColor = sketchColor
            }
        }
    }

    var brushWidth: CGFloat = 6 {
        didSet {
            guard brushWidth != oldValue else {
                return
            }

            knobView.knobDiameter = brushWidth
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

        setNeedsUpdateConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        if initialContraintsCreated {
            return
        }

        knobView.translatesAutoresizingMaskIntoConstraints = false
        knobView.centerInSuperview()
        knobView.setDimensions(length: 25)

        initialContraintsCreated = true
    }
}
