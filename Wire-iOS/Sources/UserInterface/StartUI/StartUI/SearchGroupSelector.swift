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
import Cartography

final class SearchGroupSelector: UIView, TabBarDelegate {

    @objc static var shouldShowBotResults: Bool {
        return DeveloperMenuState.developerMenuEnabled() && ZMUser.selfUser().team != nil
    }

    @objc public var onGroupSelected: ((SearchGroup)->())? = nil

    @objc public var group: SearchGroup = .people {
        didSet {
            onGroupSelected?(group)
        }
    }

    // MARK: - Views

    let style: ColorSchemeVariant

    private let tabBar: TabBar
    private let groups: [SearchGroup]

    // MARK: - Initialization
    
    init(style: ColorSchemeVariant) {

        self.groups = SearchGroup.all
        self.style = style

        let groupItems: [UITabBarItem] = groups.enumerated().map { index, group in
            UITabBarItem(title: group.name.uppercased(), image: nil, tag: index)
        }

        self.tabBar = TabBar(items: groupItems, style: style, selectedIndex: 0)
        super.init(frame: .zero)

        configureViews()
        configureConstraints()

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        tabBar.delegate = self
        tabBar.animatesTransition = false
        backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorBarBackground, variant: style)
        addSubview(tabBar)
    }

    private func configureConstraints() {

        constrain(self, tabBar) { selfView, tabBar in
            tabBar.top == selfView.top
            tabBar.left == selfView.left
            tabBar.right == selfView.right
            selfView.bottom == tabBar.bottom
        }

    }

    // MARK: - Tab Bar Delegate

    func tabBar(_ tabBar: TabBar, didSelectItemAt index: Int) {
        group = groups[index]
    }

}
