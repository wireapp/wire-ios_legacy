# Wire™

[![Wire logo](https://github.com/wireapp/wire/blob/master/assets/header-small.png?raw=true)](https://wire.com/jobs/)

[![Azure Pipelines Build Status](https://dev.azure.com/wireswiss/Wire%20iOS/_apis/build/status/Frameworks/wire-ios-protos?branchName=develop)](https://dev.azure.com/wireswiss/Wire%20iOS/_build/latest?definitionId=29&branchName=develop) [![codecov](https://codecov.io/gh/wireapp/wire-ios-protos/branch/develop/graph/badge.svg)](https://codecov.io/gh/wireapp/wire-ios-protos)

This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code at [github.com/wireapp/wire](https://github.com/wireapp/wire).

For licensing information, see the attached LICENSE file and the list of third-party licenses at [wire.com/legal/licenses/](https://wire.com/legal/licenses/).

# wire-ios-protos

This framework is part of Wire iOS SyncEngine. Additional documentation is available in the [Wire iOS wiki](https://github.com/wireapp/wire-ios/wiki).

The wire-ios-protos framework contains precompiled protocol buffer definitions for Swift.

## How to build

This framework is using Carthage to manage its dependencies. To pull the dependencies binaries, `run carthage bootstrap --platform ios`.

You need the Swift Protocol Buffer compiler  to build the protobuf Swift files. Run `brew install swift-protobuf` to install it.

Run `bash Scripts/compile-protos.sh` to generate the files from the protobuf definitions imported from Carthage.

You can now open the Xcode project and build.
