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
import ZipArchive
import WireSyncEngine
import WireCommonComponents

extension ConversationInputBarViewController: UINavigationControllerDelegate {}

private let zmLog = ZMSLog(tag: "ConversationInputBarViewController+Files")

extension ConversationInputBarViewController {

    @available(iOS, introduced: 8.0, deprecated: 11.0, message: "Upload a directory is no longer allowed in Document picker")
    /// Tested with iOS 10 simulator and confirmed that folder is not selectable for upload.
    /// This method should be removed in the future
    ///
    /// - Parameter itemURL: url of the directory
    func updateDirectory(itemURL: URL) {
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())

        let itemPath = itemURL.path

        do {
            try FileManager.default.moveItem(atPath: itemPath, toPath: URL(fileURLWithPath: tmpURL.path).appendingPathComponent(itemURL.lastPathComponent).absoluteString)
        } catch {
            zmLog.error("Cannot move \(itemPath) to \(tmpURL): \(error)")
            removeItem(atPath: tmpURL.path)
            return
        }

        let archivePath = itemPath + (".zip")
        let zipSucceded = SSZipArchive.createZipFile(atPath: archivePath, withContentsOfDirectory: tmpURL.path)

        if zipSucceded {
            uploadFile(at: URL(fileURLWithPath: archivePath))
        } else {
            zmLog.error("Cannot archive folder at path: \(itemURL)")
        }

        removeItem(atPath: tmpURL.path)

    }

    @available(iOS, introduced: 8.0, deprecated: 11.0, message: "Upload a directory is no longer allowed in Document picker")
    func uploadItem(at itemURL: URL) {
        let itemPath = itemURL.path
        var isDirectory: ObjCBool = false
        let fileExists = FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory)
        if !fileExists {
            zmLog.error("File not found for uploading: \(itemURL)")
            return
        }

        guard isDirectory.boolValue else {
            uploadFile(at: itemURL)
            return
        }

        // zip and upload the directory
        updateDirectory(itemURL: itemURL)
    }

    @discardableResult
    private func removeItem(atPath path: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            zmLog.error("Cannot delete folder at path \(path): \(error)")

            return false
        }

        return true
    }

    func uploadFiles(at urls: [URL]) {
        guard urls.count > 1 else {
            if let url = urls.first {
                uploadFile(at: url)
            }
            return
        }

        if let archiveURL = urls.zipFiles() {
            uploadFile(at: archiveURL)
        } else {
            zmLog.error("Cannot archive files at URLs: \(urls.description)")
        }

    }

    /// upload a signal file
    ///
    /// - Parameter url: the URL of the file
    func uploadFile(at url: URL) {
        guard let maxUploadFileSize = ZMUserSession.shared()?.maxUploadFileSize else { return }

        let completion: Completion = { [weak self] in
            self?.removeItem(atPath: url.path)
        }

        guard let fileSize: UInt64 = url.fileSize else {
            zmLog.error("Cannot get file size on selected file:")
            parent?.dismiss(animated: true)
            completion()

            return
        }

        guard fileSize <= maxUploadFileSize else {
            // file exceeds maximum allowed upload size
            parent?.dismiss(animated: false)

            showAlertForFileTooBig()

            _ = completion()

            return
        }

        FileMetaDataGenerator.metadataForFileAtURL(url,
                                                   UTI: url.UTI(),
                                                   name: url.lastPathComponent) { [weak self] metadata in
            guard let weakSelf = self else { return }

            weakSelf.impactFeedbackGenerator.prepare()
            ZMUserSession.shared()?.perform({

                weakSelf.impactFeedbackGenerator.impactOccurred()

                var conversationMediaAction: ConversationMediaAction = .fileTransfer

                do {
                    let message = try weakSelf.conversation.appendFile(with: metadata)
                    if let fileMessageData = message.fileMessageData {
                        if fileMessageData.isVideo {
                            conversationMediaAction = .videoMessage
                        } else if fileMessageData.isAudio {
                            conversationMediaAction = .audioMessage
                        }
                    }

                    Analytics.shared.tagMediaActionCompleted(conversationMediaAction, inConversation: weakSelf.conversation)
                } catch {
                    Logging.messageProcessing.warn("Failed to append file. Reason: \(error.localizedDescription)")
                }

                completion()
            })
        }
        parent?.dismiss(animated: true)
    }
    
    func execute(videoPermissions toExecute: @escaping () -> ()) {
        UIApplication.wr_requestOrWarnAboutVideoAccess({ granted in
            if granted {
                UIApplication.wr_requestOrWarnAboutMicrophoneAccess({ granted in
                    if granted {
                        toExecute()
                    }
                })
            }
        })
    }

    private func showAlertForFileTooBig() {
        guard let maxUploadFileSize = ZMUserSession.shared()?.maxUploadFileSize else { return }

        let maxSizeString = ByteCountFormatter.string(fromByteCount: Int64(maxUploadFileSize), countStyle: .binary)
        let errorMessage = String(format: "content.file.too_big".localized, maxSizeString)
        let alert = UIAlertController.alertWithOKButton(message: errorMessage)
        present(alert, animated: true)
    }
}
