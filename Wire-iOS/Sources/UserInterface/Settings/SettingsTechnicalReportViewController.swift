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
import Cartography

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
        sendReportCell = UITableViewCell(style: .default, reuseIdentifier: nil)
        sendReportCell.backgroundColor = UIColor.clear
        sendReportCell.textLabel?.text = "self.settings.technical_report.send_report".localized
        sendReportCell.textLabel?.textColor = UIColor.accent()
        sendReportCell.backgroundColor = UIColor.clear
        sendReportCell.backgroundView = UIView()
        sendReportCell.selectedBackgroundView = UIView()
        
        includedVoiceLogCell = UITableViewCell(style: .default, reuseIdentifier: nil)
        includedVoiceLogCell.accessoryType = .checkmark
        includedVoiceLogCell.textLabel?.text = "self.settings.technical_report.include_log".localized
        includedVoiceLogCell.textLabel?.textColor = UIColor.white
        includedVoiceLogCell.backgroundColor = UIColor.clear
        includedVoiceLogCell.backgroundView = UIView()
        includedVoiceLogCell.selectedBackgroundView = UIView()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("self.settings.technical_report_section.title", comment: "")
        tableView.backgroundColor = UIColor.clear
        tableView.isScrollEnabled = false
        tableView.separatorColor = UIColor(white: 1, alpha: 0.1)
        tableView.register(TechInfoCell.self, forCellReuseIdentifier: technicalReportReuseIdentifier)
    }
    
    lazy private var lastCallSessionReports: [TechnicalReport] = {
        let voiceChannelDebugString = ""
        let reportStrings = voiceChannelDebugString.components(separatedBy: .newlines)
        
        return reportStrings.reduce([TechnicalReport](), { (reports, report) -> [TechnicalReport] in
            var mutableReports = reports
            if let separatorRange = report.range(of:":") {
                let title = report.substring(to: separatorRange.lowerBound)
                let data = report.substring(from: report.index(separatorRange.lowerBound, offsetBy: 1))
                mutableReports.append([SettingsTechnicalReportViewController.technicalReportTitle: title, SettingsTechnicalReportViewController.technicalReportData: data])
            }
            
            return mutableReports
        })
    }()
    
    func sendReport() {
        let report = "Calling report"
        
        guard MFMailComposeViewController.canSendMail() else {
            let activityViewController = UIActivityViewController(activityItems: [report as Any], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = sendReportCell.textLabel
            guard let bounds = sendReportCell.textLabel?.bounds else { return }
            activityViewController.popoverPresentationController?.sourceRect = bounds
            self.present(activityViewController, animated: true, completion: nil)
            return
        }
        
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self
        mailComposeViewController.setToRecipients([NSLocalizedString("self.settings.technical_report.mail.recipient", comment: "")])
        mailComposeViewController.setSubject(NSLocalizedString("self.settings.technical_report.mail.subject", comment: ""))
        let attachmentData = AppDelegate.shared().currentVoiceLogData
        
        if attachmentData().count > 0 && includedVoiceLogCell.accessoryType == .checkmark {
            mailComposeViewController.addAttachmentData(attachmentData(), mimeType: "text/plain", fileName: "voice.log")
        }
        
        mailComposeViewController.setMessageBody(report, isHTML: false)
        self.present(mailComposeViewController, animated: true, completion: nil)
    }
    
    // MARK TableView Delegates

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == TechnicalReportSection.Reports.rawValue else { return 2 }
        return lastCallSessionReports.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case TechnicalReportSection.Options.rawValue:
            return indexPath.row == 0 ? includedVoiceLogCell : sendReportCell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: technicalReportReuseIdentifier, for: indexPath)
            let technicalReport = lastCallSessionReports[indexPath.row]
            cell.detailTextLabel?.text = technicalReport[SettingsTechnicalReportViewController.technicalReportData]
            cell.textLabel?.text = technicalReport[SettingsTechnicalReportViewController.technicalReportTitle]
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let section = TechnicalReportSection(rawValue: section) else {
            fatal("Unknown section")
        }
        
        switch (section) {
        case .Options:
        return 20
            
        default:
            break
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let section = TechnicalReportSection(rawValue: section) else {
            fatal("Unknown section")
        }
        
        switch (section) {
        case .Options:
            let label = UILabel()
            label.text = "self.settings.technical_report.privacy_warning".localized
            label.textColor = ColorScheme.default().color(withName: ColorSchemeColorTextDimmed)
            label.backgroundColor = .clear
            label.font = UIFont(magicIdentifier: "style.text.small.font_spec_light")
            
            let container = UIView()
            container.addSubview(label)
            container.layoutMargins = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
            
            constrain(label, container) { label, container in
                label.edges == container.edgesWithinMargins
            }
            
            return container
        default:
            break
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == TechnicalReportSection.Options.rawValue
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case TechnicalReportSection.Options.rawValue where indexPath.row == 0:
            includedVoiceLogCell.accessoryType = includedVoiceLogCell.accessoryType == .none ? .checkmark : .none
        case TechnicalReportSection.Options.rawValue where indexPath.row == 1:
            sendReport()
        default: break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: Mail Delegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

private class TechInfoCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear
        self.backgroundView = UIView()
        self.selectedBackgroundView = UIView()
        self.textLabel?.textColor = UIColor.white
        self.detailTextLabel?.textColor = UIColor(white: 1, alpha: 0.4)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
