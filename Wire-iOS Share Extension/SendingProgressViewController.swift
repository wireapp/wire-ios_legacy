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

class SendingProgressViewController : UIViewController {

    var cancelHandler : (() -> Void)?
    
    private var progressLabel = UILabel()
    private var observers : [(Sendable, SendableObserverToken)] = []
    
    var progress: Float = 0 {
        didSet {
            progressLabel.text = "\(Int(progress * 100))%"
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
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

}
