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

extension CGSize {
    func minZoom(imageSize: CGSize?) -> CGFloat {
        guard let imageSize = imageSize else { return 1 }
        guard imageSize != .zero else { return 1 }
        guard self != .zero else { return 1 }

        var minZoom = min(self.width / imageSize.width, self.height / imageSize.height)

        if minZoom > 1 {
            minZoom = 1
        }

        return minZoom
    }


    /// returns the longest length among width and height
    var longestLength: CGFloat {
        return width > height ? width : height
    }

    /// returns true if both with and height are longer than otherSize
    ///
    /// - Parameter otherSize: other CGSize to compare
    /// - Returns: true if both with and height are longer than otherSize
    func contains(_ otherSize: CGSize) -> Bool {
        return otherSize.width < width &&
               otherSize.height < height
    }
}

extension FullscreenImageViewController {

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator?) {
        guard let imageSize = imageView?.image?.size else { return }

        let isImageZoomedToMax = scrollView.zoomScale == scrollView.maximumZoomScale

        let isImageZoomed = abs(scrollView.minimumZoomScale - scrollView.zoomScale) > kZoomScaleDelta
        updateScrollViewZoomScale(viewSize: size, imageSize: imageSize)

        let animationBlock: () -> Void = {
            if isImageZoomedToMax {
                self.scrollView.zoomScale = self.scrollView.maximumZoomScale
            } else if isImageZoomed == false {
                self.scrollView.zoomScale = self.scrollView.minimumZoomScale
            }
        }

        if let coordinator = coordinator {
            coordinator.animate(alongsideTransition: { (context) in
                animationBlock()
            })
        } else {
            animationBlock()
        }
    }

    // MARK: - Gesture Handling

    @objc func handleDoubleTap(_ doubleTapper: UITapGestureRecognizer) {
        setSelectedByMenu(false, animated: false)

        guard let image = imageView?.image else { return }

        UIMenuController.shared.isMenuVisible = false
        let scaleDiff: CGFloat = scrollView.zoomScale - scrollView.minimumZoomScale

        // image view in minimum zoom scale, zoom in to a 50 x 50 rect
        if scaleDiff < kZoomScaleDelta {
            // image is smaller than screen bound and zoom sclae is max(1), do not zoom in
            let point = doubleTapper.location(in: doubleTapper.view)

            let zoomLength = image.size.longestLength < 50 ? image.size.longestLength : 50

            let zoomRect = CGRect(x: point.x - zoomLength / 2, y: point.y - zoomLength / 2, width: zoomLength, height: zoomLength)
            let finalRect = imageView?.convert(zoomRect, from: doubleTapper.view)

            scrollView.zoom(to: finalRect ?? .zero, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }

    // MARK: - Zoom scale

    @objc func updateScrollViewZoomScale(viewSize: CGSize, imageSize: CGSize) {
        self.scrollView.minimumZoomScale = viewSize.minZoom(imageSize: imageSize)

        // if the image is small than the screen size, max zoom level is "zoom to fit screen"
        if viewSize.contains(imageSize) {
            self.scrollView.maximumZoomScale = min(viewSize.height / imageSize.height, viewSize.width / imageSize.width)
        } else {
            self.scrollView.maximumZoomScale = 1
        }
    }

    @objc func updateZoom() {
        guard let size = parent?.view?.frame.size else { return }
        updateZoom(withSize: size)
    }

    /// Zoom to show as much image as possible unless image is smaller than screen
    ///
    /// - Parameter size: size of the view which contains imageView
    @objc func updateZoom(withSize size: CGSize) {
        guard let image = imageView?.image else { return }
        guard !(size.width == 0 && size.height == 0) else { return }

        var minZoom = size.minZoom(imageSize: image.size)

        // Force scrollViewDidZoom fire if zoom did not change
        if minZoom == lastZoomScale {
            minZoom += 0.000001
        }
        scrollView.zoomScale = CGFloat(minZoom)
        lastZoomScale = minZoom
    }

    // MARK: - Image view

    @objc func setupImageView(image: MediaAsset, parentSize: CGSize) {
        guard let imageView = UIImageView(mediaAsset: image) else { return }

        imageView.clipsToBounds = true
        imageView.layer.allowsEdgeAntialiasing = true
        self.imageView = imageView
        imageView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(imageView)
        scrollView.contentSize = imageView.image?.size ?? CGSize.zero

        updateScrollViewZoomScale(viewSize: parentSize, imageSize: image.size)
        updateZoom(withSize: parentSize)

        centerScrollViewContent()
    }
}
