//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

final class NetworkConditionIndicatorView: UIView, RoundedViewProtocol {

    private let label = UILabel()

    public override class var layerClass: AnyClass {
        return ContinuousMaskLayer.self
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 32)
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.nameColor(for: .brightOrange, variant: .light)
        shape = .relative(multiplier: 1, dimension: .height)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.firstBaselineAnchor.constraint(equalTo: centerYAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
        backgroundColor = UIColor.nameColor(for: .brightOrange, variant: .light)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var networkQuality: NetworkQuality = .normal {
        didSet {
            label.attributedText = networkQuality.attributedString(color: .white)
            layoutIfNeeded()
        }
    }
}
