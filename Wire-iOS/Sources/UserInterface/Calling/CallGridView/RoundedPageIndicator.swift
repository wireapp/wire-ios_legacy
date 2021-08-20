//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import UIKit

class RoundedPageIndicator: RoundedBlurView {
    let pageControl = UIPageControl()

    override func setupViews() {
        super.setupViews()
        isHidden = true
        setCornerRadius(12)
        clipsToBounds = true

        addSubview(pageControl)
        pageControl.currentPageIndicatorTintColor = .accent()

        if #available(iOS 14.0, *) {
            pageControl.backgroundStyle = .minimal
            pageControl.allowsContinuousInteraction = false
        }
    }

    override func createConstraints() {
        super.createConstraints()
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pageControl.centerYAnchor.constraint(equalTo: centerYAnchor),
            pageControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -CGFloat.pageControlMargin),
            pageControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CGFloat.pageControlMargin)
        ])
    }

    var numberOfPages: Int = 0 {
        didSet {
            pageControl.numberOfPages = numberOfPages
            isHidden = numberOfPages <= 1
        }
    }

    var currentPage: Int = 0 {
        didSet {
            pageControl.currentPage = currentPage
        }
    }

    override var accessibilityIdentifier: String? {
        get { "\(String(describing: self)).\(currentPage)" }
        set {}
    }
}

private extension CGFloat {
    static let pageControlMargin: CGFloat = 10
}
