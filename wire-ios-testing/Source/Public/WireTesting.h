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

//! Project version number for WireTesting.
FOUNDATION_EXPORT double WireTestingVersionNumber;

//! Project version string for WireTesting.
FOUNDATION_EXPORT const unsigned char WireTestingVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <WireTesting/PublicHeader.h>

#import <WireTesting/ZMTBaseTest.h>
#import <WireTesting/XCTestCase+Helpers.h>
#import <WireTesting/ZMTFailureRecorder.h>
#import <WireTesting/ZMTAsserts.h>
#import <WireTesting/NSData+WireTesting.h>
#import <WireTesting/NSOperationQueue+WireTesting.h>
#import <WireTesting/ZMTImageComparator.h>
#import <WireTesting/NSUUID+WireTesting.h>
#import <WireTesting/ZMMockManagedObjectContextFactory.h>
#import <WireTesting/ZMMockEntity.h>
#import <WireTesting/ZMMockEntity2.h>
