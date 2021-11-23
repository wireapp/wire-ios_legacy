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

protocol ClientListViewControllerDelegate: AnyObject {
    func finishedDeleting(_ clientListViewController: ClientListViewController)
}

protocol ClientColorVariantProtocol {
    var variant: ColorSchemeVariant? { get set }
    var headerFooterViewTextColor: UIColor { get }
    var separatorColor: UIColor { get }
    func setColor(for variant: ColorSchemeVariant?)
}

extension ClientColorVariantProtocol where Self: UIViewController {

    var headerFooterViewTextColor: UIColor {
        switch variant {
        case .none, .dark?:
            return UIColor(white: 1, alpha: 0.4)
        case .light?:
            return UIColor.from(scheme: .textForeground, variant: .light)
        }
    }

    var separatorColor: UIColor {
        switch variant {
        case .none, .dark?:
            return UIColor(white: 1, alpha: 0.1)
        case .light?:
            return UIColor.from(scheme: .separator, variant: .light)
        }
    }

    func setColor(for variant: ColorSchemeVariant?) {
        switch variant {
        case .none:
            view.backgroundColor = .clear
        case .dark?:
            view.backgroundColor = .black
        case .light?:
            view.backgroundColor = .white
        }
    }
}
