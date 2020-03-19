
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

extension ConversationInputBarViewController: UINavigationControllerDelegate {}

private let zmLog = ZMSLog(tag: "ConversationInputBarViewController+Files")

extension ConversationInputBarViewController {
    func uploadItem(at itemURL: URL) {
        let itemPath = itemURL.path
        var isDirectory = false
        let fileExists = FileManager.default.fileExists(atPath: itemPath, isDirectory: UnsafeMutablePointer<ObjCBool>(mutating: &isDirectory))
        if !fileExists {
            zmLog.error("File not found for uploading: \(itemURL)")
            return
        }
        
        if isDirectory {
            let tmpPath = URL(fileURLWithPath: URL(fileURLWithPath: itemPath).deletingLastPathComponent().absoluteString).appendingPathComponent("tmp").absoluteString
            
            var error: Error? = nil
            do {
                try FileManager.default.createDirectory(atPath: tmpPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                zmLog.error("Cannot create folder at path \(tmpPath): \(error)")
                return
            }
            
            do {
                try FileManager.default.moveItem(atPath: itemPath ?? "", toPath: URL(fileURLWithPath: tmpPath).appendingPathComponent(itemPath?.lastPathComponent ?? "").absoluteString)
            } catch {
                zmLog.error("Cannot move \(itemPath) to \(tmpPath): \(error)")
                do {
                    try FileManager.default.removeItem(atPath: tmpPath)
                } catch {
                }
                return
            }
            
            let archivePath = itemPath ?? "" + (".zip")
            let zipSucceded = SSZipArchive.createZipFile(atPath: archivePath, withContentsOfDirectory: tmpPath)
            
            if zipSucceded {
                uploadFile(at: URL(fileURLWithPath: archivePath))
            } else {
                zmLog.error("Cannot archive folder at path: \(itemURL)")
            }
            
            do {
                try FileManager.default.removeItem(atPath: tmpPath)
            } catch {
                    zmLog.error("Cannot delete folder at path \(tmpPath): \(error)")
                    return
            }
        } else {
            uploadFile(at: itemURL)
        }
    }

    func uploadFile(at url: URL) {
        let completion = {
            var deleteError: Error? = nil
            do {
                try FileManager.default.removeItem(at: url)
            } catch let deleteError {
                zmLog.error("Error: cannot unlink document: \(deleteError)")
            }
            
        }

        let attributes: [FileAttributeKey : Any]
        do {
            attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        } catch {
            zmLog.error("Cannot get attributes on selected file: \(error)")
            parent?.dismiss(animated: true)
            completion()
        }
        
        
        
            if (attributes[FileAttributeKey.size] as? NSNumber)?.uint64Value ?? 0 > ZMUserSession.shared().maxUploadFileSize() {
                // file exceeds maximum allowed upload size
                parent?.dismiss(animated: false)
                
                showAlertForFileTooBig()
                
                completion()
            } else {
                FileMetaDataGenerator.metadataForFile(at: url, uti: url?.uti, name: url?.lastPathComponent) { metadata in
                    self.impactFeedbackGenerator.prepare()
                    ZMUserSession.sharedSession.performChanges({
                        
                        weak var message = self.conversation.appendMessage(with: metadata)
                        self.impactFeedbackGenerator.impactOccurred()
                        
                        if message?.fileMessageData.isVideo != nil {
                            Analytics.shared().tagMediaActionCompleted(ConversationMediaActionVideoMessage, inConversation: self.conversation)
                        } else if message?.fileMessageData.isAudio != nil {
                            Analytics.shared().tagMediaActionCompleted(ConversationMediaActionAudioMessage, inConversation: self.conversation)
                        } else {
                            Analytics.shared().tagMediaActionCompleted(ConversationMediaActionFileTransfer, inConversation: self.conversation)
                        }
                        
                        completion()
                    })
                }
                parent?.dismiss(animated: true)
            }
        
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
    
    @objc
    func showAlertForFileTooBig() {
        guard let maxUploadFileSize = ZMUserSession.shared()?.maxUploadFileSize() else { return }
        
        let maxSizeString = ByteCountFormatter.string(fromByteCount: Int64(maxUploadFileSize), countStyle: .binary)
        let errorMessage = String(format: "content.file.too_big".localized, maxSizeString)
        let alert = UIAlertController.alertWithOKButton(message: errorMessage)
        present(alert, animated: true)
    }
}
