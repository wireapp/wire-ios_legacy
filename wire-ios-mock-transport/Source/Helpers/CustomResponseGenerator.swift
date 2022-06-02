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

@objcMembers public class ResponseGenerator : NSObject {
    
    /// When defining a custom response generator, you can return this object and it will
    /// prevent the request from being completed - it will be in a suspended state until
    /// `completeAllBlockedRequests` is called.
    static public let ResponseNotCompleted : ZMTransportResponse = ZMTransportResponse(
        payload: ["label":"This will prevent the response from being completed. The completion handler won't be called at all."] as ZMTransportData,
        httpStatus: 500,
        transportSessionError: nil,
        apiVersion: 0
    )

}
