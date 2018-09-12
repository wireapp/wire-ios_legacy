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

extension NetworkCondition {
    func attributedString(color: UIColor) -> NSAttributedString? {
        switch self {
        case .medium, .poor:
            let attachment = NSTextAttachment()
            attachment.image = UIImage(for: .networkCondition, iconSize: .tiny, color: color)
            attachment.bounds = CGRect(x: 0.0, y: -4, width: attachment.image!.size.width, height: attachment.image!.size.height)
            let text = "Poor connection".uppercased()
            let attributedText = text.attributedString.adding(font: FontSpec(.small, .semibold).font!, to: text).adding(color: color, to: text)
            return NSAttributedString(attachment: attachment) + " " + attributedText
        case .normal:
            return nil
        }
    }
}

final class NetworkConditionIndicatorView: UIView, RoundedViewProtocol {

    private let label = UILabel()

    public override class var layerClass: AnyClass {
        return ContinuousMaskLayer.self
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 32)
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

    var networkCondition: NetworkCondition? {
        didSet {
            label.attributedText = networkCondition?.attributedString(color: .white)
            layoutIfNeeded()
        }
    }

}
