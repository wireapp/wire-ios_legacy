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
import WireTesting

@testable import WireRequestStrategy

class MockDependencyEntity: DependencyEntity, Hashable {
    public var expirationDate: Date?
    public var isExpired: Bool = false
    fileprivate let uuid = UUID()

    public func expire() {
         isExpired = true
    }

    var dependentObjectNeedingUpdateBeforeProcessing: NSObject?

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.uuid)
    }
}

func == (lhs: MockDependencyEntity, rhs: MockDependencyEntity) -> Bool {
    return lhs === rhs
}

class MockEntityTranscoder: EntityTranscoder {

    var didCallRequestForEntityCount: Int = 0
    var didCallRequestForEntityDidCompleteWithResponse: Bool = false
    var didCallShouldTryToResendAfterFailure: Bool = false

    var shouldResendOnFailure = false
    var generatedRequest: ZMTransportRequest?

    var requestForEntityExpectation: XCTestExpectation?
    var requestForEntityDidCompleteWithResponseExpectation: XCTestExpectation?
    var shouldTryToResendAfterFailureExpectation: XCTestExpectation?

    func request(forEntity entity: MockDependencyEntity, apiVersion: APIVersion) -> ZMTransportRequest? {
        requestForEntityExpectation?.fulfill()
        didCallRequestForEntityCount += 1
        return generatedRequest
    }

    func request(forEntity entity: MockDependencyEntity, didCompleteWithResponse response: ZMTransportResponse) {
        requestForEntityDidCompleteWithResponseExpectation?.fulfill()
        didCallRequestForEntityDidCompleteWithResponse = true
    }

    func shouldTryToResend(entity: MockDependencyEntity, afterFailureWithResponse response: ZMTransportResponse) -> Bool {
        shouldTryToResendAfterFailureExpectation?.fulfill()
        didCallShouldTryToResendAfterFailure = true
        return shouldResendOnFailure
    }

}

class DependencyEntitySyncTests: ZMTBaseTest {

    var context: NSManagedObjectContext!
    var mockTranscoder = MockEntityTranscoder()
    var sut: DependencyEntitySync<MockEntityTranscoder>!
    var dependency: MockEntity!
    var anotherDependency: MockEntity!

    override func setUp() {
        super.setUp()

        context = MockModelObjectContextFactory.testContext()
        dependency = MockEntity.insertNewObject(in: context)
        anotherDependency = MockEntity.insertNewObject(in: context)

        sut = DependencyEntitySync(transcoder: mockTranscoder, context: context)
    }

    // Mark - Request creation

    func testThatTranscoderIsAskedToCreateRequest_whenEntityHasNoDependencies() {

        // given
        let entity = MockDependencyEntity()

        // when
        sut.synchronize(entity: entity)
        _ = sut.nextRequest(for: .v0)

        // then
        XCTAssertEqual(mockTranscoder.didCallRequestForEntityCount, 1)
    }

    func testThatTranscoderIsNotAskedToCreateRequest_whenEntityHasDependencies() {

        // given
        let entity = MockDependencyEntity()
        entity.dependentObjectNeedingUpdateBeforeProcessing = dependency

        // when
        sut.synchronize(entity: entity)
        _ = sut.nextRequest(for: .v0)

        // then
        XCTAssertEqual(mockTranscoder.didCallRequestForEntityCount, 0)
    }

    func testThatEntityIsExpired_whenExpiringEntitiesWithDependencies() {
        // given
        let entity = MockDependencyEntity()
        entity.dependentObjectNeedingUpdateBeforeProcessing = dependency
        sut.synchronize(entity: entity)

        // when
        sut.expireEntities(withDependency: dependency)

        // then
        XCTAssertTrue(entity.isExpired)
    }

    func testThatTranscoderIsNotAskedToCreateRequest_whenEntityHasSwappedDependenciesAfterAnUpdate() {

        // given
        let entity = MockDependencyEntity()
        let dependencySet: Set<NSManagedObject> = [dependency]
        entity.dependentObjectNeedingUpdateBeforeProcessing = dependency
        sut.synchronize(entity: entity)

        // when
        entity.dependentObjectNeedingUpdateBeforeProcessing = anotherDependency
        sut.objectsDidChange(dependencySet)
        _ = sut.nextRequest(for: .v0)

        // then
        XCTAssertEqual(mockTranscoder.didCallRequestForEntityCount, 0)
    }

