//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import XCTest
@testable import WireCryptobox

private typealias Sut = ChaCha20Poly1305.StreamEncryption

class ChaCha20StreamEncryptionFileHeaderTests: XCTestCase {

    func testThatWrittenFileHeaderCanBeRead() throws {
        // given
        let uuid = UUID()
        let header = try Sut.Header(uuid: uuid)

        // when
        _ = try Sut.Header(buffer: header.buffer)
    }
    
    func testThatFileHeaderCanBeReadFromBuffer() throws {
        // given
        let buffer = Data(base64Encoded: "V0JVSQAAAQ8CgQ/ikb7pIkWDhhDkY7uMxemLjGnPNJ2ohITEekzYAzAxygPF36PpKw9HXrGZWg==")!
        
        // when
        let header = try Sut.Header(buffer: [UInt8](buffer))
        
        // then
        XCTAssertEqual(header.salt, [15, 2, 129, 15 ,226 ,145, 190, 233, 34, 69, 131, 134, 16, 228, 99, 187])
        XCTAssertEqual(header.uuidHash, [140, 197, 233, 139, 140, 105, 207, 52, 157, 168, 132, 132, 196, 122, 76, 216, 3, 48, 49, 202, 3, 197, 223, 163, 233, 43, 15, 71, 94, 177, 153, 90 ])
    }
    
    func testThatParsingHeaderWithWrongSizeThrowsAnError() {
        // given
        let buffer = [UInt8]([0,1,3])
        
        // when
        do {
            _ = try Sut.Header(buffer: buffer)
        } catch Sut.EncryptionError.malformedHeader {
            // success
            return
        } catch {
            XCTFail("Unexpected error")
        }
        
        XCTFail("Expected error")
    }
    
    func testThatParsingHeaderWithUnknownPlatformThrowsAnError() {
        // given
        let buffer = [UInt8](Data(base64Encoded: "QldVSQAAAQ8CgQ/ikb7pIkWDhhDkY7uMxemLjGnPNJ2ohITEekzYAzAxygPF36PpKw9HXrGZWg==")!)
        
        // when
        do {
            _ = try Sut.Header(buffer: buffer)
        } catch Sut.EncryptionError.malformedHeader {
            // success
            return
        } catch {
            XCTFail("Unexpected error")
        }
        
        XCTFail("Expected error")
    }
    
}

class ChaCha20StreamEncryptionTests: XCTestCase {
    
    var directoryURL: URL!
    
    override func setUp() {
        super.setUp()
        let docments = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        directoryURL = docments.appendingPathComponent("ChaCha20EncryptionTests")
        
        do {
            try FileManager.default.createDirectory(atPath: directoryURL.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Unable to create directory: \(error)")
        }
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: directoryURL)
        directoryURL = nil
        super.tearDown()
    }
    
    private func createTemporaryURL() -> URL {
        return directoryURL.appendingPathComponent(UUID().uuidString)
    }
    
    private func encrypt(_ message: Data, passphrase: Sut.Passphrase) throws -> Data {
        let inputStream = InputStream(data: message)
        var outputBuffer = Array<UInt8>(repeating: 0, count: 256)
        let outputStream = OutputStream(toBuffer: &outputBuffer, capacity: 256)
        
        let bytesWritten = try Sut.encrypt(input: inputStream, output: outputStream, passphrase: passphrase)
        
        return Data(outputBuffer.prefix(bytesWritten))
    }
    
    private func decrypt(_ chipherMessage: Data, passphrase: Sut.Passphrase) throws -> Data {
        var outputBuffer = Array<UInt8>(repeating: 0, count: 256)
        let outputStream = OutputStream(toBuffer: &outputBuffer, capacity: 256)
        let inputStream = InputStream(data: chipherMessage)
        let decryptedBytes = try Sut.decrypt(input: inputStream, output: outputStream, passphrase: passphrase)
        
        return Data(outputBuffer.prefix(decryptedBytes))
    }
    
