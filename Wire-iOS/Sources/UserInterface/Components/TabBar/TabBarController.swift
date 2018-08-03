//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cartography

@objc protocol TabBarControllerDelegate: class {
    func tabBarController(_ controller: TabBarController, tabBarDidSelectIndex: Int)
}

extension UIPageViewController {
    var scrollView: UIScrollView? {
        return view.subviews
            .lazy
            .compactMap { $0 as? UIScrollView }
            .first
    }
}

extension UIViewController {
    @objc var wr_tabBarController: TabBarController? {
        if parent == nil {
            return nil
        } else if (parent?.isKind(of: TabBarController.self) != nil) {
            return parent as? TabBarController
        } else {
            return parent?.wr_tabBarController
        }
    }

    @objc public func takeFirstResponder() {
        if UIAccessibilityIsVoiceOverRunning() {
            return
        }
    }
}

@objcMembers
class TabBarController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIScrollViewDelegate {

    weak var delegate: TabBarControllerDelegate?
    
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private(set) var viewControllers: [UIViewController]
    private(set) var selectedIndex: Int
    
    @objc(interactive) var isInteractive = true {
        didSet {
            pageViewController.dataSource = isInteractive ? self : nil
            pageViewController.delegate = isInteractive ? self : nil
            tabBar?.animatesTransition = isInteractive
        }
    }

    var style: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            tabBar?.style = style
        }
    }

    @objc(enabled)
    var isEnabled = true {
        didSet {
            tabBar?.isUserInteractionEnabled = isEnabled
            isInteractive = isEnabled // Shouldn't be interactive when it's disabled
        }
    }

    // MARK: - Views
    private var tabBar: TabBar?
    private var contentView = UIView()
    private var isSwiping = false
    private var startOffset: CGFloat = 0

    // MARK: - Initialization

    init(viewControllers: [UIViewController]) {
        self.viewControllers = viewControllers
        self.selectedIndex = 0
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        createViews()
        createConstraints()
        selectIndex(selectedIndex, animated: false)
    }

    fileprivate func createViews() {
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.contentView)
        contentView.backgroundColor = viewControllers.first?.view?.backgroundColor
        add(pageViewController, to: contentView)
        pageViewController.scrollView?.delegate = self

        if isInteractive {
            pageViewController.dataSource = self
            pageViewController.delegate = self
        }
        
        let items = self.viewControllers.map({ viewController in viewController.tabBarItem! })
        self.tabBar = TabBar(items: items, style: self.style, selectedIndex: selectedIndex)
        tabBar?.animatesTransition = isInteractive
        self.tabBar?.delegate = self
        self.tabBar?.isUserInteractionEnabled = self.isEnabled && items.count > 1
        self.view.addSubview(self.tabBar!)
    }

    fileprivate func createConstraints() {
        pageViewController.view.fitInSuperview()
        
        if let tabBar = self.tabBar {
            constrain(tabBar, contentView, view) { tabBar, contentView, view in
                tabBar.top == tabBar.superview!.top
                tabBar.left == tabBar.superview!.left
                tabBar.right == tabBar.superview!.right
                contentView.top == tabBar.bottom
                contentView.bottom == view.bottom
            }
        }

        constrain(contentView, view, pageViewController.view) { contentView, view, pageViewController in
            if (self.tabBar == nil) { contentView.top == contentView.superview!.top }
            contentView.left == contentView.superview!.left
            contentView.right == contentView.superview!.right
            pageViewController.width == contentView.width
            pageViewController.height == contentView.height
        }
    }

    // MARK: - Interacting with the Tab Bar

    func selectIndex(_ index: Int, animated: Bool) {
        selectedIndex = index

        let toViewController = viewControllers[index]
        let fromViewController = pageViewController.viewControllers?.first

        guard toViewController != fromViewController else { return }
        
        let forward = viewControllers.index(of: toViewController) > fromViewController.flatMap(viewControllers.index)
        let direction = forward ? UIPageViewControllerNavigationDirection.forward : .reverse
        
        pageViewController.setViewControllers([toViewController], direction: direction, animated: isInteractive) { [delegate, tabBar] complete in
            guard complete else { return }
            tabBar?.setSelectedIndex(index, animated: animated)
            delegate?.tabBarController(self, tabBarDidSelectIndex: index)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return viewControllers.index(of: viewController).flatMap {
            let index = $0 + 1
            guard index >= 0 && index < viewControllers.count else { return nil }
            return viewControllers[index]
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return viewControllers.index(of: viewController).flatMap {
            let index = $0 - 1
            guard index >= 0 && index < viewControllers.count else { return nil }
            return viewControllers[index]
        }
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
        ) {
        guard let selected = pageViewController.viewControllers?.first else { return }
        guard let index = viewControllers.index(of: selected) else { return }

        if completed {
            isSwiping = false
            delegate?.tabBarController(self, tabBarDidSelectIndex: index)
            selectedIndex = index
            tabBar?.setSelectedIndex(selectedIndex, animated: isInteractive)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isSwiping = true
        startOffset = scrollView.contentOffset.x
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isSwiping = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isSwiping else { return }
    
        let startPosition = abs(startOffset - scrollView.contentOffset.x)
        let numberOfItems = CGFloat(viewControllers.count)
        let percent = (startPosition / view.frame.width) / numberOfItems

        // Percentage occupied by one page, e.g. 33% when we have 3 controllers.
        let increment = 1.0 / numberOfItems
        // Start percentage, for example 50% when starting to swipe from the last of 2 controllers.
        let startPercentage = increment * CGFloat(selectedIndex)
        
        // The adjusted percentage of the movement based on the scroll direction
        let adjustedPercent: CGFloat = {
            if startOffset <= scrollView.contentOffset.x {
                return startPercentage + percent // going right or not moving
            } else {
                return startPercentage - percent // going left
            }
        }()

        tabBar?.setOffsetPercentage(adjustedPercent)
    }

}

extension TabBarController: TabBarDelegate {

    func tabBar(_ tabBar: TabBar, didSelectItemAt index: Int) {
        selectIndex(index, animated: tabBar.animatesTransition)
    }

}
