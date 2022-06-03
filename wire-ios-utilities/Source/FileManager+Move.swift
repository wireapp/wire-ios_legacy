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

extension FileManager {
    
    /// Moves the content of the folder recursively to another folder.
    /// If the destionation folder does not exists, it creates it.
    /// If it exists, it moves files and folders from the first folder to the second, then
    /// deletes the first folder.
    @objc public func moveFolderRecursively(
        from source: URL,
        to destination: URL,
        overwriteExistingFiles: Bool) throws
    {
        try self.moveOrCopyFolderRecursively(
            operation: .move,
            from: source,
            to: destination,
            overwriteExistingFiles: overwriteExistingFiles)
        
        // we moved everything, now we can delete
        try self.removeItem(at: source)
    }
    
    /// Copies the content of the folder recursively to another folder.
    /// If the destionation folder does not exists, it creates it.
    @objc public func copyFolderRecursively(
        from source: URL,
        to destination: URL,
        overwriteExistingFiles: Bool) throws
    {
        try self.moveOrCopyFolderRecursively(
            operation: .copy,
            from: source,
            to: destination,
            overwriteExistingFiles: overwriteExistingFiles)
    }
    
    private enum FileOperation {
        case move
        case copy
    }
    
    private func moveOrCopyFolderRecursively(
        operation: FileOperation,
        from source: URL,
        to destination: URL,
        overwriteExistingFiles: Bool) throws
    {
        self.createAndProtectDirectory(at: destination)
        
        var isDirectory : ObjCBool = false
        let enumerator = self.enumerator(at: source, includingPropertiesForKeys: [.nameKey, .isDirectoryKey])!
        try enumerator.forEach { item in
            let sourceItem = item as! URL
            guard self.fileExists(atPath: sourceItem.path, isDirectory: &isDirectory) else { return }
            let destinationItem = destination.appendingPathComponent(sourceItem.lastPathComponent)
            
            if isDirectory.boolValue {
                enumerator.skipDescendants() // do not descend in this directory with this forEach loop
                try self.moveOrCopyFolderRecursively(
                    operation: operation,
                    from: sourceItem,
                    to: destinationItem,
                    overwriteExistingFiles: overwriteExistingFiles
                ) // manually do recursion in this subfolder
            } else {
                if self.fileExists(atPath: destinationItem.path) {
                    if !overwriteExistingFiles {
                        return // skip already existing files!
                    } else {
                        try self.removeItem(at: destinationItem)
                    }
                }
                try self.apply(operation, at: sourceItem, to: destinationItem)
            }
        }
    }
    
    private func apply(_ operation: FileOperation, at source: URL, to destination: URL) throws {
        switch operation {
        case .move:
            try self.moveItem(at: source, to: destination)
        case .copy:
            try self.copyItem(at: source, to: destination)
        }
    }
}
