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
import WireSyncEngine
import MessageUI


class EmailInvitePresenter: NSObject, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate {
    static let sharedInstance: EmailInvitePresenter = EmailInvitePresenter()

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: .none)
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: .none)
    }
}


extension ZMAddressBookContact {

    static func canInviteLocallyWithEmail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }

    func inviteLocallyWithEmail(_ email: String) {
        let composeController = MFMailComposeViewController()
        composeController.mailComposeDelegate = EmailInvitePresenter.sharedInstance
        composeController.modalPresentationStyle = .formSheet

        composeController.setMessageBody(invitationBody(), isHTML: false)
        composeController.setToRecipients([email])
        ZClientViewController.shared?.present(composeController, animated: true, completion: .none)
    }

    static func canInviteLocallyWithPhoneNumber() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }

    func inviteLocallyWithPhoneNumber(_ phoneNumber: String) {
        let composeController = MFMessageComposeViewController()
        composeController.messageComposeDelegate = EmailInvitePresenter.sharedInstance
        composeController.modalPresentationStyle = .formSheet
        composeController.body = invitationBody()
        composeController.recipients = [phoneNumber]
        ZClientViewController.shared?.present(composeController, animated: true, completion: .none)
    }

    private func invitationBody() -> String {
        guard
            let handle = SelfUser.provider?.selfUser.handle
        else {
            return "send_invitation_no_email.text".localized
        }

        return "send_invitation.text".localized(args: "@" + handle)
    }
}
