# Wire™
[![Wire logo](https://github.com/wireapp/wire/blob/master/assets/header-small.png?raw=true)](https://wire.com/jobs/)

[![Azure Pipelines Build Status](https://dev.azure.com/wireswiss/Wire%20iOS/_apis/build/status/Frameworks/wire-ios-testing?branchName=develop)](https://dev.azure.com/wireswiss/Wire%20iOS/_build/latest?definitionId=22&branchName=develop) [![codecov](https://codecov.io/gh/wireapp/wire-ios-testing/branch/develop/graph/badge.svg)](https://codecov.io/gh/wireapp/wire-ios-testing)


This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code at [github.com/wireapp/wire](https://github.com/wireapp/wire).

For licensing information, see the attached LICENSE file and the list of third-party licenses at [wire.com/legal/licenses/](https://wire.com/legal/licenses/).

# wire-ios-testing

This framework is part of Wire iOS SyncEngine. Visit [iOS SyncEngine repository](http://github.com/wireapp/zmessaging-cocoa) for an overview of the architecture.

The wire-ios-testing framwork compiles some utilities to help with unit / integration tests.


### How to build

This framework is using Carthage to manage its dependencies. To pull the dependencies binaries, `run carthage bootstrap --platform ios`.

You can now open the Xcode project and build.
