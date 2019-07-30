//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

enum BlockerViewControllerContext {
    case blacklist
    case jailbroken
    case wipedFromJailbreak
}

class BlockerViewController : LaunchImageViewController {
    
    private var context: BlockerViewControllerContext = .blacklist
    var applicationDidBecomeActiveToken : NSObjectProtocol? = nil
    
    init(context: BlockerViewControllerContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showAlert()
    }
    
    func showAlert() {
        switch context {
        case .blacklist:
            showBlacklistMessage()
        case .jailbroken:
            showJailbrokenMessage()
        case .wipedFromJailbreak:
            showWipedFromJailbreakMessage()
        }
    }
    
    func showBlacklistMessage() {
        let alertController = UIAlertController(title: "force.update.title".localized, message: "force.update.message".localized, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "force.update.ok_button".localized, style: .default) { (_) in
            UIApplication.shared.open(URL.wr_wireAppOnItunes)
        }
        
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func showJailbrokenMessage() {
        // TODO change copy
        let alertController = UIAlertController(title: "jailbrokendevice.alert.title".localized, message: "jailbrokendevice.alert.message".localized, preferredStyle: .alert)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func showWipedFromJailbreakMessage() {
        // TODO change copy
        let alertController = UIAlertController(title: "Jailbroken device", message: "Wiped database", preferredStyle: .alert)
        
        present(alertController, animated: true, completion: nil)
    }
    
}
