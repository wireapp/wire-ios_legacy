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
    var wr_tabBarController: TabBarController? {
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

@objc
class TabBarController: UIViewController {

    weak var delegate: TabBarControllerDelegate?

    fileprivate(set) var viewControllers: [UIViewController]
    fileprivate(set) var selectedIndex: Int

    var style: ColorSchemeVariant = ColorScheme.default().variant {
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

    fileprivate var presentedTabBarViewController: UIViewController?
    fileprivate var tabBar: TabBar?
    fileprivate var contentView: UIView!
    fileprivate var isTransitioning: Bool = false

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
        self.contentView = UIView(frame: self.view.bounds)
        self.contentView!.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.contentView)

        let items = self.viewControllers.map({ viewController in viewController.tabBarItem! })
        self.tabBar = TabBar(items: items, style: self.style, selectedIndex: selectedIndex)
        self.tabBar?.delegate = self
        self.tabBar?.isUserInteractionEnabled = self.isEnabled && items.count > 1
        self.view.addSubview(self.tabBar!)
    }

    fileprivate func createConstraints() {

        if let tabBar = self.tabBar {
            constrain(tabBar, self.contentView) { tabBar, contentView in
                tabBar.top == tabBar.superview!.top
                tabBar.left == tabBar.superview!.left
                tabBar.right == tabBar.superview!.right
                contentView.top == tabBar.bottom
            }
        }

        constrain(self.contentView) { contentView in
            if (self.tabBar == nil) { contentView.top == contentView.superview!.top }
            contentView.left == contentView.superview!.left
            contentView.right == contentView.superview!.right
            contentView.bottom == contentView.superview!.bottom
        }
    }

    // MARK: - Interacting with the Tab Bar

    func selectIndex(_ index: Int, animated: Bool) {
        selectedIndex = index

        let toViewController = self.viewControllers[index]
        let fromViewController = self.presentedTabBarViewController

        guard toViewController != fromViewController &&
            self.contentView != nil &&
            !isTransitioning
            else {
            return
        }

        delegate?.tabBarController(self, tabBarDidSelectIndex: index)
        self.presentedTabBarViewController = toViewController
        self.tabBar?.setSelectedIndex(index, animated: animated)

        if (fromViewController != nil) {
            fromViewController?.willMove(toParentViewController: nil)
        }

        toViewController.view.translatesAutoresizingMaskIntoConstraints = true
        toViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        toViewController.view.frame = self.contentView.bounds

        addChildViewController(toViewController)
        self.contentView.addSubview(toViewController.view)

        guard fromViewController != nil else {
            toViewController.didMove(toParentViewController: self)
            return
        }

        self.transition(from: fromViewController!, to: toViewController, duration: animated ? 0.25 : 0, options: .transitionCrossDissolve, animations: {
            self.isTransitioning = true
            if toViewController.responds(to: #selector(UIViewController.takeFirstResponder)) {
                toViewController.perform(#selector(UIViewController.takeFirstResponder))
            }
        }, completion: { (finished) in
            self.isTransitioning = false
            fromViewController?.view.removeFromSuperview()
            fromViewController?.removeFromParentViewController()
            toViewController.didMove(toParentViewController: self)
        })

    }

}

extension TabBarController: TabBarDelegate {

    func tabBar(_ tabBar: TabBar, didSelectItemAt index: Int) {
        selectIndex(index, animated: tabBar.animatesTransition)
    }

}
