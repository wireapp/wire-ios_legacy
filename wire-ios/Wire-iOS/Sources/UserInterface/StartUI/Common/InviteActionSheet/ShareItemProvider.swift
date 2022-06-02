// 
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

import UIKit

final class ShareItemProvider: UIActivityItemProvider {
    override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "send_invitation.subject".localized
    }

    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        guard
            let handle = SelfUser.provider?.selfUser.handle
        else {
            return "send_invitation_no_email.text".localized
        }

        let displayHandle = "@\(handle)"
        return String(format: "send_invitation.text".localized, displayHandle)
    }
}
