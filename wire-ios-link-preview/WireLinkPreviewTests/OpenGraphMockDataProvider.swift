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
@testable import WireLinkPreview

struct OpenGraphMockData {
    let head: String
    let expected: OpenGraphData?
    let urlString: String
    let urlVersion: String?
}

class OpenGraphMockDataProvider: NSObject {

    static func twitterData() -> OpenGraphMockData {

        let expected = OpenGraphData(
            title: "ericasadun on Twitter",
            type: "article",
            url: "https://twitter.com/ericasadun/status/743868311843151872",
            resolvedURL: "https://twitter.com/ericasadun/status/743868311843151872",
            imageUrls: ["https://pbs.twimg.com/profile_images/292927387/dogbert-e_400x400.png"],
            siteName: "Twitter",
            description: "“`lazy var` doesn't use dispatch_once/not thread-safe w/o synch'n. Only global&static properties init w/ dispatchonceish mechanism- @jckarter”"
        )

        return OpenGraphMockData(
            head: fixtureWithName("twitter_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    static func twitterDataWithImages() -> OpenGraphMockData {

        let expected = OpenGraphData(
            title: "Ayaka Nonaka on Twitter",
            type: "article",
            url: "https://twitter.com/ayanonagon/status/749726072623685632",
            resolvedURL: "https://twitter.com/ayanonagon/status/749726072623685632",
            imageUrls: ["https://pbs.twimg.com/media/CmeP2R6VIAAMx2N.jpg:large", "https://pbs.twimg.com/media/CmeP2R5UMAA_1fB.jpg:large", "https://pbs.twimg.com/media/CmeP2R6UIAAHT1t.jpg:large", "https://pbs.twimg.com/media/CmeP2T4UIAA5pNt.jpg:large"],
            siteName: "Twitter",
            description: "“Hello from Lake Tahoe. Happy weekend everyone! ✌🏼️💙❤️”",
            userGeneratedImage: true
        )

        return OpenGraphMockData(
            head: fixtureWithName("twitter_images_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    static func foursquareData() -> OpenGraphMockData {

        var expected = OpenGraphData(
            title: "NETA Mexican Street Food",
            type: "playfoursquare:venue",
            url: "https://foursquare.com/neta_msf",
            resolvedURL: "https://foursquare.com/neta_msf",
            imageUrls: ["https://irs0.4sqi.net/img/general/600x600/119241531_vEv_57iCz-SX9nKwMsd0GovpEA1gKtNAICRsah7GKjg.jpg", "https://irs3.4sqi.net/img/general/600x600/119241531__mAWGX94algkPbGcxKXYEqMAk4Vso70GkTWGdi-UTAA.jpg", "https://irs0.4sqi.net/img/general/600x600/119241531_b56QzEzT2AeqiFiAz5yzAvzMVkJv-TtuAchMcbuD5hk.jpg", "https://irs1.4sqi.net/img/general/600x600/119241531_aCFVIfqXAUOBJr1ixU8usw-sFxIBCz-zVNeSCcm4N74.jpg"],
            siteName: "Foursquare",
            description: "Burrito-Imbiss in Berlin, Berlin"
        )

        expected.foursquareMetaData = FoursquareMetaData(latitude: 52.53084856462712, longitude: 13.4021941476607)

        return OpenGraphMockData(
            head: fixtureWithName("foursquare_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    static func vergeData() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "The ultimate Apple I/O death chart",
            type: "article",
            url: "http://www.theverge.com/2016/6/29/12054410/apple-tech-death-chart-headphone-jack-ports-usb-c",
            resolvedURL: "http://www.theverge.com/2016/6/29/12054410/apple-tech-death-chart-headphone-jack-ports-usb-c",
            imageUrls: ["https://cdn0.vox-cdn.com/thumbor/eCXqqjnIBNh9YQxtkfu5EofTMO8=/0x134:1500x978/1600x900/cdn0.vox-cdn.com/uploads/chorus_image/image/49985217/imac_ports_large.0.jpg"],
            siteName: "The Verge",
            description: "The internet has been ablaze the past few weeks about Apple potentially removing the headphone jack from the next iPhone — a move that’s been heavily rumored for months, and has everything from..."
        )

        return OpenGraphMockData(
            head: fixtureWithName("verge_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: "20171116072016"
        )
    }

    static func youtubeData() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "Last Week Tonight with John Oliver: Brexit (HBO)",
            type: "video",
            url: "https://www.youtube.com/watch?v=iAgKHSNqxa8",
            resolvedURL: "https://www.youtube.com/watch?v=iAgKHSNqxa8",
            imageUrls: ["https://i.ytimg.com/vi/iAgKHSNqxa8/maxresdefault.jpg"],
            siteName: "YouTube",
            description: "Britain could soon vote to leave the European Union. John Oliver enlists a barbershop quartet to propose a smarter option. Connect with Last Week Tonight onl..."
        )

        return OpenGraphMockData(
            head: fixtureWithName("youtube_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    static func guardianData() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "What's it like to drive with Tesla's Autopilot and how does it work?",
            type: "article",
            url: "http://www.theguardian.com/technology/2016/jul/01/tesla-autopilot-model-s-crash-how-does-it-work",
            resolvedURL: "http://www.theguardian.com/technology/2016/jul/01/tesla-autopilot-model-s-crash-how-does-it-work",
            imageUrls: ["https://i.guim.co.uk/img/media/7a8eb8b3e9768f03fd56b1f38f3a4bbacc2f4521/0_115_3500_2102/3500.jpg?w=1200&h=630&q=55&auto=format&usm=12&fit=crop&bm=normal&ba=bottom%2Cleft&blend64=aHR0cHM6Ly91cGxvYWRzLmd1aW0uY28udWsvMjAxNi8wNS8yNS9vdmVybGF5LWxvZ28tMTIwMC05MF9vcHQucG5n&s=361fd974e61775119c65c52997274245"],
            siteName: "the Guardian",
            description: "Tesla’s Autopilot is in the spotlight after a fatal crash. Samuel Gibbs used it when he drove to France in a Model S – here’s how he found the experience of driver assistance"
        )

        return OpenGraphMockData(
            head: fixtureWithName("guardian_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: "20170918063647"
        )
    }

    static func crashingDataEmoji() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "Wall posts ",
            type: "website",
            url: "https://vk.com/wall-36047336_69534",
            resolvedURL: "",
            imageUrls: ["https://pp.userapi.com/c824202/v824202790/122846/GMTO8Rcm-wI.jpg"],
            siteName: nil,
            description: "📍 xxxxx"
        )

        return OpenGraphMockData(
            head: fixtureWithName("crash_emoji"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    static func instagramData() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "Instagram photo by Silvan Dähn • Aug 5, 2015 at 4:27pm UTC",
            type: "instapp:photo",
            url: "https://www.instagram.com/p/6AiRp5TOXB/",
            resolvedURL: "https://www.instagram.com/p/6AiRp5TOXB/",
            imageUrls: ["https://scontent-frt3-1.cdninstagram.com/t51.2885-15/s750x750/sh0.08/e35/11809632_1741377449423046_2075339609_n.jpg?ig_cache_key=MTA0NDk4NTg2MDM0NzE5Mjc2OQ%3D%3D.2"],
            siteName: "Instagram",
            description: "See this Instagram photo by @silvandaehn • 25 likes"
        )

        return OpenGraphMockData(
            head: fixtureWithName("instagram_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    static func vimeoData() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "Auto",
            type: "video",
            url: "https://vimeo.com/170888135",
            resolvedURL: "https://vimeo.com/170888135",
            imageUrls: ["https://i.vimeocdn.com/video/576126576_1280x720.jpg"],
            siteName: "Vimeo",
            description: "Cars dance on highways, crowds of people wash across sidewalk shores.   RISD Senior film - 2016"
        )

        return OpenGraphMockData(
            head: fixtureWithName("vimeo_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    static func nytimesData() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "Brazil’s Olympic Catastrophe",
            type: "article",
            url: "http://www.nytimes.com/2016/07/03/opinion/sunday/brazils-olympic-catastrophe.html",
            resolvedURL: "http://www.nytimes.com/2016/07/03/opinion/sunday/brazils-olympic-catastrophe.html",
            imageUrls: ["https://static01.nyt.com/images/2016/07/03/opinion/sunday/03barbara/03barbara-facebookJumbo.jpg"],
            description: "Can Rio pull off the Games with only weeks to go?"
        )

        return OpenGraphMockData(
            head: fixtureWithName("nytimes_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: "20180523034751"
        )
    }

    static func washingtonPostData() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "Holocaust Museum to visitors: Please stop catching Pokémon here",
            type: "article",
            url: "https://www.washingtonpost.com/news/the-switch/wp/2016/07/12/holocaust-museum-to-visitors-please-stop-catching-pokemon-here/",
            resolvedURL: "https://www.washingtonpost.com/news/the-switch/wp/2016/07/12/holocaust-museum-to-visitors-please-stop-catching-pokemon-here/",
            imageUrls: ["https://images.washingtonpost.com/?url=http://img.washingtonpost.com/blogs/the-switch/files/2016/07/DoduoHM.png&w=1484&op=resize&opt=1&filter=antialias"],
            siteName: "Washington Post",
            description: "Melding the real world with a digital one can sometimes lead to uncomfortable consequences."
        )

        return OpenGraphMockData(
            head: fixtureWithName("washington_post_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: "20180519102639"
        )
    }

    static func mediumData() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "The tune for this summer — audio filters — Wire News",
            type: "article",
            url: "https://medium.com/wire-news/the-tune-for-this-summer-audio-filters-eca8cb0b4c57",
            resolvedURL: "https://medium.com/wire-news/the-tune-for-this-summer-audio-filters-eca8cb0b4c57",
            imageUrls: ["https://cdn-images-1.medium.com/max/1200/1*-txfQwEIvfMETmDi_hdfpQ.png"],
            siteName: "Medium",
            description: "Hello again from the Wire news room. Even though it’s a hot summer out there, we have been busy making our app the most modern, private…"
        )

        return OpenGraphMockData(
            head: fixtureWithName("medium_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    static func wireData() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "Wire — modern, private communication. For iOS, Android, OS X, Windows and web.",
            type: "website",
            url: "https://wire.com/",
            resolvedURL: "https://wire.com/",
            imageUrls: ["https://lh3.ggpht.com/gbxDT30ZwpwYMCF7ilrSaIpRQP3Z1Xdx2WUcyW5x_e8FDN8kA4CJGQQ0fFpVhKiGnPkAIOEf7S1_9cNi684Be-OY=s1024"],
            description: "HD quality calls, private and group chats with inline photos, music and video. Secure and perfectly synced across your devices."
        )

        return OpenGraphMockData(
            head: fixtureWithName("wire_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    static func polygonData() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "Which Pokémon Go team should you join?",
            type: "website",
            url: "http://www.polygon.com/2016/7/11/12148448/which-pokemon-go-team-should-i-pick",
            resolvedURL: "http://www.polygon.com/2016/7/11/12148448/which-pokemon-go-team-should-i-pick",
            imageUrls: ["https://cdn1.vox-cdn.com/thumbor/VhM0gxcxqzqlpHJNQmqPuilpdXA=/0x1075:1440x1885/1600x900/cdn0.vox-cdn.com/uploads/chorus_image/image/50077599/Screenshot_20160709-102153.0.0.png"],
            siteName: "Polygon",
            description: "How to answer one of the game's toughest questions"
        )

        return OpenGraphMockData(
            head: fixtureWithName("polygon_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: "20171126020245"
        )
    }

    static func iTunesData() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "„Wolves of Winter“ aus „Ellipsis (Deluxe)“ von Biffy Clyro auf Apple Music",
            type: "website",
            url: "https://itunes.apple.com/de/album/ellipsis-deluxe/id1093554521",
            resolvedURL: "https://itunes.apple.com/de/album/ellipsis-deluxe/id1093554521",
            imageUrls: ["http://is2.mzstatic.com/image/thumb/Music49/v4/7b/29/cd/7b29cd44-0d47-963e-5ffe-89d67c6e7dc4/source/1200x630bf.jpg"],
            siteName: "iTunes",
            description: "Hör dir „Wolves of Winter“ vom Album „Ellipsis (Deluxe)“ an. Kaufe den Titel für 1,29 €. Kostenlos mit Apple Music-Abo."
        )

        return OpenGraphMockData(
            head: fixtureWithName("itunes_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    static func iTunesDataWithoutTitle() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "„Ellipsis (Deluxe)“ von Biffy Clyro auf Apple Music",
            type: "website",
            url: "https://itunes.apple.com/de/album/ellipsis-deluxe/id1093554521",
            resolvedURL: "https://itunes.apple.com/de/album/ellipsis-deluxe/id1093554521",
            imageUrls: ["http://is2.mzstatic.com/image/thumb/Music49/v4/7b/29/cd/7b29cd44-0d47-963e-5ffe-89d67c6e7dc4/source/1200x630bf.jpg"],
            siteName: "iTunes",
            description: "Hör dir „Wolves of Winter“ vom Album „Ellipsis (Deluxe)“ an. Kaufe den Titel für 1,29 €. Kostenlos mit Apple Music-Abo."
        )

        return OpenGraphMockData(
            head: fixtureWithName("itunes_without_title_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    static func yahooSports() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "Mario Gomez: Besiktas verlängert Leihe",
            type: "article",
            url: "https://de.sports.yahoo.com/news/mario-gomez-besiktas-verl%c3%a4ngert-leihe-115423346.html",
            resolvedURL: "https://de.sports.yahoo.com/news/mario-gomez-besiktas-verl%c3%a4ngert-leihe-115423346.html",
            imageUrls: ["https://s.yimg.com/bt/api/res/1.2/Hm3djeE3ivlN_WaKu7eOog--/YXBwaWQ9eW5ld3NfbGVnbztxPTc1O3c9NjAw/http://media.zenfs.com/de-DE/homerun/de.goal.com/629c73161149247ba39c58e4d8a951a4.cf.png"],
            siteName: "Yahoo Sport",
            description: "Der deutsche Stürmer spielt offenbar auch in der kommenden Saison in Istanbul. Die Türken leihen ihn demnach erneut aus. Ein wichtiges Argument sei die Champions League."
        )

        return OpenGraphMockData(
            head: fixtureWithName("yahoo_sports_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    static func soundCloudTrack() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "Bridgit Mendler - Atlantis feat. Kaiydo",
            type: "music.song",
            url: "https://soundcloud.com/bridgitmendler/bridgit-mendler-atlantis-feat-kaiydo",
            resolvedURL: "https://soundcloud.com/bridgitmendler/bridgit-mendler-atlantis-feat-kaiydo",
            imageUrls: ["https://i1.sndcdn.com/artworks-000178472656-9nxuid-t500x500.jpg"],
            siteName: "SoundCloud",
            description: "\"Atlantis\" by Bridgit Mendler feat. @Kaiydo The official music video for \"Atlantis\" is out now! Watch here: http://smarturl.it/AtlantisMusicVideo"
        )

        return OpenGraphMockData(
            head: fixtureWithName("soundcloud_track_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    static func soundCloudPlaylist() -> OpenGraphMockData {
        let expected = OpenGraphData(
            title: "Artists To Watch 2019",
            type: "music.playlist",
            url: "https://soundcloud.com/playback/sets/2019-artists-to-watch",
            resolvedURL: "https://soundcloud.com/playback/sets/2019-artists-to-watch",
            imageUrls: ["https://i1.sndcdn.com/artworks-000454250598-idv5gc-t500x500.jpg"],
            siteName: "SoundCloud",
            description: "Listen to Artists To Watch 2019 by Playback #np on #SoundCloud"
        )

        return OpenGraphMockData(
            head: fixtureWithName("soundcloud_playlist_head"),
            expected: expected,
            urlString: expected.url,
            urlVersion: nil
        )
    }

    // MARK: - Helper

    private static func fixtureWithName(_ name: String) -> String {
        let bundle = Bundle(for: OpenGraphMockDataProvider.self)
        let url = bundle.url(forResource: name, withExtension: "txt")!
        return try! String(contentsOf: url)
    }

}
