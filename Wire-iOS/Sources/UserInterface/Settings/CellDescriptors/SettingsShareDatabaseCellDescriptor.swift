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
import ZipArchive

class DocumentDelegate : NSObject, UIDocumentInteractionControllerDelegate {
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return UIApplication.shared.wr_topmostController(onlyFullScreen: false)!
    }
    
    func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return CGRect.zero
    }
    
}


class SettingsShareDatabaseCellDescriptor : SettingsButtonCellDescriptor {
    
    let documentDelegate : DocumentDelegate
    
    init() {
        let documentDelegate = DocumentDelegate()
        self.documentDelegate = documentDelegate
        
        super.init(title: "Share Database", isDestructive: false) { _ in
            let fileURL = ZMUserSession.shared()!.managedObjectContext.zm_storeURL!
            let archiveURL = fileURL.appendingPathExtension("zip")
            
            SSZipArchive.createZipFile(atPath: archiveURL.path, withFilesAtPaths: [fileURL.path])
            
            let shareDatabaseDocumentController = UIDocumentInteractionController(url: archiveURL)
            shareDatabaseDocumentController.delegate = documentDelegate
            shareDatabaseDocumentController.presentPreview(animated: true)
        }
    
    }
    
}
