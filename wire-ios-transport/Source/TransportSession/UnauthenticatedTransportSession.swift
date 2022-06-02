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


public enum EnqueueResult {
    case success, nilRequest, maximumNumberOfRequests
}

public protocol UnauthenticatedTransportSessionProtocol: TearDownCapable {

    func enqueueOneTime(_ request: ZMTransportRequest)
    func enqueueRequest(withGenerator generator: ZMTransportRequestGenerator) -> EnqueueResult
    func tearDown()
    
    var environment: BackendEnvironmentProvider { get }
}


@objcMembers public class UserInfo: NSObject {
    public let identifier: UUID
    public let cookieData: Data
    
    public init(identifier: UUID, cookieData: Data) {
        self.identifier = identifier
        self.cookieData = cookieData
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UserInfo else { return false }
        return other.cookieData == cookieData && other.identifier == identifier
    }
}


private let zmLog = ZMSLog(tag: "Network")


fileprivate extension ZMTransportRequest {
    func log() -> Void {
        zmLog.debug("[Unauthenticated] ----> Request: \(description)")
    }
}

fileprivate extension ZMTransportResponse {
    func log() -> Void {
        zmLog.debug("[Unauthenticated] <---- Response: \(description)")
    }
}


/// The `UnauthenticatedTransportSession` class should be used instead of `ZMTransportSession`
/// until a user has been authenticated. Consumers should set themselves as delegate to 
/// be notified when a cookie was parsed from a response of a request made using this transport session.
/// When cookie data became available it should be used to create a `ZMPersistentCookieStorage` and
/// to create a regular transport session with it.
final public class UnauthenticatedTransportSession: NSObject, UnauthenticatedTransportSessionProtocol {

    private let maximumNumberOfRequests: Int = 3
    private var numberOfRunningRequests = ZMAtomicInteger(integer: 0)
    private let baseURL: URL
    private var session: SessionProtocol!
    private let userAgent: ZMUserAgent
    public var environment: BackendEnvironmentProvider
    fileprivate let reachability: ReachabilityProvider
    
    public init(environment: BackendEnvironmentProvider,
                urlSession: SessionProtocol? = nil,
                reachability: ReachabilityProvider,
                applicationVersion: String) {
        self.baseURL = environment.backendURL
        self.environment = environment
        self.reachability = reachability
        self.userAgent = ZMUserAgent()
        
        super.init()
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = ["User-Agent": ZMUserAgent.userAgent(withAppVersion: applicationVersion)]
        
        self.session = urlSession ?? URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    
    /// Enqueues a single request on the internal `URLSession`.
    ///
    /// - parameter request: Request which should be enqueued.
    ///
    /// The concurrent request limit does apply to when using this method
    public func enqueueOneTime(_ request: ZMTransportRequest) {
        _ = increment()
        enqueueRequest(request)
    }

    /// Creates and resumes a request on the internal `URLSession`.
    /// If there are too many requests in progress no request will be enqueued.
    /// - parameter generator: The closure used to retrieve a new request.
    /// - returns: The result of the enqueue operation.
    public func enqueueRequest(withGenerator generator: ZMTransportRequestGenerator) -> EnqueueResult {
        // Increment the running requests count and return early in case we are above the limit.
        let newCount = increment()
        if maximumNumberOfRequests < newCount {
            decrement(notify: false)
            return .maximumNumberOfRequests
        }

        // Ask the generator to create a request and return early if there is none.
        guard let request = generator() else {
            decrement(notify: false)
            return .nilRequest
        }
        
        enqueueRequest(request)

        return .success
    }
    
    @discardableResult
    private func enqueueRequest(_ request: ZMTransportRequest) -> DataTaskProtocol {
        guard let urlRequest = URL(string: request.path, relativeTo: baseURL).flatMap(NSMutableURLRequest.init) else { preconditionFailure() }
        urlRequest.configure(with: request)
        request.log()
        
        let task = session.task(with: urlRequest as URLRequest) { [weak self] data, response, error in
            
            var transportResponse: ZMTransportResponse!
            
            if let response = response as? HTTPURLResponse {
                transportResponse = ZMTransportResponse(httpurlResponse: response, data: data, error: error, apiVersion: request.apiVersion)
            }
            else if let error = error {
                transportResponse = ZMTransportResponse(transportSessionError: error, apiVersion: request.apiVersion)
            }
            
            if nil == transportResponse {
                preconditionFailure()
            }
            
            transportResponse?.log()
            request.complete(with: transportResponse)
            self?.decrement(notify: true)
        }
        
        task.resume()
        
        return task
    }

    /// Decrements the number of running requests and posts a new
    /// request notification in case we are below the limit.
    /// - parameter notify: Whether a new request available notificaiton should be posted
    /// when the amount of running requests is below the maximum after decrementing.
    private func decrement(notify: Bool) {
        let newCount = numberOfRunningRequests.decrement()
        guard newCount < maximumNumberOfRequests, notify else { return }
        ZMTransportSession.notifyNewRequestsAvailable(self)
    }

    /// Increments the number of running requests.
    /// - returns: The value after the increment.
    private func increment() -> Int {
        return numberOfRunningRequests.increment()
    }
    
    public func tearDown() {
        // From NSURLSession documentation at https://developer.apple.com/documentation/foundation/urlsession:
        // "The session object keeps a strong reference to the delegate until your app 
        // exits or explicitly invalidates the session. 
        // If you do not invalidate the session, your app leaks memory until it exits."
        self.session = nil
    }

}

// MARK: - SSL Pinning

extension UnauthenticatedTransportSession: URLSessionDelegate {

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let protectionSpace = challenge.protectionSpace
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            // It's safe to force-unwrap protectionSpace.serverTrust because according to docs it has to be present with this authentication method
            guard environment.verifyServerTrust(trust: protectionSpace.serverTrust!, host: protectionSpace.host) else { return completionHandler(.cancelAuthenticationChallenge, nil) }
        }
        completionHandler(.performDefaultHandling, challenge.proposedCredential)
    }

}

