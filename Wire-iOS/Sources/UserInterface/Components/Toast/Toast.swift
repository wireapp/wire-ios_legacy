//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

final class Toast {
    static weak var toastView: ToastView?
    
    static func show(configuration: ToastConfiguration, completion: ((Bool) -> Void)? = nil) {
        guard
            toastView == nil,
            let window = UIApplication.shared.topMostVisibleWindow
            else { return }
        
        let toast = ToastView(configuration: configuration)
        toastView = toast
        
        toast.translatesAutoresizingMaskIntoConstraints = false
        toast.alpha = 0
        
        window.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            toast.topAnchor.constraint(equalTo: window.safeTopAnchor, constant: 20),
            toast.widthAnchor.constraint(equalTo: window.widthAnchor, multiplier: 0.9, constant: 0)
        ])
        
        UIView.animate(withDuration: 0.2, animations: {
            toast.alpha = 1.0
        }, completion: nil)
    }
    
    static func hide() {
        toastView?.removeFromSuperview()
    }
}
