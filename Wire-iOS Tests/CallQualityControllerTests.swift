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
@testable import Wire

class CallQualityControllerTests: ZMSnapshotTestCase {

    var qualityController: CallQualityViewController?

    override func tearDown() {
        qualityController = nil
        super.tearDown()
    }

    func testSurveyRequestValidation() {

        // When the survey was never presented, it is possible to request it
        let initialDate = Date()
        CallQualityScoreProvider.resetSurveyMuteFilter()
        XCTAssertTrue(CallQualityScoreProvider.canRequestSurvey(at: initialDate))

        CallQualityScoreProvider.updateLastSurveyDate(initialDate)

        // During the mute time interval, it is not possible to request it
        let mutedRequestDate = Date()
        XCTAssertFalse(CallQualityScoreProvider.canRequestSurvey(at: mutedRequestDate))

        // After the mute time interval, it is not possible to request it
        let postMuteDate = mutedRequestDate.addingTimeInterval(2)
        XCTAssertTrue(CallQualityScoreProvider.canRequestSurvey(at: postMuteDate, muteInterval: 1))

    }

    func configure(view: UIView, isTablet: Bool) {
        qualityController?.dimmingView.alpha = 1
        qualityController?.updateLayout(isRegular: isTablet)
    }

    func testSurveyInterface() {
        CallQualityScoreProvider.resetSurveyMuteFilter()
        let qualityController = CallQualityViewController.requestSurveyController(callDuration: 10)!
        self.qualityController = qualityController
        verifyInAllDeviceSizes(view: qualityController.view, configuration: configure)
    }

}
