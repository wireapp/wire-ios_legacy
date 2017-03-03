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


#import <PureLayout/PureLayout.h>


#import "ParticipantsChangedView.h"
#import "zmessaging+iOS.h"
#import "Constants.h"
#import "WAZUIMagicIOS.h"
#import "BadgeUserImageView.h"
#import "UIColor+WR_ColorScheme.h"
#import "NSAttributedString+Wire.h"
#import "UserImageView+Magic.h"


static CGFloat const MaxVisibleUserViews        = 4;
static CGFloat const MaxVisibleUserViewsIPad    = 5;



@interface ParticipantsChangedView ()

@property (nonatomic, strong) UIView *userViewContainer;
@property (nonatomic, strong) UILabel *moreUsersLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@property (nonatomic, strong) NSParagraphStyle *subtitleParagraphStyle;

@property (nonatomic, strong) NSMutableArray <BadgeUserImageView *> *userViews;
@property (nonatomic, strong) NSArray *userViewSpacingConstraints;
@property (nonatomic, strong) NSArray *userViewWidthConstraints;

// Magic values
@property (nonatomic, assign) CGFloat singleTileImageDiameter;
@property (nonatomic, assign) CGFloat multiTileImageDiameter;
@property (nonatomic, assign) CGFloat multiTileImageSpacing;

@end

@implementation ParticipantsChangedView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self createViews];
        [self createConstraints];
    }
    
    return self;
}

- (NSUInteger)maxVisibleUsers
{
    const NSUInteger maxVisibleUsers = IS_IPAD ? MaxVisibleUserViewsIPad : MaxVisibleUserViews;
    return maxVisibleUsers;
}

- (void)createViews
{
    self.singleTileImageDiameter = [WAZUIMagic cgFloatForIdentifier:@"content.system.participant.added.single.image_diameter"];
    self.multiTileImageDiameter = [WAZUIMagic cgFloatForIdentifier:@"content.system.participant.added.multi.image_diameter"];
    self.multiTileImageSpacing = [WAZUIMagic cgFloatForIdentifier:@"content.system.participant.added.multi.horizontal_gap"];
    
    [self createUserViews];
    [self createMoreUsersLabel];
    [self createSubtitleLabel];
}

- (void)createUserViews
{
    self.userViews = [[NSMutableArray alloc] init];
    
    NSUInteger maxVisibleUsers = [self maxVisibleUsers];
    
    self.userViewContainer = [[UIView alloc] init];
    self.userViewContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.userViewContainer];
    
    for (NSUInteger i = 0; i < maxVisibleUsers; i++) {
        BadgeUserImageView *userView = [[BadgeUserImageView alloc] initWithMagicPrefix:@"content.system.participant.user_tile"];
        [self.userViews addObject:userView];
        [self.userViewContainer addSubview:userView];
    }
}

- (void)createMoreUsersLabel
{
    UIFont *moreUsersFont = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"];
    UIColor *moreUsersLabelColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground];
    UIColor *moreUsersBorderColor = [UIColor colorWithMagicIdentifier:@"content.system.participant.added.multi.others_stroke_color"];
    
    UILabel *moreUsers = [[UILabel alloc] init];
    
    moreUsers.textAlignment = NSTextAlignmentCenter;
    moreUsers.font = moreUsersFont;
    moreUsers.textColor = moreUsersLabelColor;
    moreUsers.layer.borderWidth = 1;
    moreUsers.layer.borderColor = moreUsersBorderColor.CGColor;
    
    self.moreUsersLabel = moreUsers;
    [self.userViewContainer addSubview:moreUsers];
}

- (void)createSubtitleLabel
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.minimumLineHeight = [WAZUIMagic cgFloatForIdentifier:@"content.system_message_line_height"];
    paragraphStyle.maximumLineHeight = paragraphStyle.minimumLineHeight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    self.subtitleParagraphStyle = paragraphStyle;
    
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.numberOfLines = 0;
    
    [self addSubview:self.subtitleLabel];
}

