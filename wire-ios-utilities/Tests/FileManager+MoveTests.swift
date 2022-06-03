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
import XCTest
@testable import WireUtilities

class FileManagerMoveTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        self.wipeDirectories()
        try! FileManager.default.createDirectory(at: self.tempFolder1, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        super.tearDown()
        self.wipeDirectories()
    }
    
    func testThatItMovesOneFolder() throws {
        
        // GIVEN
        let files = [
            "foo/bar/x.dat",
            "bam/bar/dat.txt",
            "baz.md",
            "foo/eh.ah"
        ]
        self.createFiles(in: self.tempFolder1, relativeFilePaths: files)
        
        // WHEN
        try FileManager.default.moveFolderRecursively(from: self.tempFolder1, to: self.tempFolder2, overwriteExistingFiles: true)
        
        // THEN
        files.forEach {
            checkIfFileExists(in: self.tempFolder2, relativePath: $0)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: self.tempFolder1.path))
    }
    
    func testThatItMovesOneFolderOverAnExistingOne() throws {
        
        // GIVEN
        let filesToMove = [
            "foo/bar/x.dat",
            "bam/bar/dat.txt",
            "baz.md",
            "foo/eh.ah"
        ]
        let preExistingFiles = [
            "foo/bar/extra.file",
            "meh.bah"
        ]
        self.createFiles(in: self.tempFolder1, relativeFilePaths: filesToMove)
        self.createFiles(in: self.tempFolder2, relativeFilePaths: preExistingFiles)
        
        // WHEN
        try FileManager.default.moveFolderRecursively(from: self.tempFolder1, to: self.tempFolder2, overwriteExistingFiles: true)
        
        // THEN
        (filesToMove + preExistingFiles).forEach {
            checkIfFileExists(in: self.tempFolder2, relativePath: $0)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: self.tempFolder1.path))
    }
    
    func testThatItDoesNotOverwriteFilesInTheDestinationDirectory() throws {
        // GIVEN
        let nonOverwrittenExistingFile = "foo/eh.ah"
        let overwrittenExistingFile = "meh.bah"
        let preExistingFiles = [overwrittenExistingFile, nonOverwrittenExistingFile]
        let filesToMove = [
            "baz.md",
            overwrittenExistingFile
        ]
        
        self.createFiles(in: self.tempFolder1, relativeFilePaths: filesToMove, content: "SOURCE")
        self.createFiles(in: self.tempFolder2, relativeFilePaths: preExistingFiles, content: "DESTINATION")
        
        // WHEN
        try FileManager.default.moveFolderRecursively(from: self.tempFolder1, to: self.tempFolder2, overwriteExistingFiles: false)
        
        // THEN
        self.checkIfFileExists(in: self.tempFolder2, relativePath: overwrittenExistingFile, content: "DESTINATION")
        self.checkIfFileExists(in: self.tempFolder2, relativePath: nonOverwrittenExistingFile, content: "DESTINATION")
    }
    
    func testThatItOverwritesFilesInTheDestinationDirectory() throws {
        // GIVEN
        let nonOverwrittenExistingFile = "foo/eh.ah"
        let overwrittenExistingFile = "meh.bah"
        let preExistingFiles = [overwrittenExistingFile, nonOverwrittenExistingFile]
        let filesToMove = [
            "baz.md",
            overwrittenExistingFile
        ]
        
        self.createFiles(in: self.tempFolder1, relativeFilePaths: filesToMove, content: "SOURCE")
        self.createFiles(in: self.tempFolder2, relativeFilePaths: preExistingFiles, content: "DESTINATION")
        
        // WHEN
        try FileManager.default.moveFolderRecursively(from: self.tempFolder1, to: self.tempFolder2, overwriteExistingFiles: true)
        
        // THEN
        self.checkIfFileExists(in: self.tempFolder2, relativePath: overwrittenExistingFile, content: "SOURCE")
        self.checkIfFileExists(in: self.tempFolder2, relativePath: nonOverwrittenExistingFile, content: "DESTINATION")
    }
}

// MARK: Copy
extension FileManagerMoveTests {
    
    func testThatItCopiesOneFolder() throws {
        
        // GIVEN
        let files = [
            "foo/bar/x.dat",
            "bam/bar/dat.txt",
            "baz.md",
            "foo/eh.ah"
        ]
        self.createFiles(in: self.tempFolder1, relativeFilePaths: files)
        
        // WHEN
        try FileManager.default.copyFolderRecursively(from: self.tempFolder1, to: self.tempFolder2, overwriteExistingFiles: true)
        
        // THEN
        files.forEach {
            checkIfFileExists(in: self.tempFolder2, relativePath: $0)
            checkIfFileExists(in: self.tempFolder1, relativePath: $0)
        }
    }
    
