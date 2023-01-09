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

protocol TabBarDelegate: AnyObject {
    func tabBar(_ tabBar: TabBar, didSelectItemAt index: Int)
}

final class TabBar: UIView {
    fileprivate let stackView = UIStackView()

    // MARK: - Properties

    weak var delegate: TabBarDelegate?
    var animatesTransition = true
    fileprivate(set) var items: [UITabBarItem] = []
    private let tabInset: CGFloat = 16

    private let selectionLineView = UIView()
    private let lineView = UIView()
    private(set) var tabs: [Tab] = []
    private lazy var lineLeadingConstraint: NSLayoutConstraint = selectionLineView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: tabInset)
    private var didUpdateInitialBarPosition = false

    fileprivate(set) var selectedIndex: Int {
        didSet {
            updateButtonSelection()
        }
    }

    fileprivate var selectedTab: Tab {
        return self.tabs[selectedIndex]
    }

    private var titleObservers: [NSKeyValueObservation] = []

    deinit {
        titleObservers.forEach { $0.invalidate() }
    }

    // MARK: - Initialization

    init(items: [UITabBarItem], selectedIndex: Int = 0) {
        precondition(!items.isEmpty, "TabBar must be initialized with at least one item")

        self.items = items
        self.selectedIndex = selectedIndex

        super.init(frame: CGRect.zero)

        self.accessibilityTraits = .tabBar

        setupViews()
        createConstraints()
        updateButtonSelection()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        tabs = items.enumerated().map(makeButtonForItem)
        tabs.forEach(stackView.addArrangedSubview)

        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        stackView.alignment = .fill
        addSubview(stackView)

        addSubview(lineView)
        addSubview(selectionLineView)
        selectionLineView.backgroundColor = SemanticColors.TabBar.backgroundSeperatorSelected
        lineView.backgroundColor = SemanticColors.TabBar.backgroundSeparator
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !didUpdateInitialBarPosition, bounds != .zero {
            didUpdateInitialBarPosition = true
            updateLinePosition(animated: false)
        }
    }

    private func updateLinePosition(animated: Bool) {
        let offset = CGFloat(selectedIndex) * selectionLineView.bounds.width
        guard offset != lineLeadingConstraint.constant else { return }
        updateLinePosition(offset: offset, animated: animated)
    }

    private func updateLinePosition(offset: CGFloat, animated: Bool) {
        lineLeadingConstraint.constant = offset + tabInset

        if animated {
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: layoutIfNeeded
            )
        } else {
            layoutIfNeeded()
        }
    }

    func setOffsetPercentage(_ percentage: CGFloat) {
        let offset = percentage * (bounds.width - tabInset * 2)
        updateLinePosition(offset: offset, animated: false)
    }

    private func createConstraints() {
        let oneOverItemsCount: CGFloat = 1 / CGFloat(items.count)
        let widthInset = tabInset * 2 * oneOverItemsCount

        [self, lineView, selectionLineView, stackView].prepareForLayout()
        NSLayoutConstraint.activate([
            lineLeadingConstraint,
            lineView.heightAnchor.constraint(equalTo: selectionLineView.heightAnchor),
            lineView.bottomAnchor.constraint(equalTo: selectionLineView.bottomAnchor),
            lineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            lineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectionLineView.heightAnchor.constraint(equalToConstant: 1),
            selectionLineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            selectionLineView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: oneOverItemsCount, constant: -widthInset),

            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: tabInset),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -tabInset),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 48),

            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
    }

    fileprivate func makeButtonForItem(_ index: Int, _ item: UITabBarItem) -> Tab {
        let tab = Tab()
        tab.setTitle(item.title, for: .normal)

        if let accessibilityID = item.accessibilityIdentifier {
            tab.accessibilityIdentifier = accessibilityID
        } else {
            tab.accessibilityIdentifier = "Tab\(index)"
        }

        let changeObserver = item.observe(\.title) { [unowned tab, unowned item] _, _ in
            tab.setTitle(item.title, for: .normal)
        }

        titleObservers.append(changeObserver)

        tab.addTarget(self, action: #selector(TabBar.itemSelected(_:)), for: .touchUpInside)
        return tab
    }

    // MARK: - Actions

    @objc func itemSelected(_ sender: AnyObject) {
        guard
            let tab = sender as? Tab,
            let selectedIndex =  self.tabs.firstIndex(of: tab)
        else {
            return
        }

        self.delegate?.tabBar(self, didSelectItemAt: selectedIndex)
        setSelectedIndex(selectedIndex, animated: animatesTransition)
    }

    func setSelectedIndex( _ index: Int, animated: Bool) {
        let changes = { [weak self] in
            self?.selectedIndex = index
            self?.layoutIfNeeded()
        }

        if animated {
            UIView.transition(
                with: self,
                duration: 0.3,
                options: [.transitionCrossDissolve, .allowUserInteraction, .beginFromCurrentState],
                animations: changes
            )
        } else {
            changes()
        }

        updateLinePosition(animated: animated)
    }

    fileprivate func updateButtonSelection() {
        tabs.forEach { $0.isSelected = false }
        tabs[selectedIndex].isSelected = true
    }
}
