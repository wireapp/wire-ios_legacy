//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireMessageStrategy
import WireRequestStrategy
import ZMTransport.ZMRequestCancellation


class StrategyFactory {

    let syncContext: NSManagedObjectContext
    let registrationStatus: ClientRegistrationStatus
    let cancellationProvider: ZMRequestCancellation

    private var tornDown = false
    private(set) var strategies = [AnyObject]()

    init(syncContext: NSManagedObjectContext, registrationStatus: ClientRegistrationStatus, cancellationProvider: ZMRequestCancellation) {
        self.syncContext = syncContext
        self.registrationStatus = registrationStatus
        self.cancellationProvider = cancellationProvider
        strategies = createStrategies()
    }

    deinit {
        precondition(tornDown, "Need to call tearDown before deinit")
    }

    func tearDown() {
        strategies.flatMap { $0 as? ZMObjectSyncStrategy }.forEach { $0.tearDown() }
        tornDown = true
    }

    private func createStrategies() -> [AnyObject] {
        return [
            createImageDownloadRequestStrategy(),
            createAssetV3DownloadRequestStrategy(),
            createAssetV3PreviewDownloadRequestStrategy()
        ]
    }

    private func createImageDownloadRequestStrategy() -> ImageDownloadRequestStrategy {
        return ImageDownloadRequestStrategy(
            clientRegistrationStatus: registrationStatus,
            managedObjectContext: syncContext
        )
    }

    private func createAssetV3DownloadRequestStrategy() -> AssetV3DownloadRequestStrategy {
        return AssetV3DownloadRequestStrategy(
            authStatus: registrationStatus,
            taskCancellationProvider: TaskCancellationDummy(),
            managedObjectContext: syncContext
        )
    }

    private func createAssetV3PreviewDownloadRequestStrategy() -> AssetV3PreviewDownloadRequestStrategy {
        return AssetV3PreviewDownloadRequestStrategy(
            authStatus: registrationStatus,
            managedObjectContext: syncContext
        )
    }

}
