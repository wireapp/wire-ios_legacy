# Wire™
[![Wire logo](https://github.com/wireapp/wire/blob/master/assets/header-small.png?raw=true)](https://wire.com/jobs/)

[![Azure Pipelines Build Status](https://dev.azure.com/wireswiss/Wire%20iOS/_apis/build/status/Frameworks/wire-ios-cryptobox?branchName=develop)](https://dev.azure.com/wireswiss/Wire%20iOS/_build/latest?definitionId=24&branchName=develop) [![codecov](https://codecov.io/gh/wireapp/wire-ios-cryptobox/branch/develop/graph/badge.svg)](https://codecov.io/gh/wireapp/wire-ios-cryptobox)

This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code at [github.com/wireapp/wire](https://github.com/wireapp/wire).

For licensing information, see the attached LICENSE file and the list of third-party licenses at [wire.com/legal/licenses/](https://wire.com/legal/licenses/).

# wire-ios-cryptobox

This framework is part of Wire iOS. Additional documentation is available in the [Wire iOS wiki](https://github.com/wireapp/wire-ios/wiki).

This project provides for cross-compilation of [cryptobox](https://github.com/wireapp/cryptobox) for iOS, currently only in the form of static libraries.

## Integrating Objective-C Wrapper
You can integrate Objective-C Wrapper (Cryptobox.framework) using Carthage.
When Carthage will build it first time it will also build `libcryptobox.a` and `libsodium.a` in `Carthage/Checkouts/cryptobox-ios/build` with `libs` and `include` subfolders. So you can just add these paths to Libraries Search Paths and Headers Search Paths of your project.
