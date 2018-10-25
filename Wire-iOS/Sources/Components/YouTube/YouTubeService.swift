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

/**
 * Errors that can occur when interacting with the YouTube service.
 */

enum YouTubeServiceError: Error {
    case invalidVideoID, invalidResponse, noData
}

/**
 * An object that interfaces with the YouTube API.
 */

@objc class YouTubeService: NSObject {

    let requester: ProxiedURLRequester?

    var currentRequester: ProxiedURLRequester? {
        return requester ?? ZMUserSession.shared()
    }

    /// The shared YouTube service, that always uses the current user session.
    @objc(sharedInstance) static let shared = YouTubeService(requester: nil)

    @objc init(requester: ProxiedURLRequester?) {
        self.requester = requester
    }

    // MARK: - Video Lookup

    @objc func fetchMediaPreviewDataForVideo(at videoURL: URL, completion: @escaping (MediaPreviewData?, Error?) -> Void) {

        guard let videoID = self.videoID(for: videoURL) else {
            completion(nil, YouTubeServiceError.invalidVideoID)
            return
        }

        let path = "/v3/videos?id=\(videoID)&part=snippet"

        currentRequester?.doRequest(withPath: path, method: .methodGET, type: .youTube) {
            self.handleVideoLookupResponse($0, $1, $2, completion: completion)
        }

    }

    func handleVideoLookupResponse(_ data: Data?, _ response: URLResponse?, _ err: Error?, completion: @escaping (MediaPreviewData?, Error?) -> Void) {

        do {
            let data = try validateJSONResponse(data, response, err)
            let mediaPreview = try makeVideoMediaPreview(from: data)
            completion(mediaPreview, nil)
        } catch {
            completion(nil, error)
        }

    }

    // MARK: - Utilities

    /**
     * Returns the YouTube video identifier from the given URL.
     *
     * - parameter url: The URL that contains the video ID. This must be
     * a YouTube URL.
     *
     * - returns: The ID of the video if it could be found, or `nil` if the URL
     * is not in the correct format.
     */

    func videoID(for url: URL) -> String? {

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        if let idComponent = components.queryItems?.first(where: { $0.name == "v" }) {
            return idComponent.value
        }

        if let lastPathComponent = url.pathComponents.last, !lastPathComponent.isEmpty {
            return lastPathComponent
        }

        return nil

    }

    /**
     * Validates the JSON response and returns the JSON data if appropriate.
     */

    func validateJSONResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) throws -> Data {

        if let error = error {
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw YouTubeServiceError.invalidResponse
        }

        guard let data = data else {
            throw YouTubeServiceError.noData
        }

        return data

    }

    /**
     * Creates the media preview data from the JSON response describing a video.
     *
     * - parameter data: The JSON data containing the video lookup response. This must
     * be the result of a single video search, made for a specific identifier.
     *
     * - throws: If the data is not valid, throws `YouTubeServiceError.invalidResponse`.
     * - returns: If the data is valid, returns the `MediaPreviewData` representing the video.
     */

    func makeVideoMediaPreview(from data: Data) throws -> MediaPreviewData {

        let decoder = JSONDecoder()
        let response = try decoder.decode(YouTubeVideoLookupResponse.self, from: data)

        guard let snippet = response.items.first?.snippet else {
            throw YouTubeServiceError.invalidResponse
        }

        let thumbnails = snippet.thumbnails.values.map {
            MediaThumbnail(url: $0.url, size: CGSize(width: $0.width, height: $0.height))
        }

        return MediaPreviewData(title: snippet.title, thumbnails: thumbnails, provider: .youtube)

    }

}
