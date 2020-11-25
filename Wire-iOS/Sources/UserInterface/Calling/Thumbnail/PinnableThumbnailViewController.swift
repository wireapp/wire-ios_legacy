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

final class PinnableThumbnailViewController: UIViewController {

    private let thumbnailView = RoundedView()

    private let thumbnailContainerView: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "ThumbnailContainerView"
        return view
    }()

    private(set) var contentView: OrientableView?

    // MARK: - Dynamics

    fileprivate let edgeInsets = CGPoint(x: 16, y: 16)
    fileprivate var originalCenter: CGPoint = .zero
    fileprivate var hasDoneInitialLayout = false
    fileprivate var hasEnabledPinningBehavior = false

    fileprivate lazy var pinningBehavior: ThumbnailCornerPinningBehavior = {
        return ThumbnailCornerPinningBehavior(item: self.thumbnailView, edgeInsets: self.edgeInsets)
    }()

    fileprivate lazy var animator: UIDynamicAnimator = {
        return UIDynamicAnimator(referenceView: self.thumbnailContainerView)
    }()

    // MARK: - Changing the Previewed Content

    fileprivate(set) var thumbnailContentSize = CGSize(width: 100, height: 100)
    
    func removeCurrentThumbnailContentView() {
        contentView?.removeFromSuperview()
        contentView = nil
    }

    func setThumbnailContentView(_ contentView: OrientableView, contentSize: CGSize) {
        removeCurrentThumbnailContentView()
        thumbnailView.addSubview(contentView)
        self.contentView = contentView

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
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !hasDoneInitialLayout {
            view.layoutIfNeeded()
            view.backgroundColor = .clear
            
            updateThumbnailAfterLayoutUpdate()
            hasDoneInitialLayout = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !hasEnabledPinningBehavior {
            animator.addBehavior(self.pinningBehavior)
            hasEnabledPinningBehavior = true
        }
    }

    private func configureViews() {
        view.addSubview(thumbnailContainerView)

        thumbnailContainerView.addSubview(thumbnailView)
        thumbnailView.autoresizingMask = []
        thumbnailView.clipsToBounds = true
        thumbnailView.shape = .rounded(radius: 12)
        
        thumbnailContainerView.layer.shadowRadius = 30
        thumbnailContainerView.layer.shadowOpacity = 0.32
        thumbnailContainerView.layer.shadowColor = UIColor.black.cgColor
        thumbnailContainerView.layer.shadowOffset = CGSize(width: 0, height: 8)
        thumbnailContainerView.layer.masksToBounds = false
    }

    private func configureConstraints() {
        thumbnailContainerView.translatesAutoresizingMaskIntoConstraints = false

        thumbnailContainerView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor).isActive = true
        thumbnailContainerView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor).isActive = true
        thumbnailContainerView.topAnchor.constraint(equalTo: safeTopAnchor).isActive = true
        thumbnailContainerView.bottomAnchor.constraint(equalTo: safeBottomAnchor).isActive = true
    }

    // MARK: - Orientation

    @objc func orientationDidChange() {
        contentView?.layoutForOrientation()
    }
    
    // MARK: - Size

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        pinningBehavior.isEnabled = false

        // Calculate the new size of the container

        let insets = view.safeAreaInsetsOrFallback

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
        guard thumbnailContentSize != .zero else { return }
        let size = thumbnailContentSize.withOrientation(UIDevice.current.orientation)
        let position = thumbnailPosition(for: size, parentSize: parentSize)

        let changesBlock = { [contentView, thumbnailView, view] in
            thumbnailView.frame = CGRect(
                x: position.x - size.width / 2,
                y: position.y - size.height / 2,
                width: size.width,
                height: size.height
            )

            view?.layoutIfNeeded()
            contentView?.layoutForOrientation()
        }
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: changesBlock)
        } else {
            changesBlock()
        }
    }

    private func updateThumbnailAfterLayoutUpdate() {
        updateThumbnailFrame(animated: false, parentSize: thumbnailContainerView.frame.size)
        pinningBehavior.updateFields(in: thumbnailContainerView.bounds)
    }

    private func thumbnailPosition(for size: CGSize, parentSize: CGSize) -> CGPoint {
        if let center = pinningBehavior.positionForCurrentCorner() {
            return center
        }

        let frame: CGRect

        if UIApplication.isLeftToRightLayout {
            frame = CGRect(x: parentSize.width - size.width - edgeInsets.x, y: edgeInsets.y,
                           width: size.width, height: size.height)
        } else {
            frame = CGRect(x: edgeInsets.x, y: edgeInsets.y, width: size.width, height: size.height)
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
