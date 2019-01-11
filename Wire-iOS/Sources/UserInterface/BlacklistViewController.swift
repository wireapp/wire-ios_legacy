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

import Foundation

class BlacklistViewController : LaunchImageViewController {
    
    var applicationDidBecomeActiveToken : NSObjectProtocol? = nil
    
    deinit {
        if let token = applicationDidBecomeActiveToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applicationDidBecomeActiveToken = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self](_) in
            self?.showAlert()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showAlert()
    }
    
    func showAlert() {
        let alertController = UIAlertController(title: "force.update.title".localized, message: "force.update.message".localized, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "force.update.ok_button".localized, style: .default) { (_) in
            UIApplication.shared.open(URL.wr_wireAppOnItunes)
        }
        
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
}
