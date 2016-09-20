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
import MessageUI

typealias TechnicalReport = [String: String]

class SettingsTechnicalReportViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    private enum TechnicalReportSection: Int {
        case Reports = 0
        case Options = 1
    }
    
    static private let technicalReportTitle = "TechnicalReportTitleKey"
    static private let technicalReportData = "TechnicalReportDataKey"
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
    
    lazy private var lastCallSessionReports: [TechnicalReport] = {
        let voiceChannelDebugString = ZMVoiceChannel.voiceChannelDebugInformation().string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let reportStrings = voiceChannelDebugString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        
        return reportStrings.reduce([TechnicalReport](), combine: { (reports, report) -> [TechnicalReport] in
            var mutableReports = reports
            if let separatorRange = report.rangeOfString(":") {
                let title = report.substringToIndex(separatorRange.startIndex)
                let data = report.substringFromIndex(separatorRange.startIndex.advancedBy(1))
                mutableReports.append([SettingsTechnicalReportViewController.technicalReportTitle: title, SettingsTechnicalReportViewController.technicalReportData: data])
            }
            
            return mutableReports
        })
    }()
    
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
        guard section == TechnicalReportSection.Reports.rawValue else {
            return 2
        }
        return lastCallSessionReports.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case TechnicalReportSection.Options.rawValue:
            return indexPath.row == 0 ? includedVoiceLogCell : sendReportCell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier(technicalReportReuseIdentifier, forIndexPath: indexPath)
            let technicalReport = lastCallSessionReports[indexPath.row]
            cell.detailTextLabel?.text = technicalReport[SettingsTechnicalReportViewController.technicalReportData]
            cell.textLabel?.text = technicalReport[SettingsTechnicalReportViewController.technicalReportTitle]
            return cell
            
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section > 0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case TechnicalReportSection.Reports.rawValue where indexPath.row == 0:
            includedVoiceLogCell.accessoryType = includedVoiceLogCell.accessoryType == .None ? .Checkmark : .None
        case TechnicalReportSection.Options.rawValue where indexPath.row == 1:
            sendReport()
        default:
            break
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
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