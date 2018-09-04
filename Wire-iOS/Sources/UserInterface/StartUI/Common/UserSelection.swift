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

import Foundation
import WireUtilities

@objc
public protocol UserSelectionObserver {
    
    func userSelection(_ userSelection: UserSelection, didAddUser user: ZMUser)
    func userSelection(_ userSelection: UserSelection, didRemoveUser user: ZMUser)
    func userSelection(_ userSelection: UserSelection, wasReplacedBy users: [ZMUser])
    
}

@objcMembers
public class UserSelection : NSObject {
    
    public fileprivate(set) var users : Set<ZMUser> = Set()
    fileprivate var observers : [UnownedObject<UserSelectionObserver>] = []
    
    public func replace(_ users: [ZMUser]) {
        self.users = Set(users)
        observers.forEach({ $0.unbox?.userSelection(self, wasReplacedBy: users) })
    }
    
    public func add(_ user: ZMUser) {
        users.insert(user)
        observers.forEach({ $0.unbox?.userSelection(self, didAddUser: user) })
    }
    
    public func remove(_ user: ZMUser) {
        users.remove(user)
        observers.forEach({ $0.unbox?.userSelection(self, didRemoveUser: user) })
    }
    
    @objc(addObserver:)
    public func add(observer: UserSelectionObserver) {
        guard !observers.contains(where: { $0.unbox === observer}) else { return }
        
        observers.append(UnownedObject(observer))
    }
    
    @objc(removeObserver:)
    public func remove(observer: UserSelectionObserver) {
        guard let index = observers.index(where: { $0.unbox === observer}) else { return }
        
        observers.remove(at: index)
    }
    
    // MARK: - Limit
    
    public private(set) var limit: Int?
    private var limitReachedHandler: (() -> Void)?
    
    public var hasReachedLimit: Bool {
        guard let limit = limit, users.count >= limit else { return false }
        limitReachedHandler?()
        return true
    }
    
    public func setLimit(_ limit: Int, handler: @escaping () -> Void) {
        self.limit = limit
        self.limitReachedHandler = handler
    }
}
