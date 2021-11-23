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

class ScalableView: UIView, UIGestureRecognizerDelegate {

    let pinchGesture = UIPinchGestureRecognizer()
    let panGesture = UIPanGestureRecognizer()

    // MARK: - View Life Cycle

    init(isScalingEnabled: Bool) {
        self.isScalingEnabled = isScalingEnabled
        super.init(frame: .zero)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public Interface

    var isScalingEnabled: Bool {
        didSet {
            updateGestureRecognizers()
        }
    }

    func resetScale() {
        transform = .identity
    }

    // MARK: - Setup

    private func setupViews() {
        pinchGesture.addTarget(self, action: #selector(handlePinchGesture(_:)))
        pinchGesture.delegate = self

        panGesture.addTarget(self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 2
        panGesture.maximumNumberOfTouches = 2

        addGestureRecognizer(pinchGesture)
        addGestureRecognizer(panGesture)

        updateGestureRecognizers()
    }

    private func updateGestureRecognizers() {
        panGesture.isEnabled = isScalingEnabled
        pinchGesture.isEnabled = isScalingEnabled
    }

    // MARK: - Pinch To Zoom

    @objc
    func handlePinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard
            gestureRecognizer.state == .began
                || gestureRecognizer.state == .changed
                || gestureRecognizer.state == .ended
        else { return }

        guard let view = gestureRecognizer.view else { return }

        // get location of the gesture's centroid
        var location = gestureRecognizer.location(in: view)

        // offset location relative to center of the view
        // because transform is done relatively to the view's center
        location.x -= view.bounds.midX
        location.y -= view.bounds.midY

        // translate view origin to pinch location, scale, translate view back
        let transform = view.transform
            .translatedBy(x: location.x, y: location.y)
            .scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale)
            .translatedBy(x: -location.x, y: -location.y)

        // apply transform
        view.transform = transform

        // reset scale
        gestureRecognizer.scale = 1

        // reset to identity if the view is scaled smaller than its container
        if view.frame.size.width < bounds.width {
            view.transform = .identity
        }
    }

    @objc
    func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view else { return }

        // prevent translation if the view transform is identity
        guard view.transform != .identity else { return }

        let translation = gestureRecognizer.translation(in: view)

        // translate view to gesture's location
        view.transform = view.transform.translatedBy(x: translation.x, y: translation.y)

        // reset translation
        gestureRecognizer.setTranslation(.zero, in: view)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

}
