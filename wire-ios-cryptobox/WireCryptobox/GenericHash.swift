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

import Foundation

/// Encapsulates the hash value.

public struct GenericHash: Hashable {
    private let value: Int

    init(value: Int) {
        self.value = value
    }
}

extension GenericHash: CustomStringConvertible {
    public var description: String {
        return "GenericHash \(hashValue)"
    }
}

/// This class is designed to generate the hash value for the given input data.
/// Sample usage:
///
///     let builder = GenericHashBuilder()
///     builder.append(data1)
///     builder.append(data2)
///     let hash = builder.build()
public final class GenericHashBuilder {
    private enum State {
        case initial
        case readyToBuild
        case done
    }


    
    private var cryptoState: UnsafeMutableRawBufferPointer
    private var opaqueCryptoState: OpaquePointer


    private var state: State = .initial
    private static let size = MemoryLayout<Int>.size
    
    init() {
        cryptoState = UnsafeMutableRawBufferPointer.allocate(byteCount: crypto_generichash_statebytes(), alignment: 64)
        opaqueCryptoState = OpaquePointer(cryptoState.baseAddress!)

        crypto_generichash_init(opaqueCryptoState, nil, 0, GenericHashBuilder.size)
    }
    
    public func append(_ data: Data) {
        assert(state != .done, "This builder cannot be used any more: hash is already calculated")
        state = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> State in
            crypto_generichash_update(opaqueCryptoState, bytes.baseAddress!.assumingMemoryBound(to: UInt8.self), UInt64(data.count))
            return .readyToBuild
        }
    }
    
    public func build() -> GenericHash {
        assert(state != .done, "This builder cannot be used any more: hash is already calculated")
        var hashBytes: Array<UInt8> = Array(repeating: 0, count: GenericHashBuilder.size)
        crypto_generichash_final(opaqueCryptoState, &hashBytes, GenericHashBuilder.size)
        state = .done
        
        let bigEndianValue = hashBytes.withUnsafeBufferPointer {
            ($0.baseAddress!.withMemoryRebound(to: Int.self, capacity: 1) { $0 })
            }.pointee
        
        return GenericHash(value: Int(bigEndian: bigEndianValue))
    }
}
