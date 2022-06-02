//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

/// Delegate protocol which the user of the IdentifierObjectSync class should implement.

public protocol IdentifierObjectSyncTranscoder: AnyObject {
    associatedtype T: Hashable

    var fetchLimit: Int { get }

    func request(for identifiers: Set<T>, apiVersion: APIVersion) -> ZMTransportRequest?

    func didReceive(response: ZMTransportResponse, for identifiers: Set<T>)

}

public protocol IdentifierObjectSyncDelegate: AnyObject {

    func didFinishSyncingAllObjects()
    func didFailToSyncAllObjects()

}

/// Class for syncing objects based on an identifier.

public class IdentifierObjectSync<Transcoder: IdentifierObjectSyncTranscoder>: NSObject, ZMRequestGenerator {

    fileprivate let managedObjectContext: NSManagedObjectContext
    fileprivate var pending: Set<Transcoder.T> = Set()
    fileprivate var downloading: Set<Transcoder.T> = Set()
    fileprivate weak var transcoder: Transcoder?

    weak var delegate: IdentifierObjectSyncDelegate?

    var isSyncing: Bool {
        return !pending.isEmpty || !downloading.isEmpty
    }

    /// - parameter managedObjectContext: Managed object context on which the sync will operate
    /// - parameter transcoder: Transcoder which which will create requests & parse responses
    /// - parameter fetchLimit: Maximum number of objects which will be asked to be fetched in a single request

    public init(managedObjectContext: NSManagedObjectContext, transcoder: Transcoder) {
        self.transcoder = transcoder
        self.managedObjectContext = managedObjectContext

        super.init()
    }

    /// Add identifiers for objects which should be fetched
    ///
    /// - parameter identifiers: Set of identifiers to fetch.
    ///
    /// If the identifiers have already been added this method has no effect.

    public func sync<S: Sequence>(identifiers: S) where S.Element == Transcoder.T {
        let newIdentifiers = Set(identifiers)

        if newIdentifiers.isEmpty && downloading.isEmpty && pending.isEmpty {
            delegate?.didFinishSyncingAllObjects()
        } else {
            pending.formUnion(Set(identifiers).subtracting(downloading))
        }
    }

    /// Remove identifiers from the list of objects to be fetched
    ///
    /// - parameter identifiers: Set of identifiers to remove
    ///
    /// If the identifiers have been or are currently being downloaded this method has no effect.

    public func cancel<S: Sequence>(identifiers: S) where S.Element == Transcoder.T {
        pending.subtract(identifiers)
    }

    public func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard !pending.isEmpty, let fetchLimit = transcoder?.fetchLimit else { return nil }

        let scheduled = Set(pending.prefix(fetchLimit))

        guard let request = transcoder?.request(for: scheduled, apiVersion: apiVersion) else { return nil }

        downloading.formUnion(scheduled)
        pending.subtract(scheduled)

        request.add(ZMCompletionHandler(on: managedObjectContext, block: { [weak self] (response) in
            guard let strongSelf = self else { return }

            switch response.result {
            case .permanentError, .success:
                strongSelf.downloading.subtract(scheduled)
                strongSelf.transcoder?.didReceive(response: response, for: scheduled)

                if case .permanentError = response.result {
                    self?.delegate?.didFailToSyncAllObjects()
                }
            default:
                strongSelf.downloading.subtract(scheduled)
                strongSelf.pending.formUnion(scheduled)
            }

            strongSelf.managedObjectContext.enqueueDelayedSave()

            if !strongSelf.isSyncing {
                self?.delegate?.didFinishSyncingAllObjects()
            }
        }))

        return request
    }

}
