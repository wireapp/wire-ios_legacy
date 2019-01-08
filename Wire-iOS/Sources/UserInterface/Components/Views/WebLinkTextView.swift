//
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

import UIKit


// This subclass is used for the legal text in the Welcome screen and the reset password text in the login screen
// Purpose of this class is to reduce the amount of duplicate code to set the default properties of this NSTextView. On the Mac client we are using something similar to also stop the user from being able to select the text (selection property needs to be enabled to make the NSLinkAttribute work on the string). We may want to add this in the future here as well
@objc final class WebLinkTextView: UITextView {

    var heightConstraint: NSLayoutConstraint!

    init() {
        super.init(frame: .zero, textContainer: nil)

        setupWebLinkTextView()

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupWebLinkTextView() {
        isSelectable = true
        isEditable = false
        isScrollEnabled = false
        bounces = false
        backgroundColor = UIColor.clear
        textContainerInset = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)

        setupConstraints()
    }


    override public var attributedText: NSAttributedString? {
        get {
            return super.attributedText
        }

        set {
            super.attributedText = newValue

            let size = sizeThatFits(CGSize(width: frame.size.width, height: UIView.noIntrinsicMetric))

            heightConstraint.constant = size.height
        }
    }

    private func setupConstraints() {
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([heightConstraint])
    }
}
