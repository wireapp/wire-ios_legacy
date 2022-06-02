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

@objc public protocol NetworkSocketDelegate {
    @objc(networkSocketDidOpen:)
    func didOpen(socket: NetworkSocket)
    
    @objc(didReceiveData:networkSocket:)
    func didReceive(data: Data, on socket: NetworkSocket)
    
    /// Called when the socket is closed. Might be called from the different queue than `callbackQueue` if the
    /// `NetworkSocket` is torn down when deallocated.
    @objc(networkSocketDidClose:)
    func didClose(socket: NetworkSocket)
}

@objcMembers public class DataBuffer: NSObject {
    fileprivate var data: DispatchData = DispatchData.empty
    
    public var objcData: __DispatchData {
        return data as __DispatchData
    }
    
    fileprivate func append(data: DispatchData) {
        self.data.append(data)
    }
    
    @objc(appendData:)
    public func append(data: __DispatchData) {
        self.data.append(data as DispatchData)
    }
    
    func clear(until offset: Int) {
        let dataOffset = data.index(data.startIndex, offsetBy: offset)
        
        data = data.subdata(in: dataOffset..<data.endIndex)
    }
    
    func isEmpty() -> Bool {
        return data.isEmpty
    }
}

@objcMembers public final class NetworkSocket: NSObject {
    
    // MARK: - Public API
    public let url: URL
    public let trustProvider: BackendTrustProvider
    public let queue: DispatchQueue
    public let callbackQueue: DispatchQueue
    public let group: ZMSDispatchGroup
    
    public weak var delegate: NetworkSocketDelegate?
    
    private let queueMarkerKey = DispatchSpecificKey<Void>()
    
    public init(url: URL, trustProvider: BackendTrustProvider, delegate: NetworkSocketDelegate?, queue: DispatchQueue, callbackQueue: DispatchQueue, group: ZMSDispatchGroup) {
        self.url = url
        self.trustProvider = trustProvider
        self.delegate = delegate
        self.queue = queue
        self.callbackQueue = callbackQueue
        self.group = group
        
        queue.setSpecific(key: queueMarkerKey, value: ())
        
        super.init()
    }
    
    deinit {
        if state != .stopped {
            if isOnQueue() {
                close(syncDelegate: true)
            }
            else {
                // `queue` is specially created to handle all the actions on the `networkSocket`.
                // therefore it should be safe to dispatch sync on it: it must not be blocked with other
                // activity.
                queue.sync {
                    close(syncDelegate: true)
                }
            }
        }
    }
    
    public func open() {
        preconditionQueue()
        
        state = .connecting
        
        let hostName = url.host!
        let port = url.port ?? 443
        
        var inStream: InputStream? = nil
        var outStream: OutputStream? = nil
        Stream.getStreamsToHost(withName: hostName, port: port, inputStream: &inStream, outputStream: &outStream)
        inputStream = inStream
        outputStream = outStream
        
        guard let inputStream = self.inputStream, let outputStream = self.outputStream else {
            fatal("Missing streams")
        }
        
        inputStream.delegate = self
        outputStream.delegate = self
        
        CFReadStreamSetDispatchQueue(inputStream, queue)
        CFWriteStreamSetDispatchQueue(outputStream, queue)
        
        let sslSettings: [AnyHashable: Any] = [kCFStreamSSLPeerName: hostName,
                                               kCFStreamSSLValidatesCertificateChain: false]
        
        inputStream.setProperty(sslSettings, forKey: Stream.PropertyKey(kCFStreamPropertySSLSettings as String))
        
        inputStream.setProperty(StreamSocketSecurityLevel.tlSv1,
                                 forKey: Stream.PropertyKey.socketSecurityLevelKey)
        
        inputStream.setProperty(StreamNetworkServiceTypeValue.background,
                                 forKey: Stream.PropertyKey.networkServiceType)
        
        inputStream.open()
        outputStream.open()
    }
    
    public func close() {
        self.close(syncDelegate: false)
    }
    
    private func close(syncDelegate: Bool) {
        preconditionQueue()
        
        guard self.state != .stopped else {
            return
        }
        
        state = .stopped
        
        inputStream?.delegate = nil
        inputStream?.close()
        
        outputStream?.delegate = nil
        outputStream?.close()
        
        self.withDelegate({ delegate in
            delegate.didClose(socket: self)
        }, sync: syncDelegate)
        
        delegate = nil
    }
    
    fileprivate func withDelegate(_ perform: @escaping (NetworkSocketDelegate)->(), sync: Bool = false) {
        guard let delegate = self.delegate else {
            return
        }
        
        if sync {
            perform(delegate)
        }
        else {
            self.group.async(on: callbackQueue) {
                perform(delegate)
            }
        }
    }
    
