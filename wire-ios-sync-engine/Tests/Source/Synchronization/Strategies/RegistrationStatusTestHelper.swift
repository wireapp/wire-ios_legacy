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

class TestRegistrationStatus: WireSyncEngine.RegistrationStatusProtocol {
    var handleErrorCalled = 0
    var handleErrorError: Error?
    func handleError(_ error: Error) {
        handleErrorCalled += 1
        handleErrorError = error
    }

    var successCalled = 0
    func success() {
        successCalled += 1
    }

    var phase: RegistrationPhase = .none
}

protocol RegistrationStatusStrategyTestHelper {
    var registrationStatus: TestRegistrationStatus! { get }
    func handleResponse(response: ZMTransportResponse)
}

extension RegistrationStatusStrategyTestHelper {
    func checkResponseError(with phase: RegistrationPhase, code: ZMUserSessionErrorCode, errorLabel: String, httpStatus: NSInteger, file: StaticString = #file, line: UInt = #line) {
        registrationStatus.phase = phase

        let expectedError = NSError(code: code, userInfo: [:])
        let payload = [
            "label": errorLabel,
            "message": "some"
        ]

        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: httpStatus, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

        // when
        XCTAssertEqual(registrationStatus.successCalled, 0, "Success should not be called", file: file, line: line)
        XCTAssertEqual(registrationStatus.handleErrorCalled, 0, "HandleError should not be called", file: file, line: line)
        handleResponse(response: response)

        // then
        XCTAssertEqual(registrationStatus.successCalled, 0, "Success should not be called", file: file, line: line)
        XCTAssertEqual(registrationStatus.handleErrorCalled, 1, "HandleError should be called", file: file, line: line)
        XCTAssertEqual(registrationStatus.handleErrorError as NSError?, expectedError, "HandleError should be called with error: \(expectedError), but was \(registrationStatus.handleErrorError?.localizedDescription ?? "nil")", file: file, line: line)
    }
}
