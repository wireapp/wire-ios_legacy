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

extension MockTransportSession {

    // V3

    @objc(processAssetV3DeleteWithKey:apiVersion:)
    public func processAssetV3Delete(withKey key: String, apiVersion: APIVersion) -> ZMTransportResponse {
        if let asset = MockAsset(in: managedObjectContext, forID: key) {
            managedObjectContext.delete(asset)
            return ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
        } else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: apiVersion.rawValue)
        }
    }

    // V4

    @objc(processAssetV4PostWithDomain:multipart:apiVersion:)
    public func processAssetV4Post(with domain: String, multipart: [ZMMultipartBodyItem], apiVersion: APIVersion) -> ZMTransportResponse {
        guard
            multipart.count == 2,
            let jsonObject = multipart.first,
            let json = (try? JSONSerialization.jsonObject(with: jsonObject.data, options: .allowFragments)) as? [String: Any] ,
            let imageData = multipart.last,
            let mimeType = imageData.contentType
        else {
            return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil, apiVersion: apiVersion.rawValue)
        }

        let asset = MockAsset.insert(into: managedObjectContext)
        asset.data = imageData.data
        asset.contentType = mimeType
        asset.identifier = UUID.create().transportString()
        asset.domain = domain

        if json["public"] as? Bool == false {
            asset.token = UUID.create().transportString()
        }

        let payload = [
            "key": asset.identifier,
            "domain": domain,
            "token": asset.token
        ].compactMapValues { $0 } as ZMTransportData

        let location = String(format: "/asset/v4/%@", arguments: [asset.identifier])
        return ZMTransportResponse(payload: payload,
                                   httpStatus: 201,
                                   transportSessionError: nil,
                                   headers: ["Location": location],
                                   apiVersion: apiVersion.rawValue)
    }

    @objc(processAssetV4GetWithDomain:key:apiVersion:)
    public func processAssetV4Get(with domain: String, key: String, apiVersion: APIVersion) -> ZMTransportResponse {
        if let asset = MockAsset(in: managedObjectContext, forID: key, domain: domain) {
            return ZMTransportResponse(imageData: asset.data, httpStatus: 200, transportSessionError: nil, headers: nil, apiVersion: apiVersion.rawValue)
        }
        return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }

    @objc(processAssetV4DeleteWithDomain:key:apiVersion:)
    public func processAssetV4Delete(with domain: String, key: String, apiVersion: APIVersion) -> ZMTransportResponse {
        if let asset = MockAsset(in: managedObjectContext, forID: key, domain: domain) {
            managedObjectContext.delete(asset)
            return ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: apiVersion.rawValue)
        } else {
            return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: apiVersion.rawValue)
        }
    }
}
