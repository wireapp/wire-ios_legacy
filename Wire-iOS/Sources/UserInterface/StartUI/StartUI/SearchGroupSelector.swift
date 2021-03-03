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

final class SearchGroupSelector: UIView, TabBarDelegate {

    var onGroupSelected: ((SearchGroup) -> Void)?

    var group: SearchGroup = .people {
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
        groups = SearchGroup.all
        self.style = style

        let groupItems: [UITabBarItem] = groups.enumerated().map { index, group in
            UITabBarItem(title: group.name.localizedUppercase, image: nil, tag: index)
        }

        tabBar = TabBar(items: groupItems, style: style, selectedIndex: 0)
        super.init(frame: .zero)

        configureViews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        tabBar.delegate = self
        backgroundColor = UIColor.from(scheme: .barBackground, variant: style)
        addSubview(tabBar)
    }

    private func configureConstraints() {
        tabBar.fitInSuperview()
    }

    // MARK: - Tab Bar Delegate

    func tabBar(_ tabBar: TabBar, didSelectItemAt index: Int) {
        group = groups[index]
    }

}