- (void)createConstraints
{
    self.userViewSpacingConstraints = [self.userViews autoDistributeViewsAlongAxis:ALAxisHorizontal alignedTo:ALAttributeHorizontal withFixedSpacing:0 insetSpacing:NO matchedSizes:NO];
    
    [self.userViewContainer autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.userViewContainer autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    NSMutableArray *widthConstraints = [NSMutableArray array];
    
    for (UIView *userView in self.userViews) {
        [userView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        [userView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        [userView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:userView];
        [widthConstraints addObject:[userView autoSetDimension:ALDimensionWidth toSize:0]];
    }
    
    self.userViewWidthConstraints = [NSArray arrayWithArray:widthConstraints];
    
    UIView *lastUserView = self.userViews.lastObject;
    
    [self.moreUsersLabel autoAlignAxis:ALAxisVertical toSameAxisOfView:lastUserView];
    [self.moreUsersLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:lastUserView];
    [self.moreUsersLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:lastUserView];
    [self.moreUsersLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:lastUserView];
    
    [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.userViewContainer withOffset:12];
    [self.subtitleLabel autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    [self.subtitleLabel autoPinEdgeToSuperviewMargin:ALEdgeRight];
    [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    [self updateParticipantsChangedConstraintConstants];
}

- (void)updateParticipantsChangedConstraintConstants
{
    CGFloat diameter = ([self.participants count] > 1) ? self.multiTileImageDiameter : self.singleTileImageDiameter;
    NSUInteger visibleUsersCount = [self visibleUsersCount
                                    ];
    self.moreUsersLabel.layer.cornerRadius = diameter / 2;
    
    for (NSUInteger i = 0; i < self.userViews.count; i++) {
        
        NSLayoutConstraint *widthConstraint = self.userViewWidthConstraints[i];
        NSLayoutConstraint *spacingConstraint = [self spacingConstraintForIndex:i];
        
        if (i < visibleUsersCount) {
            widthConstraint.constant = diameter;
            spacingConstraint.constant = self.multiTileImageSpacing;
        }
        else {
            widthConstraint.constant = 0;
            spacingConstraint.constant = 0;
        }
    }
}

- (NSLayoutConstraint *)spacingConstraintForIndex:(NSUInteger)index
{
    if (index == 0 || index >= self.userViews.count) {
        return nil; // First item doesn't have spacing constraint
    }
    
    NSUInteger spacingConstraintIndex = (index - 1) * 2 + 1; // There are two constraints per item and we substract the first item's constraint
    return self.userViewSpacingConstraints[spacingConstraintIndex];
}

- (NSUInteger)visibleUsersCount
{
    return MIN(self.participants.count, [self maxVisibleUsers]);
}

- (void)setParticipants:(NSArray *)participants
{
    if ([participants containsObject:[ZMUser selfUser]]) {
        NSMutableArray *mutableParticipants =  participants.mutableCopy;
        [mutableParticipants removeObject:[ZMUser selfUser]];
        [mutableParticipants insertObject:[ZMUser selfUser] atIndex:0];
        participants = mutableParticipants;
    }
    
    _participants = participants;
    
    [self configureUserViewsWithUsers:participants];
    [self configureMoreUsersViewWithUsers:participants];
    [self configureSubtitle];
    
    [self updateParticipantsChangedConstraintConstants];
}

- (void)setAction:(ParticipantsChangedAction)action
{
    _action = action;
    [self configureSubtitle];
}

- (void)setUserPerformingAction:(ZMUser *)userPerformingAction
{
    _userPerformingAction = userPerformingAction;
    [self configureSubtitle];
}

- (void)configureUserViewsWithUsers:(NSArray *)users
{
    NSUInteger visibleUsersCount = [self visibleUsersCount];
    
    NSUInteger index = 0;
    for (ZMUser *user in users) {
        BadgeUserImageView *userView = self.userViews[index];
        userView.user = user;
        userView.hidden = NO;
        
        index++;
        if (index == visibleUsersCount) {
            break;
        }
    }
    
    if (self.action == ParticipantsChangedActionRemoved) {
        self.userViewContainer.alpha = [WAZUIMagic cgFloatForIdentifier:@"content.system.participant.removed.image_alpha"];
    } else {
        self.userViewContainer.alpha = 1;
    }
}

- (void)configureMoreUsersViewWithUsers:(NSArray *)users
{
    NSUInteger visibleUsersCount = [self visibleUsersCount];
    self.moreUsersLabel.text = [NSString stringWithFormat:@"+%lu", (unsigned long)(users.count - visibleUsersCount + 1)];
    
    if (users.count <= [self maxVisibleUsers]) {
        self.moreUsersLabel.hidden = YES;
        [self.userViews.lastObject setHidden:users.count != [self maxVisibleUsers]];
    } else {
        self.moreUsersLabel.hidden = NO;
        [self.userViews.lastObject setHidden:YES];
    }
}

- (void)configureSubtitle
{
    UIFont *font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    UIColor *fontColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground];
    
    NSAttributedString *attributedSubtitleText =
    [[[self subtitleText] uppercaseString] attributedStringWithAttributes:@{ NSFontAttributeName : font,
                                                                             NSForegroundColorAttributeName : fontColor,
                                                                             NSParagraphStyleAttributeName : self.subtitleParagraphStyle,
                                                                             NSBackgroundColorAttributeName : [UIColor clearColor],
                                                                             NSKernAttributeName : @(0) }];
    
    self.subtitleLabel.attributedText = attributedSubtitleText;
}

- (NSString *)subtitleText
{
    switch (self.action) {
        case ParticipantsChangedActionAdded:
        case ParticipantsChangedActionStarted:
        case ParticipantsChangedActionContinued:
            return [self subtitleForAddingUsers];
            break;
            
        case ParticipantsChangedActionRemoved:
            return [self subtitleForRemovingUser];
            break;
    }
}

- (NSString *)subtitleForAddingUsers
{
    NSMutableArray *users = self.participants.mutableCopy; [users removeObject:self.userPerformingAction];
    
    const NSRange visibleUsersRange = NSMakeRange(0, MIN([self maxVisibleUsers], users.count));
    
    NSMutableArray *visibleUsers = [users subarrayWithRange:visibleUsersRange].mutableCopy;
    NSMutableArray *additionalUsers = users.mutableCopy; [additionalUsers removeObjectsInArray:visibleUsers];
    NSMutableArray *names = [NSMutableArray array];
    
    if ([visibleUsers containsObject:[ZMUser selfUser]]) {
        [visibleUsers removeObject:[ZMUser selfUser]];
        [names addObject:NSLocalizedString(@"content.system.participants_you", @"")];
    }
    
    if (visibleUsers.count > 1 && additionalUsers.count == 0) {
        [additionalUsers addObject:visibleUsers.lastObject];
        [visibleUsers removeLastObject];
    }
    
    [names addObjectsFromArray:[visibleUsers valueForKey:@"displayName"]];
    NSString *nameList = [names componentsJoinedByString:@", "];
    
    if (additionalUsers.count == 1) {
        nameList = [NSString stringWithFormat:NSLocalizedString(@"content.system.participants_1_other", @""), nameList, [additionalUsers.firstObject displayName]];
    } else {
        nameList = [NSString stringWithFormat:NSLocalizedString(@"content.system.participants_n_others", @""), nameList, additionalUsers.count];
    }
    
    NSString *proposedString;
    if (self.action == ParticipantsChangedActionContinued) {
        proposedString = [NSString stringWithFormat:NSLocalizedString(@"content.system.continued_conversation", @""), nameList];
    }
    else if ((self.participants.count == 1) && ([self.participants containsObject:[ZMUser selfUser]])) {
        proposedString = [NSString stringWithFormat:NSLocalizedString(@"content.system.other_added_you", @""), self.userPerformingAction.displayName];
    }
    else if (self.action == ParticipantsChangedActionStarted) {
        if (self.userPerformingAction.isSelfUser) {
            proposedString = [NSString stringWithFormat:NSLocalizedString(@"content.system.you_started_conversation", @""), nameList];
        } else {
            proposedString = [NSString stringWithFormat:NSLocalizedString(@"content.system.other_started_conversation", @""), self.userPerformingAction.displayName, nameList];
        }
    } else {
        if (self.userPerformingAction.isSelfUser) {
            proposedString = [NSString stringWithFormat:NSLocalizedString(@"content.system.you_added_participant", @""), nameList];
        } else {
            proposedString = [NSString stringWithFormat:NSLocalizedString(@"content.system.other_added_participant", @""), self.userPerformingAction.displayName, nameList];
        }
    }
    
    return [proposedString uppercaseStringWithLocale:[NSLocale currentLocale]];
}

- (NSString *)subtitleForRemovingUser
{
    ZMUser *removedUser = self.participants.firstObject;
    ZMUser *selfUser = [ZMUser selfUser];
    
    NSString *proposedString;
    if (removedUser == self.userPerformingAction) {
        if (self.userPerformingAction == selfUser) {
            proposedString = [NSString stringWithFormat:NSLocalizedString(@"content.system.you_left", @"")];
        } else {
            proposedString = [NSString stringWithFormat:NSLocalizedString(@"content.system.other_left", @""), self.userPerformingAction.displayName];
        }
    } else {
        
        if (self.userPerformingAction.isSelfUser) {
            proposedString = [NSString stringWithFormat:NSLocalizedString(@"content.system.you_removed_other", @""), removedUser.displayName];
        } else if (removedUser == selfUser) {
            proposedString = [NSString stringWithFormat:NSLocalizedString(@"content.system.other_removed_you", @""), self.userPerformingAction.displayName];
        } else {
            proposedString = [NSString stringWithFormat:NSLocalizedString(@"content.system.other_removed_other", @""), self.userPerformingAction.displayName, removedUser.displayName];
        }
        
    }
    
    return [proposedString uppercaseStringWithLocale:[NSLocale currentLocale]];
}

@end
