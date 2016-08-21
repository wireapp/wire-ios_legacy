//
//  SettingsTechReportViewController.swift
//  Wire-iOS
//
//  Created by Kevin Taniguchi on 8/20/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit
import MessageUI

typealias TechReport = [String: String]

class SettingsTechReportViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    private let techReportTitle = "TechnicalReportTitle"
    private let technicalReportData = "TechnicalReportData"
    private let technicalReportReuseIdentifier = "TechnicalReportCellReuseIdentifier"
    
    private let includedVoiceLogCell: UITableViewCell
    private let sendReportCell: UITableViewCell
    
    init() {
        sendReportCell = UITableViewCell(style: .Default, reuseIdentifier: nil)
        sendReportCell.textLabel?.text = NSLocalizedString("self.settings.technical_report.send_report", comment: "")
        sendReportCell.textLabel?.textColor = UIColor.accentColor()
        includedVoiceLogCell = UITableViewCell(style: .Default, reuseIdentifier: nil)
        includedVoiceLogCell.accessoryType = .Checkmark
        includedVoiceLogCell.textLabel?.text = NSLocalizedString("self.settings.technical_report.include_log", comment: "")
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("self.settings.technical_report_section.title", comment: "")
        tableView.scrollEnabled = false
        tableView.registerClass(TechInfoCell.self, forCellReuseIdentifier: technicalReportReuseIdentifier)
    }
    
    private var lastCallSessionReports: [TechReport] {
        let voiceChannelDebugString = ZMVoiceChannel.voiceChannelDebugInformation().string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let reportStrings = voiceChannelDebugString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        
        return reportStrings.reduce([TechReport](), combine: { (reports, report) -> [TechReport] in
            var mutableReports = reports
            if let separatorRange = report.rangeOfString(":") {
                let title = report.substringToIndex(separatorRange.startIndex)
                let data = report.substringFromIndex(separatorRange.startIndex.advancedBy(1))
                mutableReports.append([techReportTitle: title, technicalReportData: data])
            }
            
            return mutableReports
        })
    }
    
    func sendReport() {
        let report = ZMVoiceChannel.voiceChannelDebugInformation()
        
        guard MFMailComposeViewController.canSendMail() else {
            let activityViewController = UIActivityViewController(activityItems: [report], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = sendReportCell.textLabel
            guard let bounds = sendReportCell.textLabel?.bounds else { return }
            activityViewController.popoverPresentationController?.sourceRect = bounds
            navigationController?.presentViewController(activityViewController, animated: true, completion: nil)
            return
        }
        
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self
        mailComposeViewController.setToRecipients([NSLocalizedString("self.settings.technical_report.mail.recipient", comment: "")])
        mailComposeViewController.setSubject(NSLocalizedString("self.settings.technical_report.mail.subject", comment: ""))
        let attachmentData = AppDelegate.sharedAppDelegate().currentVoiceLogData
        
        if attachmentData().length > 0 && includedVoiceLogCell.accessoryType == .Checkmark {
            mailComposeViewController.addAttachmentData(attachmentData(), mimeType: "text/plain", fileName: "voice.log")
        }
        
        mailComposeViewController.setMessageBody(report.string, isHTML: false)
        navigationController?.presentViewController(mailComposeViewController, animated: true, completion: nil)
    }

    // MARK TableView Delegates
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 0 else {
            return 2
        }
        return lastCallSessionReports.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            return indexPath.row == 0 ? includedVoiceLogCell : sendReportCell
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(technicalReportReuseIdentifier, forIndexPath: indexPath)
        let techReport = lastCallSessionReports[indexPath.row]
        cell.detailTextLabel?.text = techReport[technicalReportData]
        return cell
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section > 0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        guard indexPath.section == 1 && indexPath.row == 1 else {
            guard indexPath.section == 0 && indexPath.row == 0 else { return }
            includedVoiceLogCell.accessoryType = includedVoiceLogCell.accessoryType == .None ? .Checkmark : .None
            return
        }
        sendReport()
    }
    
    // MARK: Mail Delegate
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

private class TechInfoCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}