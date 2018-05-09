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

import UIKit

@objc class PinnableThumbnailViewController: UIViewController {

    private let thumbnailView = ContinuousCornersView(cornerRadius: 12)
    private let thumbnailContainerView = UIView()

    // MARK: - Dynamics

    fileprivate let edgeInset: CGFloat = 24
    fileprivate var originalCenter: CGPoint = .zero

    fileprivate lazy var pinningBehavior: ThumbnailCornerPinningBehavior = {
        return ThumbnailCornerPinningBehavior(item: self.thumbnailView, edgeInset: self.edgeInset)
    }()

    fileprivate lazy var animator: UIDynamicAnimator = {
        return UIDynamicAnimator(referenceView: self.thumbnailContainerView)
    }()

    // MARK: - Changing the Previewed Content

    fileprivate(set) var thumbnailContentSize: CGSize = .zero

    func setThumbnailContentView(_ contentView: UIView, contentSize: CGSize) {

        thumbnailView.subviews.forEach { $0.removeFromSuperview() }

        thumbnailView.addSubview(contentView)
        contentView.autoPinEdgesToSuperviewEdges()

        self.thumbnailContentSize = contentSize
        updateThumbnailFrame(animated: false, parentSize: thumbnailContainerView.frame.size)

    }

    func updateThumbnailContentSize(_ newSize: CGSize, animated: Bool) {
        self.thumbnailContentSize = newSize
        updateThumbnailFrame(animated: false, parentSize: thumbnailContainerView.frame.size)
    }


    // MARK: - Configuration

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        configureConstraints()

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        thumbnailView.addGestureRecognizer(panGestureRecognizer)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.layoutIfNeeded()
        view.backgroundColor = .white

        updateThumbnailAfterLayoutUpdate()
        animator.addBehavior(self.pinningBehavior)

    }

    private func configureViews() {

        view.addSubview(thumbnailContainerView)

        thumbnailContainerView.addSubview(thumbnailView)
        thumbnailView.autoresizingMask = []
        thumbnailView.clipsToBounds = true
        
    }

    private func configureConstraints() {

        thumbnailContainerView.translatesAutoresizingMaskIntoConstraints = false

        thumbnailContainerView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor).isActive = true
        thumbnailContainerView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor).isActive = true
        thumbnailContainerView.topAnchor.constraint(equalTo: safeTopAnchor).isActive = true
        thumbnailContainerView.bottomAnchor.constraint(equalTo: safeBottomAnchor).isActive = true

    }

    // MARK: - Size

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        pinningBehavior.isEnabled = false

        // Calculate the new size of the container

        let insets = view.safeAreaInsetsOfFallback

        let safeSize = CGSize(width: size.width - insets.left - insets.right,
                              height: size.height - insets.top - insets.bottom)

        let bounds = CGRect(origin: CGPoint.zero, size: safeSize)
        pinningBehavior.updateFields(in: bounds)

        coordinator.animate(alongsideTransition: { context in
            self.updateThumbnailFrame(animated: false, parentSize: safeSize)
        }, completion: { context in
            self.pinningBehavior.isEnabled = true
        })

    }

    @available(iOS 11, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.layoutIfNeeded()
        updateThumbnailAfterLayoutUpdate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateThumbnailAfterLayoutUpdate()
    }

    private func updateThumbnailFrame(animated: Bool, parentSize: CGSize) {

        let size: CGSize
        view.layoutIfNeeded()

        switch thumbnailContentSize.aspectRatio {
        case .square:
            let sideLength = thumbnailContainerView.bounds.width * 1/3
            size = CGSize(width: sideLength, height: sideLength)

        case .portrait(let heightRatio):
            let width = thumbnailContainerView.bounds.width * 1/4
            let height = width * heightRatio
            size = CGSize(width: width, height: height)

        case .landscape(let heightRatio):
            let width = thumbnailContainerView.bounds.width * 1/3
            let height = width * heightRatio
            size = CGSize(width: width, height: height)
        }

        let position = self.thumbnailPosition(for: size, parentSize: parentSize)

        let changesBlock = {

            self.thumbnailView.frame = CGRect(x: position.x - size.width / 2,
                                              y: position.y - size.height / 2,
                                              width: size.width, height: size.height)

            self.view.layoutIfNeeded()

        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: changesBlock)
        } else {
            changesBlock()
        }

    }

    private func updateThumbnailAfterLayoutUpdate() {
        pinningBehavior.updateFields(in: thumbnailContainerView.bounds)
        updateThumbnailFrame(animated: false, parentSize: thumbnailContainerView.frame.size)
    }

    private func thumbnailPosition(for size: CGSize, parentSize: CGSize) -> CGPoint {

        if let center = pinningBehavior.positionForCurrentCorner() {
            return center
        }

        let frame: CGRect

        if UIApplication.isLeftToRightLayout {
            frame = CGRect(x: parentSize.width - size.width - edgeInset, y: edgeInset,
                           width: size.width, height: size.height)
        } else {
            frame = CGRect(x: edgeInset, y: edgeInset, width: size.width, height: size.height)
        }

        return CGPoint(x: frame.midX, y: frame.midY)

    }

    // MARK: - Panning

    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {

        switch recognizer.state {
        case .began:
            // Disable the pinning while the user moves the thumbnail
            pinningBehavior.isEnabled = false
            originalCenter = thumbnailView.center

        case .changed:

            // Calculate the target center

            let originalFrame = thumbnailView.frame
            let containerBounds = thumbnailContainerView.bounds

            let translation = recognizer.translation(in: thumbnailContainerView)
            let transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            let transformedPoint = originalCenter.applying(transform)

            // Calculate the appropriate horizontal origin

            let x: CGFloat
            let halfWidth = originalFrame.width / 2

            if (transformedPoint.x - halfWidth) < containerBounds.minX {
                x = containerBounds.minX
            } else if (transformedPoint.x + halfWidth) > containerBounds.maxX {
                x = containerBounds.maxX - originalFrame.width
            } else {
                x = transformedPoint.x - halfWidth
            }

            // Calculate the appropriate vertical origin

            let y: CGFloat
            let halfHeight = originalFrame.height / 2

            if (transformedPoint.y - halfHeight) < containerBounds.minY {
                y = containerBounds.minY
            } else if (transformedPoint.y + halfHeight) > containerBounds.maxY {
                y = containerBounds.maxY - originalFrame.height
            } else {
                y = transformedPoint.y - halfHeight
            }

            // Do not move the thumbnail outside the container
            thumbnailView.frame = CGRect(x: x, y: y, width: originalFrame.width, height: originalFrame.height)

        case .cancelled, .ended:

            // Snap the thumbnail to the closest edge
            let velocity = recognizer.velocity(in: self.thumbnailContainerView)
            pinningBehavior.isEnabled = true
            pinningBehavior.addLinearVelocity(velocity)

        default:
            break
        }

    }

}
