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


#import "SettingsTechnicalReportViewController.h"

#import <MessageUI/MessageUI.h>

#import "zmessaging+iOS.h"
#import "UIColor+WAZExtensions.h"
#import "Constants.h"
#import "AppDelegate+Logging.h"


static NSString const * TechnicalReportTitle = @"TechnicalReportTitle";
static NSString const * TechnicalReportData = @"TechnicalReportData";

static NSString * TechnicalReportCellReuseIdentifier = @"TechnicalReportCellReuseIdentifier";

@interface TechnicalInfoCell : UITableViewCell

@end


@implementation TechnicalInfoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
}

@end

@interface SettingsTechnicalReportViewController () <MFMailComposeViewControllerDelegate>

@property (nonatomic) UITableViewCell *reportCell;
@property (nonatomic) UITableViewCell *sendReportCell;
@property (nonatomic) UITableViewCell *includeVoiceLogCell;

@property (nonatomic) NSArray *technicalReports;

@end

@implementation SettingsTechnicalReportViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"self.settings.technical_report_section.title", nil);
    self.tableView.scrollEnabled = NO;
    
    [self.tableView registerClass:TechnicalInfoCell.class forCellReuseIdentifier:TechnicalReportCellReuseIdentifier];
    
    self.sendReportCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    self.sendReportCell.textLabel.text = NSLocalizedString(@"self.settings.technical_report.send_report", nil);
    self.sendReportCell.textLabel.textColor = [UIColor accentColor];
    
    self.includeVoiceLogCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    self.includeVoiceLogCell.accessoryType = UITableViewCellAccessoryCheckmark;
    self.includeVoiceLogCell.textLabel.text = NSLocalizedString(@"self.settings.technical_report.include_log", nil);
    
    self.technicalReports = [self lastCallSessionReports];
}

- (NSArray *)lastCallSessionReports
{
    NSAttributedString *voiceChannelDebugInformation = [ZMVoiceChannel voiceChannelDebugInformation];
    NSString *voiceChannelDebugString = [voiceChannelDebugInformation.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *reportStrings = [voiceChannelDebugString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *reports =  [NSMutableArray array];
    
    for (NSString *reportString in reportStrings) {
        NSRange separatorRange = [reportString rangeOfString:@":"];
        
        NSString *title = [reportString substringToIndex:separatorRange.location];
        NSString *data = [reportString substringFromIndex:separatorRange.location + 1];
        
        [reports addObject:@{ TechnicalReportTitle   : title,
                              TechnicalReportData    : data }];
    }
    
    return reports;
}

- (void)sendReport
{
    NSAttributedString *report = [ZMVoiceChannel voiceChannelDebugInformation];
    
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
        mailComposeViewController.mailComposeDelegate = self;
        [mailComposeViewController setToRecipients:@[NSLocalizedString(@"self.settings.technical_report.mail.recipient", nil)]];
        [mailComposeViewController setSubject:NSLocalizedString(@"self.settings.technical_report.mail.subject", nil)];

        NSData *attachmentData = [[AppDelegate sharedAppDelegate] currentVoiceLogData];
        if (attachmentData != nil && self.includeVoiceLogCell.accessoryType == UITableViewCellAccessoryCheckmark) {
            [mailComposeViewController addAttachmentData:attachmentData mimeType:@"text/plain" fileName:@"voice.log"];
        }

        [mailComposeViewController setMessageBody:report.string isHTML:NO];
        
        [self.navigationController presentViewController:mailComposeViewController animated:YES completion:nil];
    } else {
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[report] applicationActivities:nil];
        activityViewController.popoverPresentationController.sourceView = self.sendReportCell.textLabel;
        activityViewController.popoverPresentationController.sourceRect = self.sendReportCell.textLabel.bounds;
        
        [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.technicalReports.count;
    } else {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TechnicalReportCellReuseIdentifier forIndexPath:indexPath];
        
        NSDictionary *technicalReport = [self.technicalReports objectAtIndex:indexPath.row];
        cell.textLabel.text = technicalReport[TechnicalReportTitle];
        cell.detailTextLabel.text = technicalReport[TechnicalReportData];
        
        return cell;
    } else {
        return indexPath.row == 0 ? self.includeVoiceLogCell: self.sendReportCell;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section != 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row == 1) {
        [self sendReport];
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        self.includeVoiceLogCell.accessoryType = (self.includeVoiceLogCell.accessoryType == UITableViewCellAccessoryNone) ?  UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
