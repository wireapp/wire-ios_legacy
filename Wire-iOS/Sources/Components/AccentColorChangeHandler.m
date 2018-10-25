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


#import "AccentColorChangeHandler.h"

#import "WireSyncEngine+iOS.h"
#import "UIColor+WAZExtensions.h"
#import "Wire-Swift.h"


@interface AccentColorChangeHandler () <ZMUserObserver>

@property (nonatomic, copy) AccentColorChangeHandlerBlock handlerBlock;
@property (atomic, unsafe_unretained) id observer;

@property (nonatomic, strong) ZMUser *selfUser;
@property (nonatomic) id userObserverToken;

- (id)initWithObserver:(id)observer handlerBlock:(AccentColorChangeHandlerBlock)changeHandler;

@end



@implementation AccentColorChangeHandler

+ (instancetype)addObserver:(id)observer handlerBlock:(AccentColorChangeHandlerBlock)changeHandler;
{
    return [[self alloc] initWithObserver:observer handlerBlock:changeHandler];
}

- (id)init;
{
    return nil;
}

- (id)initWithObserver:(id)observer handlerBlock:(AccentColorChangeHandlerBlock)changeHandler
{
    self = [super init];
    if (self != nil) {
        self.handlerBlock = changeHandler;
        self.observer = observer;
        
        self.selfUser = [ZMUser selfUser];
        if (nil != [ZMUserSession sharedSession]) {
            self.userObserverToken = [UserChangeInfo addObserver:self
                                                         forUser:self.selfUser
                                                     userSession:[ZMUserSession sharedSession]];
        }
    }
    return self;
}

- (void)dealloc
{
    self.observer = nil;
}

- (void)userDidChange:(UserChangeInfo *)change
{
    if (change.accentColorValueChanged) {
        self.handlerBlock([UIColor accentColor], self.observer);
    }
}

@end
