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


@class NSFetchRequest;


NS_ASSUME_NONNULL_BEGIN
@protocol ZMContextChangeTracker <NSObject>

- (void)objectsDidChange:(NSSet<NSManagedObject *> *)object;

/// Returns the fetch request to retrieve the initial set of objects.
///
/// During app launch this fetch request is executed and the resulting objects are passed to -addTrackedObjects:
- (nullable NSFetchRequest *)fetchRequestForTrackedObjects;
/// Adds tracked objects -- which have been retrieved by using the fetch request returned by -fetchRequestForTrackedObjects
- (void)addTrackedObjects:(NSSet<NSManagedObject *> *)objects;

@end



@protocol ZMContextChangeTrackerSource <NSObject>

@property (nonatomic, readonly) NSArray< id<ZMContextChangeTracker> > *contextChangeTrackers; /// Array of ZMContextChangeTracker

@end
NS_ASSUME_NONNULL_END
