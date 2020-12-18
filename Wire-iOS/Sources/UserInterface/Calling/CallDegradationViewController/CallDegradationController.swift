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
import WireDataModel

enum CallDegradationState: Equatable {
    case none
    case incoming(degradedUser: HashBoxUser?)
    case outgoing(degradedUser: HashBoxUser?)
}

protocol CallDegradationControllerDelegate: class {
    func continueDegradedCall()
    func cancelDegradedCall()
}

final class CallDegradationController: UIViewController {

    weak var delegate: CallDegradationControllerDelegate? = nil
    weak var targetViewController: UIViewController? = nil
    var visibleAlertController: UIAlertController? = nil
    
    // Used to delay presentation of the alert controller until
    // the view is ready.
    private var viewIsReady = false
    
    var state: CallDegradationState = .none {
        didSet {
            guard oldValue != state else { return }
            
            updateState()
        }
    }
        
    fileprivate func updateState() {
        switch state {
        case .outgoing(degradedUser: let degradeduser):
            visibleAlertController = UIAlertController.degradedCall(degradedUser: degradeduser?.value, confirmationBlock: { [weak self] (continueDegradedCall) in
                continueDegradedCall ? self?.delegate?.continueDegradedCall(): self?.delegate?.cancelDegradedCall()
            })
        case .none, .incoming(degradedUser: _):
            return
        }
        presentAlertIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewIsReady = true
        presentAlertIfNeeded()
    }

    private func presentAlertIfNeeded() {
        guard
            viewIsReady,
            let alertViewController = visibleAlertController,
            !alertViewController.isBeingPresented
            else { return }
        
        Log.calling.debug("Presenting alert about degraded call")
        targetViewController?.present(alertViewController, animated: !ProcessInfo.processInfo.isRunningTests)
    }
}
