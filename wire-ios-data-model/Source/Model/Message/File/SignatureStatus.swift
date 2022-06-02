//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

// MARK: - SignatureObserver
@objc(ZMSignatureObserver)
public protocol SignatureObserver: NSObjectProtocol {
    func willReceiveSignatureURL()
    func didReceiveSignatureURL(_ url: URL)
    func didReceiveDigitalSignature(_ cmsFileMetadata: ZMFileMetadata)
    func didFailSignature(errorType: SignatureStatus.ErrorYpe)
}

// MARK: - SignatureStatus
public enum PDFSigningState {
    case initial
    case waitingForConsentURL
    case waitingForCodeVerification
    case waitingForSignature
    case signatureInvalid
    case finished
}

private let log = ZMSLog(tag: "Conversations")

@objc
public final class SignatureStatus: NSObject {

    @objc
    public enum ErrorYpe: Int {
        case noConsentURL
        case retrieveFailed
    }

    // MARK: - Private Property
    private(set) var asset: WireProtos.Asset?
    private(set) var managedObjectContext: NSManagedObjectContext

    // MARK: - Public Property
    public var state: PDFSigningState = .initial
    public var documentID: String?
    public var fileName: String?
    public var encodedHash: String?

    // MARK: - Init
    public init(asset: WireProtos.Asset?,
                data: Data?,
                managedObjectContext: NSManagedObjectContext) {
        self.asset = asset
        self.managedObjectContext = managedObjectContext

        documentID = asset?.uploaded.assetID
        fileName = asset?.original.name.removingExtremeCombiningCharacters

        encodedHash = data?
            .zmSHA256Digest()
            .base64String()
    }

    // MARK: - Public Method
    public func signDocument() {
        guard encodedHash != nil else {
            return
        }
        state = .waitingForConsentURL
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        DigitalSignatureNotification(state: .consentURLPending)
            .post(in: managedObjectContext.notificationContext)
    }

    public func retrieveSignature() {
         guard case .waitingForCodeVerification = state else { return }
         state = .waitingForSignature
         RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }

    public func didReceiveConsentURL(_ url: URL?) {
        guard let consentURL = url else {
            state = .signatureInvalid
            DigitalSignatureNotification(state: .signatureInvalid(errorType: .noConsentURL))
                .post(in: managedObjectContext.notificationContext)
            return
        }
        state = .waitingForCodeVerification
        DigitalSignatureNotification(state: .consentURLReceived(consentURL))
            .post(in: managedObjectContext.notificationContext)
    }

    public func didReceiveSignature(with data: Data?) {
        guard
            let cmsData = data,
            let fileMetaDataInfo = writeCMSSignatureFile(for: cmsData)
        else {
            state = .signatureInvalid
            DigitalSignatureNotification(state: .signatureInvalid(errorType: .retrieveFailed))
                .post(in: managedObjectContext.notificationContext)
            return
        }

        state = .finished
        let fileMetaData = ZMFileMetadata(fileURL: fileMetaDataInfo.url,
                                          name: fileMetaDataInfo.fileName)
        DigitalSignatureNotification(state: .digitalSignatureReceived(fileMetaData))
            .post(in: managedObjectContext.notificationContext)
    }

    public func didReceiveError(_ errorType: ErrorYpe) {
        state = .signatureInvalid
        DigitalSignatureNotification(state: .signatureInvalid(errorType: errorType))
            .post(in: managedObjectContext.notificationContext)
    }

    public func store() {
        managedObjectContext.signatureStatus = self
    }

    // MARK: - Private Method
    private func writeCMSSignatureFile(for data: Data) -> CMSFileMetadataInfo? {
        guard
            let fileName = fileName?.replacingOccurrences(of: ".pdf", with: ""),
            let assetID = documentID,
            !assetID.isEmpty
        else {
            return nil
        }

        let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let cmsFileName = "\(fileName)(\(assetID)).cms"
        let cmsURL = temporaryURL.appendingPathComponent(cmsFileName)
        do {
            try data.write(to: cmsURL)
        } catch {
            log.error("Failed to decode SignatureRetrieveResponse with \(error)")
        }

        return CMSFileMetadataInfo(url: cmsURL, fileName: cmsFileName)
    }
}

// MARK: - Observable
public extension SignatureStatus {
    static func addObserver(_ observer: SignatureObserver,
                            context: NSManagedObjectContext) -> Any {
        return NotificationInContext.addObserver(name: DigitalSignatureNotification.notificationName,
                                                 context: context.notificationContext,
                                                 queue: .main) { [weak observer] note in
            if let note = note.userInfo[DigitalSignatureNotification.userInfoKey] as? DigitalSignatureNotification {
                switch note.state {
                case .consentURLPending:
                    observer?.willReceiveSignatureURL()
                case let .consentURLReceived(consentURL):
                    observer?.didReceiveSignatureURL(consentURL)
                case let .signatureInvalid(errorType):
                    observer?.didFailSignature(errorType: errorType)
                case let .digitalSignatureReceived(cmsData):
                    observer?.didReceiveDigitalSignature(cmsData)
                }
            }
        }
    }
}

// MARK: - DigitalSignatureNotification
public class DigitalSignatureNotification: NSObject {

    // MARK: - State
    public enum State {
        case consentURLPending
        case consentURLReceived(_ consentURL: URL)
        case signatureInvalid(errorType: SignatureStatus.ErrorYpe)
        case digitalSignatureReceived(_ cmsFileMetaData: ZMFileMetadata)
    }

    // MARK: - Public Property
    public static let notificationName = Notification.Name("DigitalSignatureNotification")
    public static let userInfoKey = notificationName.rawValue

    public let state: State

    // MARK: - Init
    public init(state: State) {
        self.state = state
        super.init()
    }

    // MARK: - Public Method
    public func post(in context: NotificationContext) {
        NotificationInContext(name: DigitalSignatureNotification.notificationName,
                              context: context,
                              userInfo: [DigitalSignatureNotification.userInfoKey: self]).post()
    }
}

// MARK: - CMSFileMetadataInfo
private struct CMSFileMetadataInfo {
    let url: URL
    let fileName: String

    public init(url: URL, fileName: String) {
        self.url = url
        self.fileName = fileName
    }
}

// MARK: - NSManagedObjectContext
extension NSManagedObjectContext {
    private static let signatureStatusKey = "SignatureStatus"

    @objc public var signatureStatus: SignatureStatus? {
        get {
            precondition(zm_isSyncContext, "signatureStatus can only be accessed on the sync context")
            return self.userInfo[NSManagedObjectContext.signatureStatusKey] as? SignatureStatus
        }
        set {
            precondition(zm_isSyncContext, "signatureStatus can only be accessed on the sync context")
            self.userInfo[NSManagedObjectContext.signatureStatusKey] = newValue
        }
    }
}