    func testThatItCopiesOneFolderOverAnExistingOne() throws {
        
        // GIVEN
        let filesToMove = [
            "foo/bar/x.dat",
            "bam/bar/dat.txt",
            "baz.md",
            "foo/eh.ah"
        ]
        let preExistingFiles = [
            "foo/bar/extra.file",
            "meh.bah"
        ]
        self.createFiles(in: self.tempFolder1, relativeFilePaths: filesToMove)
        self.createFiles(in: self.tempFolder2, relativeFilePaths: preExistingFiles)
        
        // WHEN
        try FileManager.default.copyFolderRecursively(from: self.tempFolder1, to: self.tempFolder2, overwriteExistingFiles: true)
        
        // THEN
        (filesToMove + preExistingFiles).forEach {
            checkIfFileExists(in: self.tempFolder2, relativePath: $0)
        }
    }
    
    func testThatItDoesNotCopyOverwriteFilesInTheDestinationDirectory() throws {
        // GIVEN
        let nonOverwrittenExistingFile = "foo/eh.ah"
        let overwrittenExistingFile = "meh.bah"
        let preExistingFiles = [overwrittenExistingFile, nonOverwrittenExistingFile]
        let filesToMove = [
            "baz.md",
            overwrittenExistingFile
        ]
        
        self.createFiles(in: self.tempFolder1, relativeFilePaths: filesToMove, content: "SOURCE")
        self.createFiles(in: self.tempFolder2, relativeFilePaths: preExistingFiles, content: "DESTINATION")
        
        // WHEN
        try FileManager.default.copyFolderRecursively(from: self.tempFolder1, to: self.tempFolder2, overwriteExistingFiles: false)
        
        // THEN
        self.checkIfFileExists(in: self.tempFolder2, relativePath: overwrittenExistingFile, content: "DESTINATION")
        self.checkIfFileExists(in: self.tempFolder2, relativePath: nonOverwrittenExistingFile, content: "DESTINATION")
    }
    
    func testThatItCopyOverwritesFilesInTheDestinationDirectory() throws {
        // GIVEN
        let nonOverwrittenExistingFile = "foo/eh.ah"
        let overwrittenExistingFile = "meh.bah"
        let preExistingFiles = [overwrittenExistingFile, nonOverwrittenExistingFile]
        let filesToMove = [
            "baz.md",
            overwrittenExistingFile
        ]
        
        self.createFiles(in: self.tempFolder1, relativeFilePaths: filesToMove, content: "SOURCE")
        self.createFiles(in: self.tempFolder2, relativeFilePaths: preExistingFiles, content: "DESTINATION")
        
        // WHEN
        try FileManager.default.copyFolderRecursively(from: self.tempFolder1, to: self.tempFolder2, overwriteExistingFiles: true)
        
        // THEN
        self.checkIfFileExists(in: self.tempFolder2, relativePath: overwrittenExistingFile, content: "SOURCE")
        self.checkIfFileExists(in: self.tempFolder2, relativePath: nonOverwrittenExistingFile, content: "DESTINATION")
    }
}

extension FileManagerMoveTests {
    
    var tempFolder1: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory() + "/FimeManagerMoveTests/1")
    }
    
    var tempFolder2: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory() + "/FimeManagerMoveTests/2")
    }
    
    func wipeDirectories() {
        try? FileManager.default.removeItem(at: self.tempFolder1)
        try? FileManager.default.removeItem(at: self.tempFolder2)
    }
    
    /// Create dummy files
    /// - parameter in: root folder where to create the file
    /// - parameter relativeFilePaths: path of the files to create, relative to the root folder
    func createFiles(in folder: URL, relativeFilePaths: [String], content: String? = nil) {
        relativeFilePaths.forEach { filePath in
            let fullURL = folder.appendingPathComponent(filePath)
            let directory = fullURL.deletingLastPathComponent()
            try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = (content ?? filePath).data(using: .utf8)
            try! data?.write(to: fullURL)
        }
    }
    
    func checkIfFileExists(in folder: URL, relativePath: String, content: String? = nil) {
        let fileURL = folder.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: fileURL), let fileContent = String(data: data, encoding: .utf8) else {
            XCTFail("File \(relativePath) not readable")
            return
        }
        XCTAssertEqual(fileContent, content ?? relativePath)
    }
    
}

