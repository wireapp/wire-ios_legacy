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

import Foundation
import WireExtensionComponents
import WireShareEngine
import Cartography

class SendingProgressViewController : UIViewController, SendableObserver {
    
    var sentHandler : (() -> Void)?
    var cancelHandler : (() -> Void)?
    
    private var progressLabel = UILabel()
    private var observers : [(Sendable, SendableObserverToken)] = []
    
    var totalProgress : Float {
        var totalProgress : Float = 0.0
        
        observers.forEach { (message, _) in
            if message.deliveryState == .sent || message.deliveryState == .delivered {
                totalProgress = totalProgress + 1.0 / Float(observers.count)
            } else {
                let messageProgress = (message.deliveryProgress ?? 0)
                totalProgress = totalProgress +  messageProgress / Float(observers.count)
            }
        }
        
        return totalProgress
    }
    
    var isAllMessagesDelivered : Bool {
        return observers.reduce(true) { (result, observer) -> Bool in
            return result && (observer.0.deliveryState == .sent || observer.0.deliveryState == .delivered)
        }
    }
    
    init(messages: [Sendable]) {
        super.init(nibName: nil, bundle: nil)
        
        messages.forEach {message in
            observers.append((message, (message.registerObserverToken(self))))
        }
    }
    
    deinit {
        observers.forEach { (message, token) in
            message.remove(token)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelTapped))
        
        progressLabel.text = "0%";
        progressLabel.textAlignment = .center
        progressLabel.font = UIFont.systemFont(ofSize: 32)
        
        view.addSubview(progressLabel)
        
        constrain(view, progressLabel) { container, progressLabel in
            progressLabel.edges == container.edgesWithinMargins
        }
    }
    
    func onCancelTapped() {
        observers.filter {
            $0.0.deliveryState != .sent && $0.0.deliveryState != .delivered
            }.forEach {
                $0.0.cancel()
        }
        cancelHandler?()
    }
    
    func onDeliveryChanged() {
        progressLabel.text = "\(Int(self.totalProgress * 100))%"
        
        if self.isAllMessagesDelivered {
            sentHandler?()
        }
    }
}
