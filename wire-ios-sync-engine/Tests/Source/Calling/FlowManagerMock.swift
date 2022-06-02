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

@testable import WireSyncEngine

@objcMembers
public class FlowManagerMock: NSObject, FlowManagerType {

    public var callConfigContext: UnsafeRawPointer?
    public var callConfigHttpStatus: Int = 0
    public var callConfig: Data?
    public var didReportCallConfig: Bool = false
    public var didSetVideoCaptureDevice: Bool = false

    override init() {
        super.init()
    }

    public func appendLog(for conversationId: UUID, message: String) {

    }

    public func report(callConfig: Data?, httpStatus: Int, context: UnsafeRawPointer) {
        self.callConfig = callConfig
        callConfigContext = context
        callConfigHttpStatus = httpStatus
        didReportCallConfig = true
    }

    public func setVideoCaptureDevice(_ device: CaptureDevice, for conversationId: AVSIdentifier) {
        didSetVideoCaptureDevice = true
    }

}
