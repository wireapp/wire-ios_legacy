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
@property (nonatomic, strong) NSString *componentsVersionsFilepath;
@end

@implementation VersionInfoViewController

- (instancetype) initWithComponentsVersionsFilepath: (NSString *)path
{

    self = [super initWithNibName:nil bundle:nil];

    self.componentsVersionsFilepath = path;

    return self;
}

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
    NSDictionary *versionsPlist = [NSDictionary dictionaryWithContentsOfFile:self.componentsVersionsFilepath]; ///TODO: inject a dummy plist

    /*
     {
     CarthageBuildInfo =     {
     Cartography = "3.0.3";
     DifferenceKit = "0.8.1";
     Down = "v2.1.1";
     FLAnimatedImage = "1.0.12-wire";
     FormatterKit = "1.8.1-swift3.0.2";
     HTMLString = "4.0.2-xcode_10_1";
     "HockeySDK-iOS" = "5.1.4";
     PINCache = "2.3-swift3.1";
     PureLayout = "v3.0.0";
     ZipArchive = "v2.1.3";
     "avs-ios-binaries" = "4.9.12";
     "ios-snapshot-test-case" = "4.0.0-xcode_10_1";
     "libPhoneNumber-iOS" = "0.9.3";
     ocmock = "v3.4.3";
     ono = "1.4.0";
     "protobuf-objc" = "1.9.14";
     "swift-protobuf" = "1.2.1";
     "wire-ios-canvas" = "9.0.2";
     "wire-ios-cryptobox" = "17.0.0";
     "wire-ios-data-model" = "160.0.0";
     "wire-ios-images" = "23.0.0";
     "wire-ios-link-preview" = "17.0.0";
     "wire-ios-protos" = "19.0.0";
     "wire-ios-request-strategy" = "139.0.0";
     "wire-ios-share-engine" = "128.0.0";
     "wire-ios-sync-engine" = "239.0.1";
     "wire-ios-system" = "26.0.0";
     "wire-ios-testing" = "18.0.0";
     "wire-ios-transport" = "53.0.0";
     "wire-ios-utilities" = "28.1.0";
     "wire-ios-ziphy" = "12.0.2";
     };
     }
     */

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
