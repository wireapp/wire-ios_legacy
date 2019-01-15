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


#import "KeyValueObserver.h"
#import <CoreData/CoreData.h>


@interface KeyValueObserver ()
@property (nonatomic, weak) id observedObject;
@property (nonatomic, copy) NSString* keyPath;
@end

@implementation KeyValueObserver

- (id)initWithObject:(id)object keyPath:(NSString*)keyPath target:(id)target selector:(SEL)selector options:(NSKeyValueObservingOptions)options;
{
    if (object == nil) {
        return nil;
    }
    NSParameterAssert(target != nil);
    NSParameterAssert([target respondsToSelector:selector]);
    self = [super init];
    if (self) {
        self.target = target;
        self.selector = selector;
        self.observedObject = object;
        self.keyPath = keyPath;
        [object addObserver:self forKeyPath:keyPath options:options context:(__bridge void *)(self)];
    }
    return self;
}

+ (NSObject *)observeObject:(id)object keyPath:(NSString*)keyPath target:(id)target selector:(SEL)selector __attribute__((warn_unused_result));
{
    return [self observeObject:object keyPath:keyPath target:target selector:selector options:0];
}

+ (NSObject *)observeObject:(id)object keyPath:(NSString*)keyPath target:(id)target selector:(SEL)selector options:(NSKeyValueObservingOptions)options __attribute__((warn_unused_result));
{
    return [[self alloc] initWithObject:object keyPath:keyPath target:target selector:selector options:options];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (context == (__bridge void *)(self)) {
        [self didChange:change];
    }
}

- (void)didChange:(NSDictionary *)change;
{
    id strongTarget = self.target;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [strongTarget performSelector:self.selector withObject:change];
#pragma clang diagnostic pop
}

- (void)dealloc;
{
    [self.observedObject removeObserver:self forKeyPath:self.keyPath];
}

@end



@interface NonRecursiveKeyValueObserver ()

@property (nonatomic) BOOL isObservingChange;

@end



@implementation NonRecursiveKeyValueObserver

- (void)didChange:(NSDictionary *)change;
{
    if (! self.isObservingChange) {
        self.isObservingChange = YES;
        [super didChange:change];
        self.isObservingChange = NO;
    }
}

@end


@implementation ManagedObjectKeyValueObserver

+ (NSObject *)observeObject:(id)object keyPath:(NSString*)keyPath target:(id)target selector:(SEL)selector options:(NSKeyValueObservingOptions)options;
{
    NSAssert([object isKindOfClass:[NSManagedObject class]], @"%@ is only for observing NSManagedObject.", [object class]);
    return [super observeObject:object keyPath:keyPath target:target selector:selector options:options];
}

- (void)didChange:(NSDictionary *)change;
{
    NSManagedObject *mo = self.observedObject;
    if (mo.faultingState != 0) {
        return;
    }
    [super didChange:change];
}

@end