    private func encryptToURL(_ message: Data, passphrase: Sut.Passphrase) throws -> URL {
        let inputURL = createTemporaryURL()
        let outputURL = createTemporaryURL()
        try message.write(to: inputURL)
        let inputStream = InputStream(url: inputURL)!
        let outputStream = OutputStream(url: outputURL, append: false)!
        try Sut.encrypt(input: inputStream, output: outputStream, passphrase: passphrase)
        return outputURL
    }
    
    private func decryptFromURL(_ url: URL, passphrase: Sut.Passphrase, file: StaticString = #file, line: UInt = #line) throws -> Data {
        let outputURL = createTemporaryURL()
        let outputStream = OutputStream(url: outputURL, append: false)!
        let inputStream = InputStream(url: url)!
        let decryptedBytes = try Sut.decrypt(input: inputStream, output: outputStream, passphrase: passphrase)
        XCTAssertGreaterThan(decryptedBytes, 0, file: file, line: line)
        return try Data(contentsOf: outputURL)
    }
    
    // MARK: - Encryption
    
    func testThatEncryptionAndDecryptionWorks() throws {
        
        // given
        let passphrase = Sut.Passphrase(password: "1235678", uuid: UUID())
        let message = "123456789"
        let messageData =  message.data(using: .utf8)!
        
        // when
        let encryptedMessage = try encrypt(messageData, passphrase: passphrase)
        let decryptedMessage = try decrypt(encryptedMessage, passphrase: passphrase)
        
        // then
        XCTAssertEqual(decryptedMessage, messageData)
    }
    
    func testThatDecryptionWorks() throws {
        
        // given
        let expectedMessage = "123456789"
        let passphrase = Sut.Passphrase(password: "1235678", uuid: UUID(uuidString: "71DE4781-9EC7-4ED4-BADE-690C5A9732C6")!)
        let encryptedMessage =  Data(base64Encoded: "V0JVSQAAAT5xxW76YX91IgLvJwXeC5x+q/8To15mBzbsA6rc5Dzf7xRyWH+LYv+bscKxj3c7Fl7trr/9qt78lgA5ZtyjK7d2ZBdSYl4HLskPjyUIseTjAZjGKt+7MEXp8aVBey8ooGep")!
        
        // when
        let decryptedMessage = try decrypt(encryptedMessage, passphrase: passphrase)
        
        // then
        XCTAssertEqual(decryptedMessage, expectedMessage.data(using: .utf8)!)
    }
        
    func testThatEncryptionAndDecryptionWorks_ToDisk() throws {
        
        // given
        let passphrase = Sut.Passphrase(password: "1235678", uuid: UUID())
        let message = "123456789"
        let messageData =  message.data(using: .utf8)!
        
        // when
        let encryptedDataURL = try encryptToURL(messageData, passphrase: passphrase)
        let decryptedMessage = try decryptFromURL(encryptedDataURL, passphrase: passphrase)
        
        // then
        XCTAssertEqual(decryptedMessage, messageData)
    }
    
    func testThatItThrowsWriteErrorWhenOutputStreamFailsWhileEncrypting() throws {
        
        // given
        let message = "123456789"
        let messageData =  message.data(using: .utf8)!
        let inputStream = InputStream(data: messageData)
        var outputBuffer = Array<UInt8>(repeating: 0, count: 1)
        let outputStream = OutputStream(toBuffer: &outputBuffer, capacity: 1)
        let passphrase = Sut.Passphrase(password: "1235678", uuid: UUID())
        
        // then when
        do {
            try Sut.encrypt(input: inputStream, output: outputStream, passphrase: passphrase)
        } catch Sut.EncryptionError.writeError {
            return // success
        } catch {
            XCTFail()
        }
    }
    
    // MARK: - Decryption
    
    func testThatItThrowsReadErrorOnEmptyData() {
        
        // given
        let passphrase = Sut.Passphrase(password: "1235678", uuid: UUID())
        let malformedMessageData =  "".data(using: .utf8)!
        var outputBuffer = Array<UInt8>(repeating: 0, count: 256)
        let outputStream = OutputStream(toBuffer: &outputBuffer, capacity: 256)
        let inputStream = InputStream(data: malformedMessageData)
        
        // then when
        do {
            try Sut.decrypt(input: inputStream, output: outputStream, passphrase: passphrase)
        } catch Sut.EncryptionError.readError {
            return // success
        } catch {
            XCTFail()
        }
        
        XCTFail()
    }
    
