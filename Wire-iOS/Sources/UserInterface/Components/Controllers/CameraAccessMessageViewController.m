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


#import "CameraAccessMessageViewController.h"
#import "Wire-Swift.h"


@interface CameraAccessMessageViewController ()
@property (weak, nonatomic) IBOutlet UILabel *cameraAccessDeniedLabel;
@property (weak, nonatomic) IBOutlet UILabel *cameraAccessInstructionLabel;
@end



@implementation CameraAccessMessageViewController

- (NSString *)nibName
{
    return @"CameraAccessMessageViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cameraAccessDeniedLabel.text = NSLocalizedString(@"camera_access.denied", "");
    self.cameraAccessDeniedLabel.font = UIFont.normalMediumFont;
    self.cameraAccessDeniedLabel.textColor = [UIColor whiteColor];
    
    self.cameraAccessInstructionLabel.text = NSLocalizedString(@"camera_access.denied.instruction", "");
    self.cameraAccessInstructionLabel.font = UIFont.normalLightFont;
    self.cameraAccessInstructionLabel.textColor = [UIColor whiteColor];
}

@end
