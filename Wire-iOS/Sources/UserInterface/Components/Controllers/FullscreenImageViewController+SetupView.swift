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

import Foundation

extension FullscreenImageViewController {
    @objc
    func setupSnapshotBackgroundView() {
        guard let snapshotBackgroundView = delegate?.backgroundScreenshot(for: self) else { return }

        snapshotBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(snapshotBackgroundView)

        let topBarHeight: CGFloat = navigationController?.navigationBar.frame.maxY ?? 0

        snapshotBackgroundView.pinToSuperview(anchor: .top, inset: topBarHeight)
        snapshotBackgroundView.pinToSuperview(anchor: .leading)
        snapshotBackgroundView.setDimensions(size: UIScreen.main.bounds.size)

        snapshotBackgroundView.alpha = 0

        self.snapshotBackgroundView = snapshotBackgroundView
    }

    @objc
    func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        scrollView.fitInSuperview()

        if #available(iOS 11, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        scrollView.delegate = self
        scrollView.accessibilityIdentifier = "fullScreenPage"

        animator = UIDynamicAnimator(referenceView: scrollView)
    }

}

