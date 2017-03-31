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


#import "MagicConfig.h"
#import "WAZUIMagicIOS.h"
#import "UIColor+WAZExtensions.h"
#import "Settings.h"
#import "Constants.h"

// Base config files (no overlap)
static NSString *const MagicConfigFileBaseStyles        = @"style.plist";
static NSString *const MagicConfigFileFramework         = @"framework.plist";
static NSString *const MagicConfigFileConversation      = @"conversation.plist";
static NSString *const MagicConfigFilePeoplePicker      = @"people_picker.plist";
static NSString *const MagicConfigFileProfile           = @"profile.plist";
static NSString *const MagicConfigFileTutorial          = @"tutorial.plist";
static NSString *const MagicConfigFileMisc              = @"misc.plist";


// Override files
static NSString *const MagicConfigFileIPad              = @"ipad.plist";
static NSString *const MagicConfigFileIPhone6           = @"iphone6.plist";
static NSString *const MagicConfigFileIPhone4           = @"iphone4.plist";



@interface MagicConfig (DeviceConfig)

- (NSArray *)configForIPad;
- (NSArray *)configForIPhone6;
- (NSArray *)configForIPhone4;
- (NSArray *)configForIPhone;

@end




@interface MagicConfig () <WAZUIMagicDelegate>

@property (nonatomic, assign) UIInterfaceOrientation currentOrientation;
@property (nonatomic, strong) NSSet *baseFiles;

@end



@implementation MagicConfig

+ (MagicConfig *)sharedConfig
{
    static MagicConfig *sharedConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedConfig = [[MagicConfig alloc] initWithDefaultConfig];
    });
    
    return sharedConfig;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupWithDefaultFiles];
    }
    return self;
}

- (instancetype)initWithDefaultConfig
{
    self = [super init];
    if (self) {
        [self setupWithDefaultFiles];
    }
    return self;
}

- (instancetype)initWithFiles:(NSArray *)magicFiles
{
    self = [super init];
    if (self) {
        [self setupWithFiles:magicFiles];
    }
    return self;
}

- (void)setupWithDefaultFiles
{
    // Currently, all base files are completely orthogonal (ie: no overlap of magic values).  Any overrides should be done
    // in different files
    self.baseFiles = [NSSet setWithArray:@[MagicConfigFileBaseStyles,
                                           MagicConfigFileConversation,
                                           MagicConfigFileFramework,
                                           MagicConfigFileMisc,
                                           MagicConfigFilePeoplePicker,
                                           MagicConfigFileProfile,
                                           MagicConfigFileTutorial]];
    
    // These are the files for overriding values
    NSSet *allFiles = [self.baseFiles setByAddingObjectsFromArray:@[MagicConfigFileIPad,
                                                                    MagicConfigFileIPhone6,
                                                                    MagicConfigFileIPhone4]];
    
    [self setupWithFiles:[allFiles allObjects]];
}

- (void)setupWithFiles:(NSArray *)magicFiles
{
    // Preload all config files in order of override
    [WAZUIMagic preloadItems:magicFiles];
    [WAZUIMagic sharedMagic].delegate = self;
    
    [self applyCurrentConfig];
}

- (void)applyCurrentConfig
{
    [self applyCurrentConfigAndForceReload:YES];
}

- (void)applyCurrentConfigAndForceReload:(BOOL)force
{
    [self activateMagicConfigurationForInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation force:force];
}

- (void)activateMagicConfigurationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    [self activateMagicConfigurationForInterfaceOrientation:orientation force:NO];
}

- (void)activateMagicConfigurationForInterfaceOrientation:(UIInterfaceOrientation)orientation force:(BOOL)force
{
    if (orientation == self.currentOrientation && ! force) {
        return;
    }
    
    NSArray *deviceConfig = nil;
    
    if (IS_IPAD) {
        deviceConfig = [self configForIPad];
    }
    else if (IS_IPHONE_6 || IS_IPHONE_6_PLUS_OR_BIGGER) {
        deviceConfig = [self configForIPhone6];
    }
    else if (IS_IPHONE_4) {
        deviceConfig = [self configForIPhone4];
    }
    else {
        deviceConfig = [self configForIPhone];
    }

    [WAZUIMagic activateItems:deviceConfig];
}

#pragma mark WAZUIMagicDelegate
- (UIColor *)accentColor
{
    return [UIColor accentColor];
}

@end



@implementation MagicConfig (DeviceConfig)

- (NSArray *)configForIPad
{
    return [self appendOverrideFilesToBaseConfig:@[MagicConfigFileIPad]];
}

- (NSArray *)configForIPhone6
{
    return [self appendOverrideFilesToBaseConfig:@[MagicConfigFileIPhone6]];
}

- (NSArray *)configForIPhone4
{
    return [self appendOverrideFilesToBaseConfig:@[MagicConfigFileIPhone4]];
}

- (NSArray *)configForIPhone
{
    return [self.baseFiles allObjects];
}

- (NSArray *)appendOverrideFilesToBaseConfig:(NSArray *)overrideFiles
{
    NSArray *baseFiles = [self.baseFiles allObjects];
    return [baseFiles arrayByAddingObjectsFromArray:overrideFiles];
}

@end
