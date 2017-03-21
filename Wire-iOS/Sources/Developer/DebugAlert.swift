//
//  DebugAlert.swift
//  Wire-iOS
//
//  Created by Marco Conti on 21/03/2017.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation
import MessageUI

/// Presents debug alerts
@objc public class DebugAlert: NSObject {
    
    /// Presents an alert, if in developer mode, otherwise do nothing
    static func show(message: String, sendLogs: Bool = true) {
        guard DeveloperMenuState.developerMenuEnabled() else { return }
        guard let controller = UIApplication.shared.keyWindow?.rootViewController else { return }
        let alert = UIAlertController(title: "DEBUG MESSAGE",
                                      message: message,
                                      preferredStyle: .alert)
        if sendLogs {
            let sendLogAction = UIAlertAction(title: "Send logs", style: .cancel, handler: {
                _ in
                DebugLogSender.sendLogsByEmail()
            })
            alert.addAction(sendLogAction)
        }
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        controller.present(alert, animated: true, completion: nil)
    }
}

/// Sends debug logs by email
@objc public class DebugLogSender: NSObject, MFMailComposeViewControllerDelegate {

    private var mailViewController : MFMailComposeViewController? = nil
    static private var senderInstance: DebugLogSender? = nil

    /// Sends recorded logs by email
    static func sendLogsByEmail() {
        guard let controller = UIApplication.shared.keyWindow?.rootViewController else { return }
        guard self.senderInstance == nil else { return }
        
        let alert = DebugLogSender()
        let logs = ZMSLog.recordedContent
        guard !logs.isEmpty else {
            DebugAlert.show(message: "There are no logs to send, have you enabled them from the debug menu > log settings?", sendLogs: false)
            return
        }
        
        guard MFMailComposeViewController.canSendMail() else {
            DebugAlert.show(message: "You do not have an email account set up", sendLogs: false)
            return
        }
        
        // Prepare subject & body
        let user = ZMUser.selfUser()!
        let userID = user.remoteIdentifier?.transportString() ?? ""
        let device = UIDevice.current.name
        let now = Date()
        let userDescription = "\(user.name ?? "") [user: \(userID)] [device: \(device)]"
        let message = "Here are the logs from \(userDescription), at \(now)\n"
            + "It contains \(logs.count) log entries, please find them in the attached file"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timeStr = formatter.string(from: now)
        let fileName = "logs_\(user.name ?? userID)_T\(timeStr).txt"
        
        // compose
        let mailVC = MFMailComposeViewController()
        mailVC.setToRecipients(["ios@wire.com"])
        mailVC.setSubject("iOS logs from \(userDescription)")
        mailVC.setMessageBody(message, isHTML: false)
        let completeLog = logs.joined(separator: "\n")
        mailVC.addAttachmentData(completeLog.data(using: .utf8)!, mimeType: "text/plain", fileName: fileName)
        mailVC.mailComposeDelegate = alert
        alert.mailViewController = mailVC
        
        self.senderInstance = alert
        controller.present(mailVC, animated: true, completion: nil)
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController,
                                      didFinishWith result: MFMailComposeResult,
                                      error: Error?) {
        self.mailViewController = nil
        controller.dismiss(animated: true)
        type(of: self).senderInstance = nil
    }
}
