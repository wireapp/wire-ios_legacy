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
    //
    //@property (nonatomic) UITableViewCell *reportCell;
    //@property (nonatomic) UITableViewCell *sendReportCell;
    //@property (nonatomic) UITableViewCell *includeVoiceLogCell;
    //
    //@property (nonatomic) NSArray *technicalReports;
    
    //
    private var techReports: [TechReport]?
    
    private let techReportTitle = "TechnicalReportTitle"
    private let technicalReportData = "TechnicalReportData"
    private let technicalReportReuseIdentifier = "TechnicalReportCellReuseIdentifier"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("self.settings.technical_report_section.title", comment: "")
        tableView.scrollEnabled = false
        tableView.registerClass(TechInfoCell.self, forCellReuseIdentifier: technicalReportReuseIdentifier)
        
//        techReports =
    }
    
    func lastCallSessionReports() -> [TechReport] {
        var voiceChannelDebugInformation = ZMVoiceChannel.voiceChannelDebugInformation()
        let voiceChannelDebugString = ZMVoiceChannel.voiceChannelDebugInformation().string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let reportStrings = voiceChannelDebugString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        var reports = [TechReport]()
        
        
        return reportStrings.reduce([TechReport](), combine: { (reports, report) -> [TechReport] in
            var mutableReports = reports
            if let separatorRange = report.rangeOfString(":") {
                let title = report.substringToIndex(separatorRange.startIndex)
                let data = report.substringFromIndex(separatorRange.startIndex.advancedBy(1))
                mutableReports.append([techReportTitle: title, technicalReportData: data])
            }
            
            return mutableReports
        })
        //            NSAttributedString *voiceChannelDebugInformation = [ZMVoiceChannel voiceChannelDebugInformation];
        //            NSString *voiceChannelDebugString = [voiceChannelDebugInformation.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //            NSArray *reportStrings = [voiceChannelDebugString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        //            NSMutableArray *reports =  [NSMutableArray array];
        //
        //            for (NSString *reportString in reportStrings) {
        //                NSRange separatorRange = [reportString rangeOfString:@":"];
        //
        //                NSString *title = [reportString substringToIndex:separatorRange.location];
        //                NSString *data = [reportString substringFromIndex:separatorRange.location + 1];
        //
        //                [reports addObject:@{ TechnicalReportTitle   : title,
        //                TechnicalReportData    : data }];
        //            }
        //            
        //            return reports;
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
}



//#import "zmessaging+iOS.h"
//#import "UIColor+WAZExtensions.h"
//#import "Constants.h"
//#import "AppDelegate+Logging.h"

//@interface SettingsTechnicalReportViewController () <MFMailComposeViewControllerDelegate>
//
//
//@end
//
//@implementation SettingsTechnicalReportViewController
//
//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//    
//    self.title = NSLocalizedString(@"self.settings.technical_report_section.title", nil);
//    self.tableView.scrollEnabled = NO;
//    
//    [self.tableView registerClass:TechnicalInfoCell.class forCellReuseIdentifier:TechnicalReportCellReuseIdentifier];
//    
//    self.sendReportCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
//    self.sendReportCell.textLabel.text = NSLocalizedString(@"self.settings.technical_report.send_report", nil);
//    self.sendReportCell.textLabel.textColor = [UIColor accentColor];
//    
//    self.includeVoiceLogCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
//    self.includeVoiceLogCell.accessoryType = UITableViewCellAccessoryCheckmark;
//    self.includeVoiceLogCell.textLabel.text = NSLocalizedString(@"self.settings.technical_report.include_log", nil);
//    
//    self.technicalReports = [self lastCallSessionReports];
//    }
//    
//    - (NSArray *)lastCallSessionReports
//        {
//            NSAttributedString *voiceChannelDebugInformation = [ZMVoiceChannel voiceChannelDebugInformation];
//            NSString *voiceChannelDebugString = [voiceChannelDebugInformation.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//            NSArray *reportStrings = [voiceChannelDebugString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
//            NSMutableArray *reports =  [NSMutableArray array];
//            
//            for (NSString *reportString in reportStrings) {
//                NSRange separatorRange = [reportString rangeOfString:@":"];
//                
//                NSString *title = [reportString substringToIndex:separatorRange.location];
//                NSString *data = [reportString substringFromIndex:separatorRange.location + 1];
//                
//                [reports addObject:@{ TechnicalReportTitle   : title,
//                TechnicalReportData    : data }];
//            }
//            
//            return reports;
//        }
//        
//        - (void)sendReport
//            {
//                NSAttributedString *report = [ZMVoiceChannel voiceChannelDebugInformation];
//                
//                if ([MFMailComposeViewController canSendMail]) {
//                    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
//                    mailComposeViewController.mailComposeDelegate = self;
//                    [mailComposeViewController setToRecipients:@[NSLocalizedString(@"self.settings.technical_report.mail.recipient", nil)]];
//                    [mailComposeViewController setSubject:NSLocalizedString(@"self.settings.technical_report.mail.subject", nil)];
//                    
//                    NSData *attachmentData = [[AppDelegate sharedAppDelegate] currentVoiceLogData];
//                    if (attachmentData != nil && self.includeVoiceLogCell.accessoryType == UITableViewCellAccessoryCheckmark) {
//                        [mailComposeViewController addAttachmentData:attachmentData mimeType:@"text/plain" fileName:@"voice.log"];
//                    }
//                    
//                    [mailComposeViewController setMessageBody:report.string isHTML:NO];
//                    
//                    [self.navigationController presentViewController:mailComposeViewController animated:YES completion:nil];
//                } else {
//                    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[report] applicationActivities:nil];
//                    activityViewController.popoverPresentationController.sourceView = self.sendReportCell.textLabel;
//                    activityViewController.popoverPresentationController.sourceRect = self.sendReportCell.textLabel.bounds;
//                    
//                    [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
//                }
//}
//

//    - (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    if (section == 0) {
//        return self.technicalReports.count;
//    } else {
//        return 2;
//    }
//    }
//    
//    - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (indexPath.section == 0) {
//        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TechnicalReportCellReuseIdentifier forIndexPath:indexPath];
//        
//        NSDictionary *technicalReport = [self.technicalReports objectAtIndex:indexPath.row];
//        cell.textLabel.text = technicalReport[TechnicalReportTitle];
//        cell.detailTextLabel.text = technicalReport[TechnicalReportData];
//        
//        return cell;
//    } else {
//        return indexPath.row == 0 ? self.includeVoiceLogCell: self.sendReportCell;
//    }
//    }
//    
//    - (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return indexPath.section != 0;
//    }
//    
//    - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (indexPath.section == 1 && indexPath.row == 1) {
//        [self sendReport];
//    } else if (indexPath.section == 1 && indexPath.row == 0) {
//        self.includeVoiceLogCell.accessoryType = (self.includeVoiceLogCell.accessoryType == UITableViewCellAccessoryNone) ?  UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
//    }
//    
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//}
//
//#pragma mark MFMailComposeViewControllerDelegate
//
//- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
//{
//    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
//}

private class TechInfoCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}