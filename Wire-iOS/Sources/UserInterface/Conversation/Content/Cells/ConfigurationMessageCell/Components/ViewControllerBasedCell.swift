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

class ViewControllerBasedCell<Child: UIViewController>: UIView {

    let viewController: Child

    var selectionView: UIView? {
        return viewController.view
    }

    init(viewController: Child) {
        self.viewController = viewController
        super.init(frame: .zero)
        configureSubviews()
        configureConstraints()
    }

    override init(frame: CGRect) {
        self.viewController = Child()
        super.init(frame: .zero)
        configureSubviews()
        configureConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isSelected: Bool = false

    private func configureSubviews() {
        addSubview(viewController.view)
    }

    private func configureConstraints() {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.fitInSuperview()
    }

}
