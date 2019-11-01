
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension UIView {
    func rotate(to angleInDegrees: CGFloat) {
        transform = transform.rotated(by: angleInDegrees / 180 * CGFloat.pi)
    }
}

typealias TapHandler = (_ collapsed: Bool) -> Void

final class ConversationListHeaderView: UICollectionReusableView {
    var collapsed = false {
        didSet {
            guard collapsed != oldValue else { return }
            // update rotation
            
            if collapsed {
                arrowIconImageView.rotate(to: -90)
            } else {
                arrowIconImageView.transform = .identity
            }
        }
    }
    
    var tapHandler: TapHandler? = nil

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .smallRegularFont
        label.textColor = .white
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        return label
    }()

    /// display title of the header
    var title: String? {
        set {
            titleLabel.text = newValue
        }

        get {
            return titleLabel.text
        }
    }

    override var accessibilityLabel: String? {
        get {
            return title
        }

        set {
            //no op
        }
    }

    override var accessibilityValue: String? {
        get {
            return collapsed ? "collapsed" : "expanded"
        }

        set {
            //no op
        }
    }

    private let arrowIconImageView: UIImageView = {
        let image = StyleKitIcon.downArrow.makeImage(size: 10, color: .white)
        
        let imageView = UIImageView(image: image)
        
        return imageView
    }()

    required override init(frame: CGRect) {
        super.init(frame: frame)

        [titleLabel, arrowIconImageView].forEach(addSubview)

        createConstraints()
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggledCollapsed)))

        isAccessibilityElement = true
        shouldGroupAccessibilityChildren = true
    }
    
    @objc
    private func toggledCollapsed() {
        let newCollaped = !collapsed

        UIView.animate(withDuration: 0.2, animations: {
            self.collapsed = newCollaped
             })
        tapHandler?(newCollaped)
    }


    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        [arrowIconImageView, titleLabel].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        arrowIconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let spacing: CGFloat = 8

        NSLayoutConstraint.activate([
            arrowIconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CGFloat.ConversationList.horizontalMargin),
            arrowIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: arrowIconImageView.trailingAnchor, constant: spacing),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -spacing)]
        )
    }
}
