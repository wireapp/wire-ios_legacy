# Wire™
[![Wire logo](https://github.com/wireapp/wire/blob/master/assets/header-small.png?raw=true)](https://wire.com/jobs/)

[![Build Status](https://dev.azure.com/wireswiss/Wire%20iOS/_apis/build/status/Frameworks/wire-ios-link-preview)](https://dev.azure.com/wireswiss/Wire%20iOS/_build/latest?definitionId=17) [![codecov](https://codecov.io/gh/wireapp/wire-ios-link-preview/branch/develop/graph/badge.svg)](https://codecov.io/gh/wireapp/wire-ios-link-preview)


This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code at [github.com/wireapp/wire](https://github.com/wireapp/wire).

For licensing information, see the attached LICENSE file and the list of third-party licenses at [wire.com/legal/licenses/](https://wire.com/legal/licenses/).

# WireLinkPreview

This framework is part of Wire iOS. Additional documentation is available in the [Wire iOS wiki](https://github.com/wireapp/wire-ios/wiki).

WireLinkPreview is a Swift framework that can be used to fetch and parse Open Graph data that is present on most webpages (see http://ogp.me/ for more information and https://developers.facebook.com/tools/debug/sharing to debug open graph data).

### How to build

This framework is using Carthage to manage its dependencies. To pull the dependencies binaries, `run carthage bootstrap --platform ios`.

You can now open the Xcode project and build.

### Usage:

Consumers of this framework should mostly interact with the `LinkPreviewDetector` type, it can be used to check if a given text contains a link using the `containsLink:inText` method and if it does it can be used to download the previews asynchronously using `downloadLinkPreviews:inText:completion`.

```swift
let text = "Text containing a link to your awesome tweet"
let detector = LinkPreviewDetector(resultsQueue: .main)

guard detector.containsLink(inText: text) else { return }
detector.downloadLinkPreviews(inText: text) { previews in
    // Do something with the previews
}
```

A call to this method will also download the images specified in the Open Graph data. The completion returns an array of `LinkPreview` objects which currently are either of type `ArticleMetadata` or `TwitterStatusMetadata`, while the count of elements in the array is also limited to one at for now. Note, use the delegate `LinkPreviewDetectorDelegate` to control which which detected links will have their preview generated.
