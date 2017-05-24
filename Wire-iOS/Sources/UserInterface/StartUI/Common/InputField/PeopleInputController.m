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


#import "PeopleInputController.h"
@import WireExtensionComponents;
#import <PureLayout/PureLayout.h>
#import "Wire-Swift.h"

#import "WAZUIMagicIOS.h"
#import "UIColor+WAZExtensions.h"



@interface PeopleInputController () <TokenFieldDelegate, UserSelectionObserver>
@property (nonatomic, strong, readwrite) TokenField *tokenField;
@end



@implementation PeopleInputController

- (void)dealloc
{
    [self.userSelection removeWithObserver:self];
}

#pragma mark - UIViewController overrides

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupSubviews];
        [self setupConstraints];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setupSubviews];
        [self setupConstraints];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Setup

- (void)setupSubviews
{
    self.view.backgroundColor = [UIColor clearColor];
    
    // initial configuration for the input field
    self.tokenField = [[TokenField alloc] initForAutoLayout];
    self.tokenField.delegate = self;
    self.tokenField.textView.text = @"";
    
    // placeholder text
    self.tokenField.textView.placeholder = NSLocalizedString(@"peoplepicker.search_placeholder", "Search placeholder for people picker");
    self.tokenField.textView.accessibilityLabel = @"textViewSearch";
    self.tokenField.textView.keyboardAppearance = UIKeyboardAppearanceDark;
    [self.view addSubview:self.tokenField];
}

- (void)setupConstraints
{
    [self.tokenField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.tokenField autoSetDimension:ALDimensionHeight toSize:100 relation:NSLayoutRelationLessThanOrEqual];
    [self.tokenField autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.view withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
        [self.tokenField autoSetContentHuggingPriorityForAxis:ALAxisVertical];
    }];
}

#pragma mark - Properties

- (NSString *)plainTextContent
{
    NSString *plainText = [self.tokenField.filterText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (plainText == nil) {
        plainText = @"";
    }
    return plainText;
}

#pragma mark - Public Interface

- (void)setUserSelection:(UserSelection *)userSelection
{
    _userSelection = userSelection;
    
    [self.userSelection addWithObserver:self];
}

- (void)addTokenForUser:(ZMUser *)user
{
    [self.tokenField addTokenForTitle:user.displayName representedObject:user];
}

- (void)removeTokenForUser:(ZMUser *)user
{
    Token *token = [self.tokenField tokenForRepresentedObject:user];
    [self.tokenField removeToken:token];
}

- (void)removeAllTokens
{
    [self.tokenField removeAllTokens];
}

- (void)filterUnwantedAttachments
{
    [self.tokenField filterUnwantedAttachments];
}

- (BOOL)userDidConfirmInput
{
    return self.tokenField.userDidConfirmInput;
}

#pragma mark - UserSelectionDelegate

- (void)userSelection:(UserSelection *)userSelection didAddUser:(ZMUser *)user
{
    [self addTokenForUser:user];
}

- (void)userSelection:(UserSelection *)userSelection didRemoveUser:(ZMUser *)user
{
    [self removeTokenForUser:user];
}

- (void)userSelection:(UserSelection *)userSelection wasReplacedBy:(NSArray<ZMUser *> *)users
{
    // nop
}

#pragma mark - TokenFieldDelegate

- (void)tokenField:(TokenField *)tokenField changedTokensTo:(NSArray *)tokens
{
    NSArray *users = [tokens valueForKeyPath:@"@distinctUnionOfObjects.representedObject"];
    [self.userSelection replace:users];
    
//    if ([self.selectionDelegate respondsToSelector:@selector(peopleInputController:changedPresentedDirectoryResultsTo:)]) {
//        NSArray *users = [tokens valueForKeyPath:@"@distinctUnionOfObjects.representedObject"];
//        [self.selectionDelegate peopleInputController:self changedPresentedDirectoryResultsTo:[NSSet setWithArray:users]];
//    }
}

- (void)tokenField:(TokenField *)tokenField changedFilterTextTo:(NSString *)text
{
    if ([self.delegate respondsToSelector:@selector(peopleInputController:changedFilterTextTo:)]) {
        [self.delegate peopleInputController:self changedFilterTextTo:text];
    }
}

- (void)tokenFieldDidBeginEditing:(TokenField *)tokenField
{
    
}

- (void)tokenFieldWillScroll:(TokenField *)tokenField
{
    
}

- (void)tokenFieldDidConfirmSelection:(TokenField *)controller
{
    if ([self.delegate respondsToSelector:@selector(peopleInputControllerDidConfirmInput:)]) {
        [self.delegate peopleInputControllerDidConfirmInput:self];
    }
}

@end


