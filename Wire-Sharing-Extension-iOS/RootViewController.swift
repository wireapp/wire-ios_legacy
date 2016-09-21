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


import UIKit
import Classy
import WireExtensionComponents

class RootViewController: UIViewController {

    @IBOutlet fileprivate weak var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let colorScheme = ColorScheme.default()
        colorScheme?.accentColor = UIColor.accentColor
        CASStyler.default().apply(colorScheme)
        
        var error: NSError? = nil
        if let path = Bundle.main.path(forResource: "stylesheet-share-ext", ofType: "cas") {
            CASStyler.default().setFilePath(path, error: &error)
            if self.isCurrentTargetSimulator() == 1 {
                CASStyler.default().watchFilePath =
                    _CASAbsoluteFilePath(#file, "../Wire-iOS/Resources/Classy/stylesheet-share-ext.cas")
            }
        }
    }
    
    func isCurrentTargetSimulator() -> Int32 {
        return TARGET_IPHONE_SIMULATOR
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let window = self.view.window {
            CASStyler.default().targetWindows = [window]
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