    func testThatTranscoderIsNotAskedToCreateRequest_whenEntityHasExpired() {

        // given
        let entity = MockDependencyEntity()
        sut.synchronize(entity: entity)
        entity.expire()

        // when
        _ = sut.nextRequest(for: .v0)

        // then
        XCTAssertEqual(mockTranscoder.didCallRequestForEntityCount, 0)
    }

    func testThatTranscoderIsAskedToCreateRequest_whenEntityHasNoDependenciesAfterAnUpdate() {

        // given
        let entity = MockDependencyEntity()
        let dependencySet: Set<NSManagedObject> = [dependency]
        entity.dependentObjectNeedingUpdateBeforeProcessing = dependency
        sut.synchronize(entity: entity)

        // when
        entity.dependentObjectNeedingUpdateBeforeProcessing = nil
        sut.objectsDidChange(dependencySet)
        _ = sut.nextRequest(for: .v0)

        // then
        XCTAssertEqual(mockTranscoder.didCallRequestForEntityCount, 1)
    }

    func testThatTranscoderIsAskedToCreateRequestOnlyOnce_whenEntityHadMultipleDependencies() {

        // given
        let entity = MockDependencyEntity()
        let dependencySet: Set<NSManagedObject> = [dependency]
        let dependencyAndAnotherDependencySet: Set<NSManagedObject> = [dependency, anotherDependency]
        entity.dependentObjectNeedingUpdateBeforeProcessing = dependency
        sut.synchronize(entity: entity)

        entity.dependentObjectNeedingUpdateBeforeProcessing = anotherDependency
        sut.objectsDidChange(dependencySet)

        // when
        entity.dependentObjectNeedingUpdateBeforeProcessing = nil
        sut.objectsDidChange(dependencyAndAnotherDependencySet)
        _ = sut.nextRequest(for: .v0)
        _ = sut.nextRequest(for: .v0)

        // then
        XCTAssertEqual(mockTranscoder.didCallRequestForEntityCount, 1)
    }

    // Mark - Response handling

    func testThatTranscoderIsAskedToHandleSuccessfullResponse() {
        // given
        mockTranscoder.generatedRequest = ZMTransportRequest(getFromPath: "/foo", apiVersion: APIVersion.v0.rawValue)
        mockTranscoder.requestForEntityDidCompleteWithResponseExpectation = expectation(description: "Was asked to handle response")

        let entity = MockDependencyEntity()
        sut.synchronize(entity: entity)
        let request = sut.nextRequest(for: .v0)

        // when
        let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        request?.complete(with: response)

        // then
         XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatTranscoderIsAskedToHandleFailureResponse() {
        // given
        mockTranscoder.generatedRequest = ZMTransportRequest(getFromPath: "/foo", apiVersion: APIVersion.v0.rawValue)
        mockTranscoder.shouldTryToResendAfterFailureExpectation = expectation(description: "Was asked to resend request")

        let entity = MockDependencyEntity()
        sut.synchronize(entity: entity)
        let request = sut.nextRequest(for: .v0)

        // when
        let response = ZMTransportResponse(payload: nil, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        request?.complete(with: response)

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatTranscoderIsAskedToCreateRequest_whenTranscoderWantsToResendRequest() {
        // given
        mockTranscoder.generatedRequest = ZMTransportRequest(getFromPath: "/foo", apiVersion: APIVersion.v0.rawValue)
        mockTranscoder.shouldTryToResendAfterFailureExpectation = expectation(description: "Was asked to resend request")
        mockTranscoder.shouldResendOnFailure = true

        let entity = MockDependencyEntity()
        sut.synchronize(entity: entity)
        let request = sut.nextRequest(for: .v0)

        let response = ZMTransportResponse(payload: nil, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        request?.complete(with: response)

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5)) // wait for response to fail
        mockTranscoder.didCallRequestForEntityCount = 0 // reset since we expect it be called again

        // when
        _ = sut.nextRequest(for: .v0)

        // then
        XCTAssertEqual(mockTranscoder.didCallRequestForEntityCount, 1)
    }

}
