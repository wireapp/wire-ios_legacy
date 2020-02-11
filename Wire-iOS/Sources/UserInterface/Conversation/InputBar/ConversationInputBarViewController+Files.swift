
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

extension ConversationInputBarViewController {
    func execute(videoPermissions toExecute: @escaping () -> ()) {
        UIApplication.wr_requestOrWarnAboutVideoAccess({ granted in
            if granted {
                UIApplication.wr_requestOrWarnAboutMicrophoneAccess({ granted in
                    if granted {
                        toExecute()
                    }
                })
            }
        })
    }
    
    @objc
    func showAlertForFileTooBig() {
        guard let maxUploadFileSize = ZMUserSession.shared()?.maxUploadFileSize() else { return }
        
        let maxSizeString = ByteCountFormatter.string(fromByteCount: Int64(maxUploadFileSize), countStyle: .binary)
        let errorMessage = String(format: "content.file.too_big".localized, maxSizeString)
        let alert = UIAlertController.alertWithOKButton(message: errorMessage)
        present(alert, animated: true)
    }
}
