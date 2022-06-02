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
import WireRequestStrategy
import WireTransport.ZMRequestCancellation
import WireLinkPreview

class StrategyFactory {

    unowned let syncContext: NSManagedObjectContext
    let applicationStatus: ApplicationStatus
    let linkPreviewPreprocessor: LinkPreviewPreprocessor
    private(set) var strategies = [AnyObject]()

    private var tornDown = false

    init(syncContext: NSManagedObjectContext, applicationStatus: ApplicationStatus, linkPreviewPreprocessor: LinkPreviewPreprocessor) {
        self.linkPreviewPreprocessor = linkPreviewPreprocessor
        self.syncContext = syncContext
        self.applicationStatus = applicationStatus
        self.strategies = createStrategies(linkPreviewPreprocessor: linkPreviewPreprocessor)
    }

    deinit {
        precondition(tornDown, "Need to call `tearDown` before `deinit`")
    }

    func tearDown() {
        strategies.forEach {
            if $0.responds(to: #selector(ZMObjectSyncStrategy.tearDown)) {
                ($0 as? ZMObjectSyncStrategy)?.tearDown()
            }
        }
        tornDown = true
    }

    private func createStrategies(linkPreviewPreprocessor: LinkPreviewPreprocessor) -> [AnyObject] {
        return [
            // Clients
            createMissingClientsStrategy(),
            createFetchingClientsStrategy(),
            createVerifyLegalHoldStrategy(),

            // Client Messages
            createClientMessageRequestStrategy(),

            // Link Previews
            createLinkPreviewAssetUploadRequestStrategy(linkPreviewPreprocessor: linkPreviewPreprocessor),
            createLinkPreviewUpdateRequestStrategy(),

            // Assets V3
            createAssetClientMessageRequestStrategy(),
            createAssetV3UploadRequestStrategy()
        ]
    }

    private func createVerifyLegalHoldStrategy() -> VerifyLegalHoldRequestStrategy {
        return VerifyLegalHoldRequestStrategy(withManagedObjectContext: syncContext, applicationStatus: applicationStatus)
    }

    private func createFetchingClientsStrategy() -> FetchingClientRequestStrategy {
        return FetchingClientRequestStrategy(withManagedObjectContext: syncContext, applicationStatus: applicationStatus)
    }

    private func createMissingClientsStrategy() -> MissingClientsRequestStrategy {
        return MissingClientsRequestStrategy(withManagedObjectContext: syncContext, applicationStatus: applicationStatus)
    }

    private func createClientMessageRequestStrategy() -> ClientMessageRequestStrategy {
        return ClientMessageRequestStrategy(
            withManagedObjectContext: syncContext,
            localNotificationDispatcher: PushMessageHandlerDummy(),
            applicationStatus: applicationStatus
        )
    }

    // MARK: – Link Previews

    private func createLinkPreviewAssetUploadRequestStrategy(linkPreviewPreprocessor: LinkPreviewPreprocessor) -> LinkPreviewAssetUploadRequestStrategy {

        return LinkPreviewAssetUploadRequestStrategy(
            managedObjectContext: syncContext,
            applicationStatus: applicationStatus,
            linkPreviewPreprocessor: linkPreviewPreprocessor,
            previewImagePreprocessor: nil
        )
    }

    private func createLinkPreviewUpdateRequestStrategy() -> LinkPreviewUpdateRequestStrategy {
        return LinkPreviewUpdateRequestStrategy(withManagedObjectContext: syncContext, applicationStatus: applicationStatus)
    }

    // MARK: - Asset V3

    private func createAssetV3UploadRequestStrategy() -> AssetV3UploadRequestStrategy {
         return AssetV3UploadRequestStrategy(withManagedObjectContext: syncContext, applicationStatus: applicationStatus)
    }

    private func createAssetClientMessageRequestStrategy() -> AssetClientMessageRequestStrategy {
        return AssetClientMessageRequestStrategy(withManagedObjectContext: syncContext, applicationStatus: applicationStatus)
    }
}
