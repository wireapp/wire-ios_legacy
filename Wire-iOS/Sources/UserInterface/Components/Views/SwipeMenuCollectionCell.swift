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
import UIKit

class SwipeMenuCollectionCell: UICollectionViewCell {
    static let MaxVisualDrawerOffsetRevealDistance: CGFloat = 21

    var canOpenDrawer = false
    var overscrollFraction: CGFloat = 0
    var visualDrawerOffset: CGFloat = 0 {
        didSet {
            setVisualDrawerOffset(visualDrawerOffset, updateUI: true)
        }
    }

    /// Controls how far (distance) the @c menuView is revealed per swipe gesture. Default CGFLOAT_MAX, means all the way
    var maxVisualDrawerOffset: CGFloat = 0 {
        didSet {
            maxMenuViewToSwipeViewLeftConstraint?.constant = maxVisualDrawerOffset
        }
    }

    /// Disabled and enables the separator line on the left of the @c menuView
    var separatorLineViewDisabled = false {
        didSet {
            separatorLine.isHidden = separatorLineViewDisabled
        }
    }
    // If this is set to some value, all cells with the same value will close when another one
    // with the same value opens
    var mutuallyExclusiveSwipeIdentifier: String?

    /// Main view to add subviews to
    let swipeView: UIView = UIView()

    /// View to add menu items to
    let menuView: UIView = UIView()
    // @m called when cell's content is overscrolled by user to the side. General use case for dismissing the cell off the screen.
    var overscrollAction: ((_ cell: SwipeMenuCollectionCell?) -> Void)?

    private var hasCreatedSwipeMenuConstraints = false
    private var swipeViewHorizontalConstraint: NSLayoutConstraint?
    private var menuViewToSwipeViewLeftConstraint: NSLayoutConstraint?
    private var maxMenuViewToSwipeViewLeftConstraint: NSLayoutConstraint?
    private let separatorLine: UIView = UIView()

    private var initialDrawerWidth: CGFloat = 0
    private var initialDrawerOffset: CGFloat = 0
    private var initialDragPoint = CGPoint.zero
    private var revealDrawerOverscrolled = false
    private var revealAnimationPerforming = false
    private var scrollingFraction: CGFloat = 0 {
        didSet {
            visualDrawerOffset = SwipeMenuCollectionCell.calculateViewOffset(forUserOffset: scrollingFraction * bounds.size.width, initialOffset: initialDrawerOffset, drawerWidth: drawerWidth, viewWidth: bounds.size.width)
        }
    }

    private var userInteractionHorizontalOffset: CGFloat = 0 {
        didSet {

            if bounds.size.width == 0 {
                return
            }

            if revealDrawerOverscrolled {
                if userInteractionHorizontalOffset + initialDrawerOffset < bounds.size.width * overscrollFraction {
                    // overscroll cancelled
                    revealAnimationPerforming = true
                    let animStartInteractionPosition = revealDrawerGestureRecognizer.location(in: self)

                    UIView.animate(easing: .easeOutExpo, duration: 0.35, animations: {
                        self.scrollingFraction = self.userInteractionHorizontalOffset / self.bounds.size.width
                        self.layoutIfNeeded()
                    }) { _ in
                        // reset gesture state
                        let animEndInteractionPosition = self.revealDrawerGestureRecognizer.location(in: self)

                        // we need to adjust the drag point to avoid the jump after the animation was ended
                        // between the animation's final state and user new finger position
                        let offsetInteractionBeforeAfterAnimation = animEndInteractionPosition.x - animStartInteractionPosition.x
                        self.initialDragPoint = CGPoint(x: offsetInteractionBeforeAfterAnimation + self.initialDragPoint.x, y: self.initialDragPoint.y)
                        self.revealAnimationPerforming = false

                        let newOffset = CGPoint(x: animEndInteractionPosition.x - self.initialDragPoint.x, y: animEndInteractionPosition.y - self.initialDragPoint.y)

                        self.scrollingFraction = newOffset.x / self.bounds.size.width
                        self.layoutIfNeeded()
                    }

                    revealDrawerOverscrolled = false
                }
            } else {
                if userInteractionHorizontalOffset + initialDrawerOffset > bounds.size.width * overscrollFraction {
                    // overscrolled

                    UIView.animate(easing: .easeOutExpo, duration: 0.35, animations: {
                        self.scrollingFraction = 1.0
                        self.visualDrawerOffset = self.bounds.size.width + self.separatorLine.bounds.size.width
                        self.layoutIfNeeded()
                    })

                    revealDrawerOverscrolled = true
                } else {
                    scrollingFraction = userInteractionHorizontalOffset / bounds.size.width
                }
            }
        }
    }

    private var revealDrawerGestureRecognizer: UIPanGestureRecognizer!
    private let openedFeedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSwipeMenuCollectionCell()

        revealDrawerGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onDrawerScroll(_:)))
        setupRecognizer()
    }

    convenience init() {
        self.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupRecognizer() {
        revealDrawerGestureRecognizer.delegate = self
        revealDrawerGestureRecognizer.delaysTouchesEnded = false
        revealDrawerGestureRecognizer.delaysTouchesBegan = false

        contentView.addGestureRecognizer(revealDrawerGestureRecognizer)
    }

    private func setupSwipeMenuCollectionCell() {
        canOpenDrawer = true
        overscrollFraction = 0.6
        /// When the swipeView is swiped and excesses this offset, the "3 dots" stays at left.
        maxVisualDrawerOffset = SwipeMenuCollectionCell.MaxVisualDrawerOffsetRevealDistance

        swipeView.backgroundColor = .clear
        contentView.addSubview(swipeView)

        menuView.backgroundColor = UIColor.clear
        contentView.addSubview(menuView)

        separatorLine.backgroundColor = UIColor(white: 1.0, alpha: 0.4)
        swipeView.addSubview(separatorLine)
        separatorLine.isHidden = separatorLineViewDisabled

        setNeedsUpdateConstraints()
    }

    @objc
    private func onDrawerScroll(_ pan: UIPanGestureRecognizer) {
        let location = pan.location(in: self)
        let offset = CGPoint(x: location.x - initialDragPoint.x, y: location.y - initialDragPoint.y)

        if !canOpenDrawer || revealAnimationPerforming {
            return
        }

        switch pan.state {
        case .began:
            // reset gesture state
            drawerScrollingStarts()
            initialDrawerOffset = visualDrawerOffset
            initialDragPoint = pan.location(in: self)
        case .changed:
            userInteractionHorizontalOffset = offset.x
            if initialDrawerWidth == 0 {
                initialDrawerWidth = menuView.bounds.size.width
            }
            openedFeedbackGenerator.prepare()
        case .ended,
             .failed,
             .cancelled:
            drawerScrollingEnded(withOffset: offset.x)

            if offset.x + initialDrawerOffset > bounds.size.width * overscrollFraction {
                // overscrolled
                overscrollAction?(self)

                separatorLine.alpha = 0.0
                setVisualDrawerOffset(0, updateUI: false)
                NotificationCenter.default.removeObserver(self)
            } else {
                if visualDrawerOffset > drawerWidth / CGFloat(2) {
                    openedFeedbackGenerator.impactOccurred()
                    setDrawerOpen(true, animated: true)
                } else {
                    setDrawerOpen(false, animated: true)
                }
            }
        default:
            break
        }
    }

    private var drawerWidth: CGFloat {
        return initialDrawerWidth
    }

    /// Apply the apple-style rubber banding on the offset
    ///
    /// - Parameters:
    ///   - offset: User-interaction offset
    ///   - viewWidth: Total container size
    ///   - coef: Coefficient (from very hard (<0.1) to very easy (>0.9))
    /// - Returns: New offset
    class private func rubberBandOffset(_ offset: CGFloat, viewWidth: CGFloat, coefficient coef: CGFloat) -> CGFloat {
        return (1.0 - (1.0 / ((offset * coef / viewWidth) + 1.0))) * viewWidth
    }

    class private func calculateViewOffset(forUserOffset offsetX: CGFloat, initialOffset initialDrawerOffset: CGFloat, drawerWidth: CGFloat, viewWidth: CGFloat) -> CGFloat {
        if offsetX + initialDrawerOffset < 0 {
            return rubberBandOffset(offsetX + initialDrawerOffset, viewWidth: viewWidth, coefficient: 0.15)
        }

        return initialDrawerOffset + offsetX
    }

    func setVisualDrawerOffset(_ visualDrawerOffset: CGFloat, updateUI doUpdate: Bool) {
        if self.visualDrawerOffset == visualDrawerOffset {
            if doUpdate {
                swipeViewHorizontalConstraint?.constant = self.visualDrawerOffset
                checkAndUpdateMaxVisualDrawerOffsetConstraints(visualDrawerOffset)
            }
            return
        }

        self.visualDrawerOffset = visualDrawerOffset
        if doUpdate {
            swipeViewHorizontalConstraint?.constant = self.visualDrawerOffset
            checkAndUpdateMaxVisualDrawerOffsetConstraints(visualDrawerOffset)
        }
    }

    private func setDrawerOpen(_ isOpened: Bool, animated: Bool) {
        if isOpened && visualDrawerOffset == drawerWidth ||
           !isOpened && visualDrawerOffset == 0 {
            return
        }

        let action = {
            self.visualDrawerOffset = 0
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(easing: .easeOutExpo, duration: 0.35, animations: {
                action()
            })
        } else {
            action()
        }
    }

    // MARK: - DrawerOverrides

    /// No need to call super, void implementation
    func drawerScrollingStarts() {
        // Intentionally left empty. No need to call super on it
    }

    /// No need to call super, void implementation
    func drawerScrollingEnded(withOffset offset: CGFloat) {
        // Intentionally left empty. No need to call super on it
    }

    override func updateConstraints() {

        if hasCreatedSwipeMenuConstraints {
            super.updateConstraints()
            return
        }

        hasCreatedSwipeMenuConstraints = true

        swipeViewHorizontalConstraint = swipeView.leftAnchor.constraint(equalTo: contentView.leftAnchor)

        /// menu view attachs to swipeView before reaching max offset
        menuViewToSwipeViewLeftConstraint = menuView.rightAnchor.constraint(equalTo: swipeView.leftAnchor)

        /// menu view attachs to content view after reaching max offset
        maxMenuViewToSwipeViewLeftConstraint = menuView.leftAnchor.constraint(equalTo: leftAnchor, constant: maxVisualDrawerOffset)

        [swipeView, separatorLine, menuView].prepareForLayout()

        let constraints: [NSLayoutConstraint] = [
            swipeViewHorizontalConstraint!,
            swipeView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            swipeView.heightAnchor.constraint(equalTo: contentView.heightAnchor),

            swipeView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            separatorLine.widthAnchor.constraint(equalToConstant: UIScreen.hairline),
            separatorLine.heightAnchor.constraint(equalToConstant: 25),
            separatorLine.centerYAnchor.constraint(equalTo: swipeView.centerYAnchor),
            separatorLine.rightAnchor.constraint(equalTo: menuView.rightAnchor),

            menuView.topAnchor.constraint(equalTo: swipeView.topAnchor),
            menuView.bottomAnchor.constraint(equalTo: swipeView.bottomAnchor),
            menuViewToSwipeViewLeftConstraint!
        ]

        NSLayoutConstraint.activate(constraints)

        super.updateConstraints()
    }

    /// Checks on the @c maxVisualDrawerOffset and switches the prio's of the constraint
    private func checkAndUpdateMaxVisualDrawerOffsetConstraints(_ visualDrawerOffset: CGFloat) {
        if visualDrawerOffset >= menuView.frame.width + maxVisualDrawerOffset {
            menuViewToSwipeViewLeftConstraint?.isActive = false
            maxMenuViewToSwipeViewLeftConstraint?.isActive = true
        } else {
            disableMaxVisualDrawerOffsetConstraints()
        }
    }

    private func disableMaxVisualDrawerOffsetConstraints() {
        maxMenuViewToSwipeViewLeftConstraint?.isActive = false
        menuViewToSwipeViewLeftConstraint?.isActive = true
    }

}

