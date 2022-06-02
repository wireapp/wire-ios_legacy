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

/* 
 To export a certificate in ascii PEM format, run:
 
 openssl s_client -connect wire.com:443 -showcerts
 
 */


import Foundation
import XCTest
@testable import WireTransport

struct CertificateData: Decodable {
    var production: [Data]
    var external: [Data]
    var invalid: [Data]
}

struct PinnedKeysData: Decodable {
    var pinnedKeys: [TrustData]
}

extension SecTrust {

    static func trustWithChain(certificateData: [Data], file: StaticString = #file, line: UInt = #line) -> SecTrust? {
        let policy = SecPolicyCreateBasicX509()
        let certificates: [SecCertificate] = certificateData.compactMap {
            guard let cert = SecCertificateCreateWithData(nil, $0 as CFData) else { XCTFail("Failed to create certificate from data", file: file, line: line); return nil }
            return cert
        }
        var trust: SecTrust? = nil
        guard SecTrustCreateWithCertificates(certificates as CFTypeRef, policy, &trust) == 0 else { XCTFail("Failed to create trust from certificate chain", file: file, line: line); return nil }

        return trust
    }

}

class BackendTrustProviderTests: XCTestCase {

    var pinnedHosts: [String]!
    var certificates: CertificateData!
    var pinnedKeys: PinnedKeysData!
    var sut: ServerCertificateTrust!

    override func setUp() {
        super.setUp()
        // Do not run tests if setup fails
        continueAfterFailure = false
        pinnedHosts = ["prod-nginz-https.wire.com", "prod-nginz-ssl.wire.com", "prod-assets.wire.com", "www.wire.com", "wire.com"]
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let mainBundle = Bundle(for: type(of: self))
        guard let backendBundlePath = mainBundle.path(forResource: "Backend", ofType: "bundle") else { XCTFail("Could not find backend.bundle"); return }
        guard let backendBundle = Bundle(path: backendBundlePath) else { XCTFail("Could not load backend.bundle"); return }
        
        guard let certificatesURL = mainBundle.url(forResource: "certificates", withExtension: "json") else { XCTFail("Could find certificates.json"); return } 
        guard let trustDataURL = backendBundle.url(forResource: "production", withExtension: "json") else { XCTFail("Could find trust_data.json"); return } 
        
        do {
            let certsData = try Data(contentsOf: certificatesURL)            
            self.certificates = try decoder.decode(CertificateData.self, from: certsData)
        } catch {
            XCTFail("Error reading certs: \(error)")
        }
        
        do {
            let trustData = try Data(contentsOf: trustDataURL)
            
            self.pinnedKeys = try decoder.decode(PinnedKeysData.self, from: trustData)
        } catch {
            XCTFail("Error reading pinned keys: \(error)")
            
        }
        
        sut = ServerCertificateTrust(trustData: pinnedKeys.pinnedKeys)
        // If setup worked fine, run all tests
        continueAfterFailure = false
    }
    
    override func tearDown() {
        pinnedHosts = nil
        certificates = nil
        pinnedKeys = nil
        sut = nil
        super.tearDown()
    }
    
    func testThatItVerifiesWithNoPinnedKeys() {
        // given
        let trustExpectation = expectation(description: "It should verify server trust")
        let trustProvider = ServerCertificateTrust(trustData: [])
        let trustVerificator = TestTrustVerificator(trustProvider: trustProvider) { trusted in
            if trusted {
                trustExpectation.fulfill()
            } else {
                XCTFail("Server should be trusted!")
            }
        }
        
        // when
        trustVerificator.verify(url: URL(string: "https://www.youtube.com")!)
        
        // then
        waitForExpectations(timeout: 0.5)
    }
    
    func testThatVerificationFailsWithNoHost() {
        // given
        guard let serverTrust = SecTrust.trustWithChain(certificateData: certificates.production) else { XCTFail("Failed to create trust"); return }

        XCTAssertFalse(sut.verifyServerTrust(trust: serverTrust, host: nil))
    }

    /// Test certificate pinning against production certificate.
    ///
    /// if this tests fails it's most likely because the production certificate
    /// in `certificates.json` has expired. The production certificate can be
    /// updated by running:
    ///
    ///      openssl s_client -connect prod-nginz-https.wire.com:443 -showcerts
    ///
    func testPinnedHostsWithValidCertificateIsTrustedAreTrusted() {
        // given
        guard let serverTrust = SecTrust.trustWithChain(certificateData: certificates.production) else { XCTFail("Failed to create trust"); return }
        
        // then
        for host in pinnedHosts {
            XCTAssertTrue(sut.verifyServerTrust(trust: serverTrust, host: host), "\(host) should be trusted")
        }
    }
    
    func testPinnedHostsAreNotTrustedWithWrongCertificate() {
        // given
        guard let serverTrust = SecTrust.trustWithChain(certificateData: certificates.external) else { XCTFail("Failed to create trust"); return }
        
        // then
        for host in pinnedHosts {
            XCTAssertFalse(sut.verifyServerTrust(trust: serverTrust, host: host), "\(host) should NOT be trusted")
        }
    }
    
    func testExternalHostWithValidCertificateIsTrusted() {
        // given
        let trustExpectation = expectation(description: "It should verify server trust")
        let trustVerificator = TestTrustVerificator { trusted in
            if trusted {
                trustExpectation.fulfill()
            } else {
                XCTFail("Server should be trusted!")
            }
        }
        
        // when
        trustVerificator.verify(url: URL(string: "https://www.youtube.com")!)
        
        // then
        waitForExpectations(timeout: 5.0)
    }
    
    func testExternalHostWithInvalidCertificateIsNotTrusted() {
        // given
        guard let serverTrust = SecTrust.trustWithChain(certificateData: certificates.invalid) else { XCTFail("Failed to create trust"); return }
        
        // then
        let host = "www.youtube.com"
        XCTAssertFalse(sut.verifyServerTrust(trust: serverTrust, host: host), "\(host) should NOT be trusted")
    }
}
