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
import WireCommonComponents

class RoundedPageIndicator: RoundedBlurView {
    private let selectedPageIndicator = UIImage.circle(filled: true)
    private let defaultPageIndicator = UIImage.circle(filled: false)
    let pageControl = UIPageControl()

    override func setupViews() {
        super.setupViews()
        isHidden = true
        setCornerRadius(12)
        clipsToBounds = true

        addSubview(pageControl)
        pageControl.currentPageIndicatorTintColor = .accent()

        if DeveloperFlag.isUpdatedCallingUI {
            backgroundColor = SemanticColors.View.borderInputBar
            pageControl.pageIndicatorTintColor = SemanticColors.Switch.borderOffStateEnabled
            blurView.isHidden = true
            if #available(iOS 14.0, *) {
                pageControl.preferredIndicatorImage = defaultPageIndicator
            }
        }

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
            currentPage = 0
        }
    }

    var currentPage: Int = 0 {
        didSet {
            pageControl.currentPage = currentPage
            if #available(iOS 14.0, *), DeveloperFlag.isUpdatedCallingUI {
                guard numberOfPages > 0 else { return }
                let lastPageIndex = numberOfPages - 1
                for index in 0...lastPageIndex {
                    pageControl.setIndicatorImage(defaultPageIndicator, forPage: index)
                }
                pageControl.setIndicatorImage(selectedPageIndicator, forPage: currentPage)
            }
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

private extension UIImage {

    class func circle(filled: Bool) -> UIImage? {
        let size = CGSize(width: 12, height: 12)
        let lineWidth = 1.0

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
                return nil
        }
        if filled {
            context.setFillColor(UIColor.black.cgColor)
        } else {
            context.setStrokeColor(UIColor.black.cgColor)
        }
        context.setLineWidth(lineWidth)
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: lineWidth * 0.5, dy: lineWidth * 0.5)
        context.addEllipse(in: rect)
        if filled {
            context.fillPath()
        } else {
            context.strokePath()
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