    func testThatItThrowsMalformedHeaderOnBadData() {
        
        // given
        let passphrase = Sut.Passphrase(password: "1235678", uuid: UUID())
        let malformedMessageData =  "malformed12345678901234567890123456789012345678901234567890".data(using: .utf8)!
        var outputBuffer = Array<UInt8>(repeating: 0, count: 256)
        let outputStream = OutputStream(toBuffer: &outputBuffer, capacity: 256)
        let inputStream = InputStream(data: malformedMessageData)
        
        // then when
        do {
            try Sut.decrypt(input: inputStream, output: outputStream, passphrase: passphrase)
        } catch Sut.EncryptionError.malformedHeader {
            return // success
        } catch {
            XCTFail()
        }
        
        XCTFail()
    }
    
    func testThatItThrowsWriteErrorWhenOutputStreamFailsWhileDecrypting() {
        
        // given
        let passphrase = Sut.Passphrase(password: "1235678", uuid: UUID())
        let message = "123456789".data(using: .utf8)!
        let encryptedData = try! encrypt(message, passphrase: passphrase)
        
        let inputStream = InputStream(data: encryptedData)
        var outputBuffer = Array<UInt8>(repeating: 0, count: 1)
        let outputStream = OutputStream(toBuffer: &outputBuffer, capacity: 1)
        
        // then when
        do {
            try Sut.decrypt(input: inputStream, output: outputStream, passphrase: passphrase)
        } catch Sut.EncryptionError.writeError {
            return // success
        } catch {
            XCTFail()
        }
    }
    
    func testThatItThrowsMismatchingUUIDWhenDecryptingWithADifferentUUID() {
        
        // given
        let uuid1 = UUID()
        let uuid2 = UUID()
        let password = "1235678"
        let message = "123456789".data(using: .utf8)!
        
        // then when
        do {
            let encryptedMessage = try encrypt(message, passphrase: Sut.Passphrase(password: password, uuid: uuid1))
            _ = try decrypt(encryptedMessage, passphrase: Sut.Passphrase(password: password, uuid: uuid2))
        } catch Sut.EncryptionError.mismatchingUUID {
            return // success
        } catch {
            XCTFail()
        }
    }
    
    func testThatItThrowsMalformedHeaderWhenDecryptingFileEncryptedOnDifferentPlatform() {
        
        // given
        let uuid1 = UUID()
        let uuid2 = UUID()
        let password = "1235678"
        let message = "123456789".data(using: .utf8)!
        
        // then when
        do {
            let encryptedMessage = try encrypt(message, passphrase: Sut.Passphrase(password: password, uuid: uuid1))
            var modifiedMessage = [UInt8](encryptedMessage)
            modifiedMessage[3] = 65 // replace I with A (A = Android)
            _ = try decrypt(Data(modifiedMessage), passphrase: Sut.Passphrase(password: password, uuid: uuid2))
        } catch Sut.EncryptionError.malformedHeader {
            return // success
        } catch {
            XCTFail()
        }
    }
    
    func testThatItThrowsMalformedHeaderWhenDecryptingFileEncryptedWithUnsupportedVersion() {
        
        // given
        let uuid1 = UUID()
        let uuid2 = UUID()
        let password = "1235678"
        let message = "123456789".data(using: .utf8)!
        
        // then when
        do {
            let encryptedMessage = try encrypt(message, passphrase: Sut.Passphrase(password: password, uuid: uuid1))
            var modifiedMessage = [UInt8](encryptedMessage)
            modifiedMessage[6] = 2 // change version number
            _ = try decrypt(Data(modifiedMessage), passphrase: Sut.Passphrase(password: password, uuid: uuid2))
        } catch Sut.EncryptionError.malformedHeader {
            return // success
        } catch {
            XCTFail()
        }
    }
    
}
