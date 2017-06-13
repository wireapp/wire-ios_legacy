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


#import "VersionInfoViewController.h"
#import "IconButton.h"
@import PureLayout;

@interface VersionInfoViewController ()
@property (nonatomic, strong) IconButton *closeButton;
@property (nonatomic, strong) UILabel *versionInfoLabel;
@end

@implementation VersionInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupCloseButton];
    [self setupVersionInfo];
}

- (void)setupCloseButton
{
    self.closeButton = [[IconButton alloc] initForAutoLayout];
    [self.view addSubview:self.closeButton];
    
    //Cosmetics
    [self.closeButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
    [self.closeButton setIconColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    //Layout
    [self.closeButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:24];
    [self.closeButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:18];
    
    //Target
    [self.closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupVersionInfo
{
    NSDictionary *versionsPlist = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ComponentsVersions" ofType:@"plist"]];

    self.versionInfoLabel = [[UILabel alloc] initForAutoLayout];
    self.versionInfoLabel.numberOfLines = 0;
    self.versionInfoLabel.backgroundColor = [UIColor clearColor];
    self.versionInfoLabel.textColor = [UIColor blackColor];
    self.versionInfoLabel.font = [UIFont systemFontOfSize:11];
    
    [self.view addSubview:self.versionInfoLabel];
    
    [self.versionInfoLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(80, 24, 24, 24)];
        
    NSMutableString *versionString = [NSMutableString stringWithCapacity:1024];
    
    NSDictionary *carthageInfo = versionsPlist[@"CarthageBuildInfo"];
    for (NSDictionary *dependency in carthageInfo) {
        [versionString appendFormat:@"\n%@ %@", dependency, carthageInfo[dependency]];
    }
    
    self.versionInfoLabel.text = versionString;
}

- (void)appendVersionDataForItem:(NSDictionary *)item toString:(NSMutableString *)string
{
    if ([item[@"version"] length] == 0) {
        return;
    }
    
    NSArray *allKeys = @[@"user", @"branch", @"time", @"job_name", @"sha", @"version", @"build_number"];
    
    for (NSString *key in allKeys) {
        [string appendFormat:@"%@: %@\n", key, item[key]];
    }
}

- (void)closeButtonTapped:(id)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
