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

extension UIViewController {
    @objc var wr_tabBarController: TabBarController? {
        if (parent == nil) {
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
class TabBarController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    weak var delegate: TabBarControllerDelegate?
    
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private(set) var viewControllers: [UIViewController]
    private(set) var selectedIndex: Int
    
    @objc(swipingEnabled) var isSwipingEnabled = true {
        didSet {
            pageViewController.dataSource = isSwipingEnabled ? self : nil
            pageViewController.delegate = isSwipingEnabled ? self : nil
        }
    }

    var style: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            tabBar?.style = style
        }
    }

    @objc(enabled)
    var isEnabled: Bool = true {
        didSet {
            self.tabBar?.isUserInteractionEnabled = self.isEnabled
        }
    }

    // MARK: - Views
    private var tabBar: TabBar?
    private var contentView = UIView()
    private var isTransitioning = false

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
        
        add(pageViewController, to: contentView)

        if isSwipingEnabled {
            pageViewController.dataSource = self
            pageViewController.delegate = self
        }
        
        let items = self.viewControllers.map({ viewController in viewController.tabBarItem! })
        self.tabBar = TabBar(items: items, style: self.style, selectedIndex: selectedIndex)
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

        guard toViewController != fromViewController, !isTransitioning else { return }

        delegate?.tabBarController(self, tabBarDidSelectIndex: index)
        tabBar?.setSelectedIndex(index, animated: animated)
        
        let forward = viewControllers.index(of: toViewController) > fromViewController.flatMap(viewControllers.index)
        let direction = forward ? UIPageViewControllerNavigationDirection.forward : .reverse
        pageViewController.setViewControllers([toViewController], direction: direction, animated: true) { _ in
            self.isTransitioning = false
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
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let selected = pageViewController.viewControllers?.first else { return }
        guard let index = viewControllers.index(of: selected) else { return }
        
        delegate?.tabBarController(self, tabBarDidSelectIndex: index)
        tabBar?.setSelectedIndex(index, animated: true)
    }

}

extension TabBarController: TabBarDelegate {

    func tabBar(_ tabBar: TabBar, didSelectItemAt index: Int) {
        selectIndex(index, animated: tabBar.animatesTransition)
    }

}
