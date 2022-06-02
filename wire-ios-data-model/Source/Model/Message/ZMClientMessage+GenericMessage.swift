//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension ZMClientMessage {

    public var underlyingMessage: GenericMessage? {
        guard !isZombieObject else {
            return nil
        }

        if cachedUnderlyingMessage == nil {
            cachedUnderlyingMessage = underlyingMessageMergedFromDataSet()
        }
        return cachedUnderlyingMessage
    }

    private func underlyingMessageMergedFromDataSet() -> GenericMessage? {
        let filteredData = dataSet.lazy
            .compactMap { ($0 as? ZMGenericMessageData)?.underlyingMessage }
            .filter { $0.knownMessage && $0.imageAssetData == nil }
            .compactMap { try? $0.serializedData() }

        guard !Array(filteredData).isEmpty else {
            return nil
        }

        var message = GenericMessage()
        filteredData.forEach {
            try? message.merge(serializedData: $0)
        }
        return message
    }

    /// Set the underlying protobuf message data.
    ///
    /// - Parameter message: The protobuf message object to be associated with this client message.
    /// - Throws `ProcessingError` if the protobuf data can't be processed.

    public func setUnderlyingMessage(_ message: GenericMessage) throws {
        let messageData = try mergeWithExistingData(message)

        if nonce == .none, let messageID = messageData.underlyingMessage?.messageID {
            nonce = UUID(uuidString: messageID)
        }

        updateCategoryCache()
        setLocallyModifiedKeys([#keyPath(ZMClientMessage.dataSet)])
    }

    @discardableResult
    func mergeWithExistingData(_ message: GenericMessage) throws -> ZMGenericMessageData {
        cachedUnderlyingMessage = nil

        let existingMessageData = dataSet
            .compactMap { $0 as? ZMGenericMessageData }
            .first

        guard let messageData = existingMessageData else {
            return try createNewGenericMessageData(with: message)
        }

        do {
            try messageData.setGenericMessage(message)
        } catch {
            throw ProcessingError.failedToProcessMessageData(reason: error.localizedDescription)
        }

        return messageData
    }

    private func createNewGenericMessageData(with message: GenericMessage) throws -> ZMGenericMessageData {
        guard let moc = managedObjectContext else {
            throw ProcessingError.missingManagedObjectContext
        }

        let messageData = ZMGenericMessageData.insertNewObject(in: moc)

        do {
            try messageData.setGenericMessage(message)
            messageData.message = self
            return messageData
        } catch {
            moc.delete(messageData)
            throw ProcessingError.failedToProcessMessageData(reason: error.localizedDescription)
        }
    }
}
