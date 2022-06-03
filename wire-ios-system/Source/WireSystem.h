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

//! Project version number for ZMSystem.
FOUNDATION_EXPORT double ZMSystemVersionNumber;

//! Project version string for ZMSystem.
FOUNDATION_EXPORT const unsigned char ZMSystemVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ZMSystem/PublicHeader.h>

#import <WireSystem/ZMSAsserts.h>
#import <WireSystem/ZMSDefines.h>
#import <WireSystem/ZMSLogging.h>
#import <WireSystem/ZMSGroupQueue.h>
#import <WireSystem/ZMSDispatchGroup.h>
#import <WireSystem/ZMSTimePoint.h>
#import <WireSystem/ZMSTestDetection.h>
#import <WireSystem/MemoryReferenceDebugger.h>
#import <WireSystem/ZMSLogNotifications.h>
#import <WireSystem/NSFileHandle+SafeOperations.h>
