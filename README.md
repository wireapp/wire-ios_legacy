# Wire™

![Wire logo](https://github.com/wireapp/wire/blob/master/assets/logo.png?raw=true)

This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code and the terms of use at [github.com/wireapp/wire](https://github.com/wireapp/wire). 

For licensing information, see the attached LICENSE file and the list of third-party licenses at [wire.com/legal/licenses/](https://wire.com/legal/licenses/).

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

