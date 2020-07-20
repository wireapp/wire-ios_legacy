
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

final class UnlockViewController: UIViewController {
    
    private let shieldView = UIView.shieldView()
    private let blurView: UIVisualEffectView = UIVisualEffectView.blurView()
    
    convenience init() {
        self.init(nibName:nil, bundle:nil)
        
        view.addSubview(shieldView)
        view.addSubview(blurView)
        
        createConstraints()
    }
    
    private func createConstraints(/*nibView: UIView*/) {
        [shieldView, blurView].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // nibView
            shieldView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shieldView.topAnchor.constraint(equalTo: view.topAnchor),
            shieldView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shieldView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // blurView
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

}