// MARK: - Request Configuration

extension NSMutableURLRequest {

    @objc(configureWithRequest:) func configure(with request: ZMTransportRequest) {
        httpMethod = request.methodAsString
        request.setAcceptedResponseMediaTypeOnHTTP(self)
        request.setBodyDataAndMediaTypeOnHTTP(self)
        request.setAdditionalHeaderFieldsOnHTTP(self)
        request.setContentDispositionOnHTTP(self)
    }

}

// MARK: - Cookie Parsing

private enum CookieKey: String {
    case zetaId = "zuid"
    case properties
}

private enum HeaderKey: String {
    case cookie = "Set-Cookie"
}

private enum UserKey: String {
    case user, id
}

extension ZMTransportResponse {

    /// Extracts the wire cookie data from the response.
    /// - returns: The encrypted cookie data (using the cookies key) if there is any.
    private func extractCookieData() -> Data? {
        guard let response = rawResponse else { return nil }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: response.allHeaderFields as! [String : String], for: response.url!)
        return HTTPCookie.extractData(from: cookies)
    }

    private func extractUserIdentifier() -> UUID? {
        guard let data = payload as? [String: Any] else { return nil }
        return (data[UserKey.user.rawValue] as? String).flatMap(UUID.init)
            ?? (data[UserKey.id.rawValue] as? String).flatMap(UUID.init)
    }

    @objc public func extractUserInfo() -> UserInfo? {
        guard let data = extractCookieData(), let id = extractUserIdentifier() else { return nil }
        return .init(identifier: id, cookieData: data)
    }

}

extension HTTPCookie {
    
    static func cookies(from string: String, for url: URL) -> [HTTPCookie] {
        let headers = [HeaderKey.cookie.rawValue: string]
        return HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
    }

    public static func extractCookieData(from cookieString: String, url: URL) -> Data? {
        let cookies = HTTPCookie.cookies(from: cookieString, for: url)
        return extractData(from: cookies)
    }
    
    fileprivate static func extractData(from cookies: [HTTPCookie]) -> Data? {
        guard !cookies.isEmpty else { return nil }
        let properties = cookies.compactMap(\.properties)
        guard let name = properties.first?[.name] as? String, name == CookieKey.zetaId.rawValue else { return nil }
        
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(properties, forKey: CookieKey.properties.rawValue)
        archiver.finishEncoding()
        let data = archiver.encodedData
        let key = UserDefaults.cookiesKey()!
        return data.zmEncryptPrefixingIV(key: key).base64EncodedData()
    }

}
