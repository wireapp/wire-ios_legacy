# Wire™

[![Wire logo](https://github.com/wireapp/wire/blob/master/assets/header-small.png?raw=true)](https://wire.com/jobs/)

[![Build Status](https://dev.azure.com/wireswiss/Wire%20iOS/_apis/build/status/wire-ios)](https://dev.azure.com/wireswiss/Wire%20iOS/_build/latest?definitionId=32)

This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code at [github.com/wireapp/wire](https://github.com/wireapp/wire).

For licensing information, see the attached LICENSE file and the list of third-party licenses at [wire.com/legal/licenses/](https://wire.com/legal/licenses/).

If you compile the open source software that we make available from time to time to develop your own mobile, desktop or web application, and cause that application to connect to our servers for any purposes, we refer to that resulting application as an “Open Source App”.  All Open Source Apps are subject to, and may only be used and/or commercialized in accordance with, the Terms of Use applicable to the Wire Application, which can be found at https://wire.com/legal/#terms.  Additionally, if you choose to build an Open Source App, certain restrictions apply, as follows:

a. You agree not to change the way the Open Source App connects and interacts with our servers; b. You agree not to weaken any of the security features of the Open Source App; c. You agree not to use our servers to store data for purposes other than the intended and original functionality of the Open Source App; d. You acknowledge that you are solely responsible for any and all updates to your Open Source App.

For clarity, if you compile the open source software that we make available from time to time to develop your own mobile, desktop or web application, and do not cause that application to connect to our servers for any purposes, then that application will not be deemed an Open Source App and the foregoing will not apply to that application.

No license is granted to the Wire trademark and its associated logos, all of which will continue to be owned exclusively by Wire Swiss GmbH. Any use of the Wire trademark and/or its associated logos is expressly prohibited without the express prior written consent of Wire Swiss GmbH.


# Wire iOS

The Wire mobile app has an architectural layer that we call *sync engine*. It is the client-side layer that processes all the data that is displayed in the mobile app. It handles network communication and authentication with the backend, push notifications, local caching of data, client-side business logic, signaling with the audio-video libraries, encryption and decryption (using encryption libraries from a lower level) and other bits and pieces.

The user interface layer of the mobile app is built on top of the *sync engine*, which provides the data to display to the UI.
The sync engine itself is built on top of a few third-party frameworks, and uses Wire components that are shared between platforms for cryptography (Proteus/Cryptobox) and audio-video signaling (AVS).

![Mobile app architecture](https://github.com/wireapp/wire/blob/master/assets/mobile-architecture.png?raw=true)

### Documentation
Additional documentation is available in the [Wire iOS wiki](https://github.com/wireapp/wire-ios/wiki).

## How to build the open source client

### What is included in the open source client

The project in this repository contains the Wire iOS client project. You can build the project yourself. However, there are some differences with the binary Wire iOS client available on the App Store.
These differences are:
- the open source project does not include the API keys of Vimeo, Localytics, HockeyApp and other 3rd party services.
- the open source project links against the open source Wire audio-video-signaling (AVS) library. The binary App Store client links against an AVS version that contains proprietary improvements for the call quality.

### Prerequisites
In order to build Wire for iOS locally, it is necessary to install the following tools on the local machine:

- OS X 11.4 or newer
- Xcode 12.4 (https://itunes.apple.com/en/app/xcode/id497799835?mt=12).
- Carthage 0.38.0 or newer (https://github.com/Carthage/Carthage)

The setup script will automatically check for you that you satisfy these requirements

### How to build locally
1. Check out the wire-ios repository.
2. From the checkout folder, run `./setup.sh`. This will pull in all the necessary dependencies with Carthage and verify that you have the right version of the tools installed.
3. Open the project `Wire-iOS.xcodeproj` in Xcode
4. Click the "Run" button in Xcode

These steps allow you to build only the Wire umbrella project, pulling in all other Wire frameworks with Carthage. If you want to modify the source/debug other Wire frameworks, you can open the `Carthage/Checkouts` subfolder and open the individual projects for each dependency there.

You can then use `carthage bootstrap --platform ios --use-xcframeworks` to rebuild the dependency and use it in the umbrella project.

### Known limitations

Notifications send through Apple Push Notification service can only be received by the App Store Wire client, which is code signed with Wire's own certificate. This is a security feature enforced by Apple, as documented in Apple's [Local and Remote Notification Programming Guide](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/). Any client build from source will not be able to receive notifications.

### Translations

All Wire translations are crowdsourced via CrowdIn: https://crowdin.com/projects/wire
