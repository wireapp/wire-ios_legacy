//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

class BorderedPageControl: UIPageControl {
    let selectedPageIndicator = UIImage.circle(size: CGSize(width: 12, height: 12), color: .accent(), filled: true)
    let defaultPageIndicator = UIImage.circle(size: CGSize(width: 12, height: 12), color: .accent(), filled: false)

    override var currentPage: Int {
        didSet {
            if #available(iOS 14.0, *) {
                guard numberOfPages > 0 else { return }
                let lastPageIndex = numberOfPages - 1
                for index in 0...lastPageIndex {
                    setIndicatorImage(defaultPageIndicator, forPage: index)
                }
                setIndicatorImage(selectedPageIndicator, forPage: currentPage)
            }
        }
    }

    override var numberOfPages: Int {
        didSet {
            currentPage = 0
        }
    }

    init() {
        super.init(frame: .zero)
        if #available(iOS 14.0, *) {
            preferredIndicatorImage = defaultPageIndicator
        }
        self.pageIndicatorTintColor = SemanticColors.Switch.borderOffStateEnabled
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension UIImage {

    class func circle(size: CGSize, color: UIColor, filled: Bool) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
                return nil
        }
        let lineWidth = 1.0
        if filled {
            context.setFillColor(color.cgColor)
        } else {
            context.setStrokeColor(color.cgColor)
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