// MARK: - UIGestureRecognizerDelegate

extension SwipeMenuCollectionCell: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var result = true

        if gestureRecognizer == revealDrawerGestureRecognizer {

            let offset = revealDrawerGestureRecognizer.translation(in: self)
            if swipeViewHorizontalConstraint?.constant == 0 && offset.x < 0 {
                result = false
            } else {
                result = abs(offset.x) > abs(offset.y)
            }
        }
        return result
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if #available(iOS 13.0, *) {
            return gestureRecognizer is UILongPressGestureRecognizer
        }

        // all other recognizers require this pan recognizer to fail
        return gestureRecognizer == revealDrawerGestureRecognizer
    }

    /// NOTE:
    /// In iOS 11, the force touch gesture recognizer used for peek & pop was blocking
    /// the pan gesture recognizer used for the swipeable cell. The fix to this problem
    /// however broke the correct behaviour for iOS 10 (namely, the pan gesture recognizer
    /// was now blocking the force touch recognizer). Although Apple documentation suggests
    /// getting the reference to the force recognizer and using delegate methods to create
    /// failure requirements, setting the delegate raised an exception (???). Here we
    /// simply apply the fix for iOS 11 and above.
    /// - Parameters:
    ///   - gestureRecognizer: gestureRecognizer
    ///   - otherGestureRecognizer: otherGestureRecognizer
    /// - Returns: true if need to require failure of otherGestureRecognizer
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        if #available(iOS 13.0, *) {
            return false
        } else if #available(iOS 11.0, *) {
            // pan recognizer should not require failure of any other recognizer
            return !(gestureRecognizer is UIPanGestureRecognizer)
        }

        return !(gestureRecognizer is UIPanGestureRecognizer) || !(otherGestureRecognizer is UIPanGestureRecognizer)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        if #available(iOS 13.0, *) {
            return true
        } else if #available(iOS 11.0, *) {
            // pan recognizer should not recognize simultaneously with any other recognizer
            return !(gestureRecognizer is UIPanGestureRecognizer)
        }

        return true
    }

}
