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

extension FullscreenImageViewController {

    ///TODO: size class update

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard let imageSize = imageView.image?.size else { return }

        let isImageZoomed = scrollView.minimumZoomScale != scrollView.zoomScale
        updateScrollViewMinimumZoomScale(viewSize: size, imageSize: imageSize)
        
        coordinator.animate(alongsideTransition: { (context) in
            if isImageZoomed == false {
                self.scrollView.zoomScale = self.scrollView.minimumZoomScale
            }
        })
    }

    func calculateMinZoom(viewSize: CGSize, imageSize: CGSize?) -> CGFloat {
        guard let imageSize = imageSize else { return 1 }

        var minZoom = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)

        if minZoom > 1 {
            minZoom = 1
        }

        return minZoom
    }

    func updateScrollViewMinimumZoomScale(viewSize: CGSize, imageSize: CGSize) {
        self.scrollView.minimumZoomScale = calculateMinZoom(viewSize: viewSize, imageSize: imageSize)
    }

    func updateZoom() {
        guard let size = parent?.view?.frame.size else { return }
        updateZoom(withSize: size)
    }

    /// Zoom to show as much image as possible unless image is smaller than screen
    ///
    /// - Parameter size: size of the view which contains imageView
    func updateZoom(withSize size: CGSize) {
        if imageView.image == nil || (size.width == 0 && size.height == 0) {
            return
        }

        var minZoom = calculateMinZoom(viewSize: size, imageSize: imageView.image?.size)

        // Force scrollViewDidZoom fire if zoom did not change
        if minZoom == lastZoomScale {
            minZoom += 0.000001
        }
        scrollView.zoomScale = CGFloat(minZoom)
        lastZoomScale = minZoom
    }

}
