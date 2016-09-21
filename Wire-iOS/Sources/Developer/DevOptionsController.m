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



#import "DevOptionsController.h"
#import "MagicConfig.h"
#import "Settings.h"
#import <PureLayout/PureLayout.h>
@import ZMCSystem;


@interface DevOptionsController ()

@property (nonatomic, strong) UISwitch *extrasSwitch;
@property (nonatomic, strong) UILabel *extrasLabel;


@property (nonatomic, strong) NSArray *switchesForLogTags;
@end




@interface DevOptionsLabelWithSwitch : NSObject

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UISwitch *uiSwitch;
@property (nonatomic, strong) NSString *tag;

@end


@implementation DevOptionsLabelWithSwitch
@end



@implementation DevOptionsController

- (void)loadView
{
    self.title = @"Options";
    self.view = [[UIView alloc] init];
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.extrasSwitch = [[UISwitch alloc] init];
    self.extrasSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.extrasSwitch.enabled = YES;
    [self.extrasSwitch addTarget:self action:@selector(enableExtrasSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.extrasSwitch];
    
    self.extrasLabel = [[UILabel alloc] initForAutoLayout];
    self.extrasLabel.text = @"Enable subtitles (will quit)";
    self.extrasLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.extrasLabel];
    
    NSMutableArray *switchesForLogTags = [NSMutableArray array];
    for(NSString *tag in ZMLogGetAllTags()) {
        DevOptionsLabelWithSwitch *labelSwitch = [[DevOptionsLabelWithSwitch alloc] init];
        labelSwitch.tag = tag;
        labelSwitch.label = [[UILabel alloc] initForAutoLayout];
        labelSwitch.label.textColor = [UIColor whiteColor];
        labelSwitch.label.text = [NSString stringWithFormat:@"Log %@", tag];
        [self.view addSubview:labelSwitch.label];
        
        labelSwitch.uiSwitch = [[UISwitch alloc] initForAutoLayout];
        labelSwitch.uiSwitch.enabled = YES;
        
        labelSwitch.uiSwitch.on = (ZMLogGetLevelForTag([tag UTF8String]) == ZMLogLevelDebug);
        [labelSwitch.uiSwitch addTarget:self action:@selector(logTagSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:labelSwitch.uiSwitch];
        
        [switchesForLogTags addObject:labelSwitch];
    }
    self.switchesForLogTags = switchesForLogTags;
    
    [self setupConstraints];
}

- (void)setupConstraints;
{
    CGFloat vOffset = 10.0;
    CGFloat hOffset = 24.0;
    [self.extrasSwitch autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:hOffset];
    [self.extrasSwitch autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:vOffset];
    
    [self.extrasLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.extrasSwitch withOffset:hOffset];
    [self.extrasLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.extrasSwitch];

    UIView *previousSwitch = self.extrasSwitch;

    for(DevOptionsLabelWithSwitch *labelSwitch in self.switchesForLogTags) {
        [labelSwitch.uiSwitch autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:hOffset];
        [labelSwitch.uiSwitch autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousSwitch withOffset:vOffset];
        
        [labelSwitch.label autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:labelSwitch.uiSwitch withOffset:hOffset];
        [labelSwitch.label autoAlignAxis:ALAxisHorizontal toSameAxisOfView:labelSwitch.uiSwitch];
        
        previousSwitch = labelSwitch.uiSwitch;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.extrasSwitch.on = [Settings sharedSettings].enableExtras;

}

- (void)logTagSwitchChanged:(id)sender
{
    // very inefficient linear search, but here performance is not an issue
    for(DevOptionsLabelWithSwitch *labelSwitch in self.switchesForLogTags) {
        if(labelSwitch.uiSwitch == sender) {
            ZMLogLevel_t level = labelSwitch.uiSwitch.on ? ZMLogLevelDebug : ZMLogLevelWarn;
            ZMLogSetLevelForTag(level, labelSwitch.tag.UTF8String);
            return;
        }
    }
}

- (void)enableExtrasSwitchChanged:(id)sender
{
    [Settings sharedSettings].enableExtras = self.extrasSwitch.on;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
}


@end

