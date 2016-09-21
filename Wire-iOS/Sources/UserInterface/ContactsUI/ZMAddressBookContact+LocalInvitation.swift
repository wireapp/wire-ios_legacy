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
import zmessaging
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
    public static func canInviteLocallyWithEmail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    public func inviteLocallyWithEmail(_ email: String) {
        let composeController = MFMailComposeViewController()
        composeController.mailComposeDelegate = EmailInvitePresenter.sharedInstance
        composeController.modalPresentationStyle = .formSheet
        composeController.setMessageBody("send_personal_invitation.text".localized, isHTML: false)
        composeController.setToRecipients([email])
        ZClientViewController.sharedZClientViewController().presentViewController(composeController, animated: true, completion: .None)
    }
    
    public static func canInviteLocallyWithPhoneNumber() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }
    
    public func inviteLocallyWithPhoneNumber(_ phoneNumber: String) {
        let composeController = MFMessageComposeViewController()
        composeController.messageComposeDelegate = EmailInvitePresenter.sharedInstance
        composeController.modalPresentationStyle = .formSheet
        composeController.body = "send_personal_invitation.text".localized
        composeController.recipients = [phoneNumber]
        ZClientViewController.sharedZClientViewController().presentViewController(composeController, animated: true, completion: .None)
    }
}
