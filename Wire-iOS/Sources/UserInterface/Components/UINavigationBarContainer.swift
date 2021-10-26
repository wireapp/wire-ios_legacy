//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

final class UINavigationBarContainer: UIViewController {

    let landscapeTopMargin: CGFloat = 20.0
    let landscapeNavbarHeight: CGFloat = 30.0
    let portraitNavbarHeight: CGFloat = 44.0

    var navigationBar: UINavigationBar
    lazy var navHeight: NSLayoutConstraint =   navigationBar.heightAnchor.constraint(equalToConstant: portraitNavbarHeight)

    init(_ navigationBar: UINavigationBar) {
        self.navigationBar = navigationBar
        super.init(nibName: nil, bundle: nil)
        self.view.addSubview(navigationBar)
        self.view.backgroundColor = UIColor.from(scheme: .barBackground)
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        [navigationBar, view].prepareForLayout()
        NSLayoutConstraint.activate([
          navHeight,
          navigationBar.leftAnchor.constraint(equalTo: view.leftAnchor),
          navigationBar.rightAnchor.constraint(equalTo: view.rightAnchor),
          view.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor)
        ])

        navigationBar.topAnchor.constraint(equalTo: safeTopAnchor).isActive = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let orientation = UIApplication.shared.statusBarOrientation
        let deviceType = UIDevice.current.userInterfaceIdiom

        if orientation.isLandscape && deviceType == .phone {
            navHeight.constant = landscapeNavbarHeight
        } else {
            navHeight.constant = portraitNavbarHeight
        }
    }
}
