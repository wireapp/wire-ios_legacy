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


#import <Foundation/Foundation.h>



@interface KeyValueObserver : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic) SEL selector;

/// Create a Key-Value Observing helper object.
///
/// As long as the returned token object is retained, the KVO notifications of the @c object
/// and @c keyPath will cause the given @c selector to be called on @c target.
/// @a object and @a target are weak references.
/// Once the token object gets dealloc'ed, the observer gets removed.
///
/// The @c selector should conform to
/// @code
/// - (void)nameDidChange:(NSDictionary *)change;
/// @endcode
/// The passed in dictionary is the KVO change dictionary (c.f. @c NSKeyValueChangeKindKey, @c NSKeyValueChangeNewKey etc.)
///
/// @returns the opaque token object to be stored in a property
///
/// Example:
///
/// @code
///   self.nameObserveToken = [KeyValueObserver observeObject:user
///                                                   keyPath:@"name"
///                                                    target:self
///                                                  selector:@selector(nameDidChange:)];
/// @endcode
+ (NSObject *)observeObject:(id)object keyPath:(NSString*)keyPath target:(id)target selector:(SEL)selector __attribute__((warn_unused_result));

/// Create a key-value-observer with the given KVO options
+ (NSObject *)observeObject:(id)object keyPath:(NSString*)keyPath target:(id)target selector:(SEL)selector options:(NSKeyValueObservingOptions)options __attribute__((warn_unused_result));

@end



/// Same as @c KeyValueObserver, but makes sure that the selector isn't called recursively.
@interface NonRecursiveKeyValueObserver : KeyValueObserver
@end



/// This makes sure that the observer is not called when the observered object is in a faulting state.
/// C.f. -[NSManagedObject faultingState]
@interface ManagedObjectKeyValueObserver : KeyValueObserver
@end
