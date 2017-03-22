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


#import "PingCell.h"
#import "zmessaging+iOS.h"
#import "UIImage+ZetaIconsNeue.h"
#import "UIView+MTAnimation.h"
#import "UIColor+WAZExtensions.h"
#import "UIColor+WR_ColorScheme.h"

#import "UIView+Borders.h"
#import <Classy/Classy.h>

#import <PureLayout/PureLayout.h>

#import "Wire-Swift.h"


typedef void (^AnimationBlock)(id, NSInteger);


@interface PingCell ()

@property (nonatomic, strong) UIImageView *pingImageView;
@property (nonatomic, assign) BOOL initialPingCellConstraintsCreated;
@property (nonatomic, strong) AnimationBlock pingAnimationBlock;
@property (nonatomic, strong) UIFont *pingFont;
@property (nonatomic, strong) UIFont *authorFont;
@property (nonatomic, strong) UILabel *pingLabel;

@property (nonatomic, assign) BOOL isPingAnimationRunning;

@end



@implementation PingCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [CASStyler.defaultStyler styleItem:self];
        [self setupPingCell];
        [self createConstraints];
    }
    
    return self;
}

- (void)setupPingCell
{
    self.pingImageView = [[UIImageView alloc] initForAutoLayout];
    self.pingLabel = [[UILabel alloc] initForAutoLayout];
    
    [self.contentView addSubview:self.pingImageView];
    [self.contentView addSubview:self.pingLabel];
    
    NSMutableArray *accessibilityElements = [NSMutableArray arrayWithArray:self.accessibilityElements];
    [accessibilityElements addObjectsFromArray:@[self.pingLabel]];
    self.accessibilityElements = accessibilityElements;
}

- (void)createConstraints
{
    [self.pingImageView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.authorImageView];
    [self.pingImageView autoAlignAxis:ALAxisVertical toSameAxisOfView:self.authorImageView];
    [self.pingLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.authorLabel];
    [self.pingLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.authorLabel];
    [self.pingLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.authorLabel];
    [self.countdownContainerView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.pingImageView];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self stopPingAnimation];
}

- (void)configureForMessage:(id<ZMConversationMessage>)message layoutProperties:(ConversationCellLayoutProperties *)layoutProperties
{
    [super configureForMessage:message layoutProperties:layoutProperties];

    NSString *senderText = self.message.sender.isSelfUser ? NSLocalizedString(@"content.ping.text.you", @"") : self.message.sender.displayName;
    NSString *pingText = [NSString stringWithFormat:NSLocalizedString(@"content.ping.text", @""), senderText, nil];
    NSAttributedString *text = [[NSAttributedString alloc] initWithString:pingText attributes:@{ NSFontAttributeName: self.pingFont }];
    self.pingLabel.attributedText = [text addingFont:self.authorFont toSubstring:senderText];

    UIColor *pingColor = message.isObfuscated ? [UIColor wr_colorFromColorScheme:ColorSchemeColorAccentDimmedFlat] : self.message.sender.accentColor;
    self.pingImageView.image = [UIImage imageForIcon:ZetaIconTypePing fontSize:20 color:pingColor];
    self.authorImageView.hidden = YES;
    self.authorLabel.hidden = YES;
}

- (UIView *)selectionView
{
    return self.authorLabel;
}

- (CGRect)selectionRect
{
    return self.authorLabel.bounds;
}

- (MenuConfigurationProperties *)menuConfigurationProperties;
{
    MenuConfigurationProperties *properties = [[MenuConfigurationProperties alloc] init];
    properties.targetRect = self.selectionRect;
    properties.targetView = self.selectionView;
    properties.selectedMenuBlock = ^(BOOL selected, BOOL animated) {
        [self setSelectedByMenu:selected animated:animated];
    };
    return properties;
}

- (MessageType)messageType;
{
    return MessageTypePing;
}

- (void)setSelectedByMenu:(BOOL)selected animated:(BOOL)animated
{
    dispatch_block_t animationBlock = ^{
        CGFloat newAlpha = selected ? ConversationCellSelectedOpacity : 1.0f;
        self.authorLabel.alpha = newAlpha;
        self.pingImageView.alpha = newAlpha;
    };
    
    if (animated) {
        [UIView animateWithDuration:ConversationCellSelectionAnimationDuration animations:animationBlock];
    } else {
        animationBlock();
    }
}


@end



@implementation PingCell (Animation)

- (void)startPingAnimation
{
    // This is the main animation block that takes another block to run REPS number of times
    self.pingAnimationBlock = [self createPingAnimationBlock];
    
    [self animateKnock];
}

- (void)stopPingAnimation
{
    self.isPingAnimationRunning = NO;
    self.pingImageView.alpha = 1;
}

- (void)animateKnock
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (! [self canAnimationContinueForMessage:self.message]) {
            return;
        }
        
        self.isPingAnimationRunning = YES;
        self.pingImageView.alpha = 1;
        self.pingAnimationBlock(self.pingAnimationBlock, 2);
    });
}

- (AnimationBlock)createPingAnimationBlock
{
   
    @weakify(self);

    AnimationBlock pingAnimationBlock = ^void(AnimationBlock otherBlock, NSInteger reps) {
        
        @strongify(self);
        
        self.pingImageView.alpha = 1;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            if (! [self canAnimationContinueForMessage:self.message]) {
                return;
            }
            
            self.isPingAnimationRunning = YES;
            
            [UIView mt_animateWithViews:@[self.pingImageView] duration:0.7 delay:0 timingFunction:MTTimingFunctionEaseOutExpo animations:^{
                self.pingImageView.transform = CGAffineTransformMakeScale(1.8, 1.8);
            } completion:^{
                self.pingImageView.transform = CGAffineTransformIdentity;
            }];
            
            [UIView mt_animateWithViews:@[self.pingImageView] duration:0.7 delay:0.0 timingFunction:MTTimingFunctionEaseOutQuart animations:^{
                self.pingImageView.alpha = 0;
            } completion:^{
                
                if (reps > 0) {
                    otherBlock(self.pingAnimationBlock, reps-1);
                }
                else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        
                        if (! [self canAnimationContinueForMessage:self.message]) {
                            return;
                        }
                        
                        self.isPingAnimationRunning = YES;
                        
                        [UIView mt_animateWithViews:@[self.pingImageView] duration:0.55 delay:0 timingFunction:MTTimingFunctionEaseOutQuart animations:^{
                            self.pingImageView.alpha = 1;
                            
                        } completion:^{
                            [self stopPingAnimation];
                        }];
                    });
                }
            }];
        });
    };
    
    return pingAnimationBlock;
}

- (BOOL)canAnimationContinueForMessage:(id<ZMConversationMessage>)knockMessage
{
    return [knockMessage.knockMessageData isEqual:self.message];
}

@end
