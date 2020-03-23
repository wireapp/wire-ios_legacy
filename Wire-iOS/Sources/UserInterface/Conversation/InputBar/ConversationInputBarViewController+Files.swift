
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

extension ConversationInputBarViewController: UINavigationControllerDelegate {}

private let zmLog = ZMSLog(tag: "ConversationInputBarViewController+Files")

extension ConversationInputBarViewController {
    //TODO: check it is still possible on iOS 10
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
    
    func uploadItem(at itemURL: URL) {
        let itemPath = itemURL.path
        var isDirectory : ObjCBool = false
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
        
        let archivePath = URL(fileURLWithPath: NSTemporaryDirectory() + "archive.zip").path
        
        let paths = urls.map(){$0.path}
        let zipSucceded = SSZipArchive.createZipFile(atPath: archivePath, withFilesAtPaths: paths)

        if zipSucceded {
            uploadFile(at: URL(fileURLWithPath: archivePath))
        } else {
            zmLog.error("Cannot archive folder at path: \(archivePath)")
        }

    }
    
    /// upload a signal file
    ///
    /// - Parameter url: the URL of the file
    func uploadFile(at url: URL) {
        let completion: Completion = { [weak self] in
            self?.removeItem(atPath: url.path)
        }
        
        let attributes: [FileAttributeKey : Any]
        do {
            attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        } catch {
            zmLog.error("Cannot get attributes on selected file: \(error)")
            parent?.dismiss(animated: true)
            completion()
            
            return
        }
        
        guard (attributes[FileAttributeKey.size] as? UInt64 ?? UInt64.max) <= ZMUserSession.shared()?.maxUploadFileSize() ?? 0 else {
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
            
            weakSelf.impactFeedbackGenerator?.prepare()
            ZMUserSession.shared()?.perform({

                weakSelf.impactFeedbackGenerator?.impactOccurred()
                
                var conversationMediaAction: ConversationMediaAction = .fileTransfer
                
                if let message: ZMConversationMessage = weakSelf.conversation.append(file: metadata),
                    let fileMessageData = message.fileMessageData {
                    if fileMessageData.isVideo {
                        conversationMediaAction = .videoMessage
                    } else if fileMessageData.isAudio {
                        conversationMediaAction = .audioMessage
                    }
                }
                
                Analytics.shared().tagMediaActionCompleted(conversationMediaAction, inConversation: weakSelf.conversation)
                
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
        guard let maxUploadFileSize = ZMUserSession.shared()?.maxUploadFileSize() else { return }
        
        let maxSizeString = ByteCountFormatter.string(fromByteCount: Int64(maxUploadFileSize), countStyle: .binary)
        let errorMessage = String(format: "content.file.too_big".localized, maxSizeString)
        let alert = UIAlertController.alertWithOKButton(message: errorMessage)
        present(alert, animated: true)
    }
}
