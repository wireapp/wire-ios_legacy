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


#import "GiphyNavigationBarController.h"
#import "GiphyNavigationBar.h"
#import "IconButton.h"
#import "UIFont+MagicAccess.h"
#import "UIImage+ZetaIconsNeue.h"
#import "UIColor+WR_ColorScheme.h"

#import <Classy/Classy.h>

@interface GiphyNavigationBarController ()

@property (nonatomic, readwrite) GiphyNavigationBarControllerState state;

@end

@implementation GiphyNavigationBarController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupNavigationBar];
}

- (void)setupNavigationBar
{
    GiphyNavigationBar *navBar =  (GiphyNavigationBar *)self.view;
    
    [navBar.rightButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [navBar.rightButton addTarget:self action:@selector(rightButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [navBar.leftButton setIcon:ZetaIconTypeGiphy withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [navBar.leftButton addTarget:self action:@selector(leftButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [navBar.centerButton addTarget:self action:@selector(centerButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    navBar.centerButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    navBar.centerButton.titleLabel.textAlignment = NSTextAlignmentCenter;
}


- (void)loadView
{
    self.view = [[GiphyNavigationBar alloc] init];
}

- (void)transitionToState:(GiphyNavigationBarControllerState)state
{
    if (self.state == state){
        return;
    }
    
    GiphyNavigationBar *navBar = (GiphyNavigationBar *)self.view;
    
    if (state == GiphyNavigationBarControllerStatePushed) {
        [navBar.leftButton setIcon:ZetaIconTypeChevronLeft withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    }
    else if (state == GiphyNavigationBarControllerStateInitial){
        [navBar.leftButton setIcon:ZetaIconTypeGiphy withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    }
    
    self.state = state;
}

- (void)setCentralTitle:(NSString *)title subTitle:(NSString *)subTitle
{
    GiphyNavigationBar *navBar = (GiphyNavigationBar *)self.view;
    
    NSString *completeString = [NSString stringWithFormat:@"%@\n%@", title, subTitle];
    NSRange titleRange = [completeString rangeOfString:title];
    NSRange subTitleRange = [completeString rangeOfString:subTitle];
    
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:completeString];
    [attributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground] range:NSMakeRange(0, completeString.length)];
    [attributedTitle addAttribute:NSFontAttributeName value:[UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_bold"] range:titleRange];
    [attributedTitle addAttribute:NSFontAttributeName value:[UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"] range:subTitleRange];

    [navBar.centerButton setAttributedTitle:[[NSAttributedString alloc] initWithAttributedString:attributedTitle]
                                                                                        forState:UIControlStateNormal];
}

#pragma mark - Actions

- (void)rightButtonTapped:(id)sender
{
    if (self.onCancelTapped){
        self.onCancelTapped();
    }
}

- (IBAction)leftButtonTapped:(id)sender
{
    switch (self.state) {
        case GiphyNavigationBarControllerStateInitial:
            if (self.onGiphyButtonTapped) {
                self.onGiphyButtonTapped();
            }
            break;
        case GiphyNavigationBarControllerStatePushed:
            if (self.onBackButtonTapped) {
                self.onBackButtonTapped();
            }
            break;
    }
}

- (IBAction)centerButtonTapped:(id)sender
{
    if (self.onTitleTapped){
        self.onTitleTapped();
    }
}

@end
