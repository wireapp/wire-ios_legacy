//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import Foundation
import CoreData

public extension NSManagedObjectContext {
    static private let timeout: TimeInterval = 10

    @discardableResult func performGroupedAndWait<T>(_ execute: @escaping (NSManagedObjectContext) -> T) -> T {
        var result: T!
        let groups = dispatchGroupContext?.enterAll(except: nil)
        let tp = ZMSTimePoint(interval: NSManagedObjectContext.timeout)
        
        performAndWait {
            tp?.resetTime()
            result = execute(self)
            groups.apply {
                dispatchGroupContext?.leave($0)
            }
            tp?.warnIfLongerThanInterval()
        }
        
        return result
    }
    
    @discardableResult func performGroupedAndWait<T>(_ execute: @escaping (NSManagedObjectContext) throws -> T) throws -> T {
        var result: T!
        var thrownError: Error?
        let groups = dispatchGroupContext?.enterAll(except: nil)
        let tp = ZMSTimePoint(interval: NSManagedObjectContext.timeout)
        
        performAndWait {
            do {
                tp?.resetTime()
                result = try execute(self)
                groups.apply {
                    dispatchGroupContext?.leave($0)
                }
                tp?.warnIfLongerThanInterval()
            } catch {
                thrownError = error
            }
        }
        
        if let error = thrownError {
            throw error
        } else {
            return result
        }
    }
}
