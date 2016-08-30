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
import AddressBook

/// Allows access to address book for search
@objc public class AddressBookHelper : NSObject {
    
    /// Time to wait between searches
    let searchTimeInterval : NSTimeInterval = 60 * 60 * 24 // 24h
    
    /// Singleton
    public static let sharedHelper : AddressBookHelper = AddressBookHelper()
    
    /// Configuration override (used for testing)
    public var configuration : AddressBookHelperConfiguration!
}

// MARK: - Permissions
extension AddressBookHelper {
    
    public var isAddressBookAccessUnknown : Bool {
        return ABAddressBookGetAuthorizationStatus() == .NotDetermined
    }
    
    public var isAddressBookAccessGranted : Bool {
        return ABAddressBookGetAuthorizationStatus() == .Authorized
    }
    
    public var isAddressBookAccessDisabled : Bool {
        return ABAddressBookGetAuthorizationStatus() == .Denied
    }
    
    /// Request access to the user. Will asynchronously invoke the callback passing as argument
    /// whether access was granted.
    public func requestPermissions(callback: ((Bool)->())?) {
        dispatch_async(addressBookIsolationQueue) {
            
            guard let addressBookRef = ABAddressBookCreateWithOptions(nil, nil)?.takeRetainedValue() else {
                dispatch_async(dispatch_get_main_queue()) {
                    callback?(false)
                }
                return
            }
            
            ABAddressBookRequestAccessWithCompletion(addressBookRef) { (granted, error) in
                dispatch_async(dispatch_get_main_queue()) {
                    callback?(granted)
                }
            }
        }
    }
    
    /// Whether enough time has passed since last search to request a new search
    private var enoughTimeHasPassedForSearch : Bool {
        guard let lastSearchDate = NSUserDefaults.standardUserDefaults().objectForKey(addressBookLastSearchDate) as? NSDate else {
            return true
        }
        // Date check
        let timeSinceLastSearch = NSDate().timeIntervalSinceDate(lastSearchDate)
        let customTimeLimit : NSTimeInterval?
        if let timeLimitInConfiguration = self.configuration?.addressBookRemoteSearchTimeInterval where timeLimitInConfiguration > 0 {
            customTimeLimit = timeLimitInConfiguration
        } else {
            customTimeLimit = self.searchTimeInterval
        }
        return timeSinceLastSearch > customTimeLimit
    }
    
    /// Whether the address book search was performed at least once
    public var addressBookSearchPerformedAtLeastOnce : Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(addressBookSearchPerfomedAtLeastOnceKey)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: addressBookSearchPerfomedAtLeastOnceKey)
        }
    }
    
    /// Whether the user was asked to perform address book search
    public var addressBookSearchWasProposed : Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(addressBookSearchWasProposedKey)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: addressBookSearchWasProposedKey)
        }
    }
}

// MARK: - Upload
extension AddressBookHelper {
    
    /// Starts an address book search, if enough time has passed since last search
    @objc(startRemoteSearchWithCheckingIfEnoughTimeSinceLast:) public func startRemoteSearch(onlyIfEnoughTimeSinceLast: Bool) {
        guard self.isAddressBookAccessGranted && (!onlyIfEnoughTimeSinceLast || self.enoughTimeHasPassedForSearch) else {
            return
        }
        self.addressBookSearchWasProposed = false;
        self.addressBookSearchPerformedAtLeastOnce = true;
        
        if TARGET_OS_SIMULATOR == 0 || (self.configuration?.shouldPerformAddressBookRemoteSearchEvenOnSimulator ?? false) {
            ZMUserSession.sharedSession().uploadAddressBook()
        }
        NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: addressBookLastSearchDate)
    }
}

// MARK: - Constants

private let addressBookLastSearchDate = "UserDefaultsKeyAddressBookExportDate"
private let addressBookSearchPerfomedAtLeastOnceKey = "AddressBookWasUploaded"
private let addressBookSearchWasProposedKey = "AddressBookUploadWasProposed"

private let addressBookIsolationQueue = dispatch_queue_create("Address book helper", DISPATCH_QUEUE_SERIAL)

// MARK: - Testing
@objc public protocol AddressBookHelperConfiguration : NSObjectProtocol {

    /// Whether the remote search using address book should be performed also on simulator
    var shouldPerformAddressBookRemoteSearchEvenOnSimulator : Bool { get }
    
    /// Overriding interval between remote search
    var addressBookRemoteSearchTimeInterval : NSTimeInterval { get }
}

