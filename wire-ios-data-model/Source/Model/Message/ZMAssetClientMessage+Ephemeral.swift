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

extension ZMAssetClientMessage {

    @objc override public var isEphemeral: Bool {
        return destructionDate != nil
            || ephemeral != nil
            || isObfuscated
    }

    var ephemeral: Ephemeral? {
        return dataSet.lazy
            .compactMap { ($0 as? ZMGenericMessageData)?.underlyingMessage }
            .first(where: { (message) -> Bool in
                guard case .ephemeral? = message.content else {
                    return false
                }
                return true
            })?.ephemeral
    }

    @objc override public var deletionTimeout: TimeInterval {
        guard let ephemeral = self.ephemeral else {
            return -1
        }
        return TimeInterval(ephemeral.expireAfterMillis / 1000)
    }

    @objc override public func obfuscate() {
        super.obfuscate()

        var obfuscatedMessage: GenericMessage?
        if let medium = mediumGenericMessage {
            obfuscatedMessage = medium.obfuscatedMessage()
        } else if fileMessageData != nil {
            obfuscatedMessage = underlyingMessage?.obfuscatedMessage()
        }
        deleteContent()

        if let obfuscatedMessage = obfuscatedMessage {
            do {
                _ = try createNewGenericMessageData(with: obfuscatedMessage)
            } catch {
                Logging.messageProcessing.warn("Failed to process obfuscated message. Reason: \(error.localizedDescription)")
            }
        }
    }

    @discardableResult @objc public override func startDestructionIfNeeded() -> Bool {

        if imageMessageData != nil && !hasDownloadedFile {
            return false
        } else if fileMessageData != nil
            && underlyingMessage?.assetData?.hasUploaded == false
            && underlyingMessage?.assetData?.hasNotUploaded == false {
            return false
        }

        return super.startDestructionIfNeeded()
    }

    /// Extends the destruction timer to the given date, which must be later
    /// than the current destruction date. If a timer is already running,
    /// then it will be stopped and restarted with the new date, otherwise
    /// a new timer will be created.
    public func extendDestructionTimer(to date: Date) {
        let timeout = date.timeIntervalSince(Date())

        guard
            let isSelfUser = sender?.isSelfUser,
            let destructionDate = self.destructionDate,
            date > destructionDate,
            timeout > 0 else {
                return
        }

        let msg = self as ZMMessage
        if isSelfUser { msg.restartObfuscationTimer(timeout) }
        else { msg.restartDeletionTimer(timeout) }
    }
}