    @objc(writeData:)
    public func write(data dataToWrite: Data) {
        dataToWrite.withUnsafeBytes { (unsafeBufferPointer: UnsafeRawBufferPointer) -> Void in
            self.write(dispatchData: DispatchData(bytes: unsafeBufferPointer))
        }
    }
    
    fileprivate func write(dispatchData: DispatchData) {
        preconditionQueue()
        
        guard state != .stopped else {
            return
        }
        
        guard let outputStream = self.outputStream, outputStream.streamStatus != .error else {
            self.close()
            return
        }
      
        dataBuffer.append(data: dispatchData)
        
        writeDataIfPossible()
    }
    
    // MARK: - Internals
    fileprivate enum State {
        case readyToConnect
        case connecting
        case connected
        case stopped
    }
    
    fileprivate var state: State = .readyToConnect
    
    fileprivate var didCheckTrust: Bool = false
    fileprivate var trusted: Bool = false
    
    fileprivate var inputStream: InputStream?
    fileprivate var outputStream: OutputStream?
    
    fileprivate let dataBuffer = DataBuffer()
    
    @inline(__always) fileprivate func preconditionQueue() {
        if #available(iOSApplicationExtension 10.0, *) {
            dispatchPrecondition(condition: .onQueue(queue))
        } else {
            precondition(isOnQueue(), "called from the wrong queue")
        }
    }
    
    fileprivate func isOnQueue() -> Bool {
        return DispatchQueue.getSpecific(key: queueMarkerKey) != nil
    }
    
    fileprivate func checkTrust(for stream: Stream) -> Bool {
        if self.didCheckTrust {
            return self.trusted
        }
        self.didCheckTrust = true
        
        guard let peerTrustValue = stream.property(forKey: kCFStreamPropertySSLPeerTrust as Stream.PropertyKey) else {
            self.trusted = false
            return false
        }
        
        let peerTrust = peerTrustValue as! SecTrust
        
        self.trusted = self.trustProvider.verifyServerTrust(trust: peerTrust, host: url.host)
        if !self.trusted {
            self.close()
        }
        return self.trusted
    }
    
    fileprivate func onBytesAvailable() {
        // Check the general state
        guard state != .stopped else {
            return
        }
        
        // Check if we have the output stream
        guard let inputStream = self.inputStream else {
            fatal("Input stream is missing")
        }
        
        let inputBufferCount = 4 * 1024
        var inputBuffer = Data(count: inputBufferCount)

        let bytesRead = inputBuffer.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> Int in
            guard let bytes = pointer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
            return inputStream.read(bytes, maxLength: inputBufferCount)
        }

        guard bytesRead > 0 else {
            return
        }
        
        inputBuffer.removeLast(inputBufferCount - bytesRead)
        self.withDelegate({ delegate in
            delegate.didReceive(data: inputBuffer, on: self)
        }, sync: false)
    }

    fileprivate func onHasSpaceAvailable() {
        // Check the general state
        guard state != .stopped else {
            return
        }
        
        // Check if we have the output stream
        guard let outputStream = self.outputStream else {
            fatal("Output stream is missing")
        }
        
        // Check if we are already writing to the stream
        assert(outputStream.streamStatus != .writing, "Error: Trying to write into output stream, but stream is already writing. Threading issue?")
        
        // Check if the stream is errored
        guard outputStream.streamStatus != .error else {
            self.close()
            return
        }
        
        // Check if there is a data to write
        guard dataBuffer.data.count != 0 else {
            return
        }
        
        writeDataIfPossible()
    }
    
    fileprivate func writeDataIfPossible() {
        // Check if we have the output stream
        guard let outputStream = self.outputStream else {
            fatal("Output stream is missing")
        }
        
        guard outputStream.hasSpaceAvailable else {
            return
        }
        
        let data = dataBuffer.data
        
        let bytesWritten = data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Int in
            return outputStream.write(bytes, maxLength: data.count)
        }
        
        if bytesWritten > 0 {
            dataBuffer.clear(until: bytesWritten)
        }
    }
}

extension NetworkSocket: StreamDelegate {
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        preconditionQueue()

        switch (self.state, eventCode) {
        case (.connecting, .openCompleted):
            if aStream == outputStream {
                self.state = .connected
                self.withDelegate({ delegate in
                    delegate.didOpen(socket: self)
                }, sync: false)
            }
        case (.connected, .hasBytesAvailable):
            guard aStream == inputStream, checkTrust(for: aStream) else {
                return
            }
            self.onBytesAvailable()
        case (.connected, .hasSpaceAvailable):
            guard aStream == outputStream, checkTrust(for: aStream) else {
                return
            }
            self.onHasSpaceAvailable()
        case (_, .errorOccurred):
            fallthrough
        case (_, .endEncountered):
            self.close()
        default:
            return
        }
    }
}
