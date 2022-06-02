# Wire™

[![Wire logo](https://github.com/wireapp/wire/blob/master/assets/header-small.png?raw=true)](https://wire.com/jobs/)


[![Azure Pipelines Build Status](https://dev.azure.com/wireswiss/Wire%20iOS/_apis/build/status/Frameworks/wire-ios-sync-engine?branchName=develop)](https://dev.azure.com/wireswiss/Wire%20iOS/_build/latest?definitionId=31&branchName=develop) [![codecov](https://codecov.io/gh/wireapp/wire-ios-sync-engine/branch/develop/graph/badge.svg)](https://codecov.io/gh/wireapp/wire-ios-sync-engine)

This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code at [github.com/wireapp/wire](https://github.com/wireapp/wire).

# Wire iOS Sync Engine

The wire-ios-sync-engine framework is used as part of the [Wire iOS client](http://github.com/wireapp/wire-ios) and is the top-most layer of the underlying *sync engine*. It is using a number of lower-level frameworks. 

The Wire iOS sync engine is developed in a mix of Objective-C and Swift (and just a handful of classes in Objective-C++). It is a result of a long development process that was started in Objective-C when Swift was not yet available. In the past years, parts of it have been written or rewritten in Swift. Going forward, expect new functionalities to be developed almost exclusively in Swift.

## Documentation
Additional documentation is available in the [Wire iOS wiki](https://github.com/wireapp/wire-ios/wiki).

# How to build

*iOS SyncEngine* is build with Xcode 13.1 using Swift 5.

It is using [Carthage](https://github.com/Carthage/Carthage) to manage dependencies. To pull the dependencies binaries run `carthage bootstrap --platform ios --use-xcframeworks`.

You can now open the Xcode project and build.
