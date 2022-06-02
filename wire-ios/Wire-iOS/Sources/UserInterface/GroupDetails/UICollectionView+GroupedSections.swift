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

fileprivate extension UICollectionViewFlowLayout {
    convenience init(forGroupedSections: ()) {
        self.init()
        scrollDirection = .vertical
        minimumInteritemSpacing = 12
        minimumLineSpacing = 0
    }
}

extension UICollectionView {
    convenience init(forGroupedSections: ()) {
        self.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout(forGroupedSections: ()))
        backgroundColor = .clear
        allowsMultipleSelection = false
        keyboardDismissMode = .onDrag
        bounces = true
        alwaysBounceVertical = true
        contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 32, right: 0)
    }
}
