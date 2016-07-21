# Wire™

![Wire logo](https://github.com/wireapp/wire/blob/master/assets/logo.png?raw=true)

This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code and the terms of use at [github.com/wireapp/wire](https://github.com/wireapp/wire). 

For licensing information, see the attached LICENSE file and the list of third-party licenses at [wire.com/legal/licenses/](https://wire.com/legal/licenses/).

If you compile the open source software that we make available from time to time to develop your own mobile, desktop or web application, and cause that application to connect to our servers for any purposes, we refer to that resulting application as an “Open Source App”.  All Open Source Apps are subject to, and may only be used and/or commercialized in accordance with, the Terms of Use applicable to the Wire Application, which can be found at https://wire.com/legal/#terms.  Additionally, if you choose to build an Open Source App, certain restrictions apply, as follows:

a. You agree not to change the way the Open Source App connects and interacts with our servers; b. You agree not to weaken any of the security features of the Open Source App; c. You agree not to use our servers to store data for purposes other than the intended and original functionality of the Open Source App; d. You acknowledge that you are solely responsible for any and all updates to your Open Source App. 

For clarity, if you compile the open source software that we make available from time to time to develop your own mobile, desktop or web application, and do not cause that application to connect to our servers for any purposes, then that application will not be deemed an Open Source App and the foregoing will not apply to that application.

No license is granted to the Wire trademark and its associated logos, all of which will continue to be owned exclusively by Wire Swiss GmbH. Any use of the Wire trademark and/or its associated logos is expressly prohibited without the express prior written consent of Wire Swiss GmbH.

# How to build the open source client

## What is included in the open source client

The project in this repository contains the Wire iOS client project. You can build the project yourself. However, there are some differences with the binary Wire iOS client available on the App Store. 
These differences are:
- the open source project does not include the API keys of Vimeo, Localytics, HockeyApp and other 3rd party services.
- the open source project links agains the open source Wire audio-video-signaling (AVS) library. The binary App Store client links against an AVS version that contains proprietary improvements for the call quality.

## Prerequisites
In order to build Wire for iOS locally, it is necessary to install the following tools on the local machine:
- OS X 10.11 or newer
- Xcode 7.3.1 (https://itunes.apple.com/en/app/xcode/id497799835?mt=12)
- Bundler (http://bundler.io)
- Carthage 0.17.2 or newer (https://github.com/Carthage/Carthage)
- CocoaPods 1.0.0 or newer (https://cocoapods.org/)
- Ruby (gem) (should be already available on OS X and not need any additional installation)

The setup script will automatically check for you that you satisfy these requirements

## How to build locally
1. Check out the wire-ios repository. 
2. From the checkout folder, run `./setup.sh`. This will pull in all the necessary dependencies with Carthage and CocoaPods and verify that you have the right version of the tools installed.
3. Open the workspace `Wire-iOS.xcworkspace` in Xcode
4. Click the "Run" button in Xcode

These steps allow you to build only the Wire umbrella project, pulling in all other Wire frameworks with Carthage. If you want to modify the source/debug other Wire frameworks, you can open the `Carthage/Checkouts` subfolder and open the individual projects for each dependency there.

You can then use `carthage build --platform ios` to rebuild the dependency and use it in the umbrella project.

