# Maculate

Maculate offers a Swift—native frontend for Qalculate, the ultimate desktop calculator. In observance of Qalculate's GPL license, Maculate is licensed freely under the GPLv2.

![](https://github.com/user-attachments/assets/e3e6bf65-f430-43dd-b890-8a762ba04e93)

<a href="https://apps.apple.com/us/app/maculate/id6738711535">![Mac App Store Badge](https://github.com/user-attachments/assets/4fd17854-b560-4e9e-803d-a5193e1a9a71)</a>

It supports just about anything you could imagine, including hundreds of units and dozens of constants, unit conversions, solving for unknown values, factorizing equations, calculus: differentiate and integrate, calculate in different base systems, calculate with time, account for uncertainty, economics, matrices and vectors, combinatorics, complex numbers, variable assignment, and much much more

For a full list of features, refer to the Qalculate documentation. Please note that Maculate does not currently support the following features: plotting, loading & exporting datasets, real time currency conversion

Due to the reoccuring expenses associated with Apple development, Maculate builds will be made available on the App Store, for \$6.99. The current intent is to distribute 50\% of the proceeds to various open source projects, after \$600 in yearly expenses are covered.

## Building

> [!NOTE]
> Ensure XCode is closed before running `./build.sh`. Otherwise, XCode will detect the `rm` commands and break configuration.

Maculate is divided into two parts: the Swift frontend, and the C++ backend. The backend is built using CMake, and the frontend is built using Xcode. The backend is built as a static library, and the frontend links against it.

Due to the fact the backend was intended to be built on Linux, the backend is built using nix, which creates a reproducible build environment.

After nix has been installed, run `./build.sh` inside the libqalc directory. The build script is genuinely disgusting, and one thing you'll need to do is make it not reference Toastcat LLC. After doing that, the frameworks must be enabled in Xcode, and the project should build.

Under certain circumstances, we may not be able to provide assistance in building the project within XCode.

## Open Source Status

Maculate is open source, but the source code is not under any sort of warranty. Contributions are generally welcome, though be aware that you will not be compensated for them.

We generally regard the codebase as being well-written and documented, so it could serve as a good basis to libqalculate.

### DRM

The currency conversion feature makes calls to a server hosted at `maculate.toastcat.club`. This server is developed within this repository. It currently acts as a simple anonymizing proxy. These requests include [Reciepts](https://developer.apple.com/documentation/appstorereceipts/validating_receipts_on_the_device) signed by Apple, which are used to verify the purchase of the app. Hence, the currency conversion feature is not available in the open source version of Maculate out of the box, but you can host your own server with relative ease.

Please note that the server is licensed under the AGPLv3, wheras the rest of the project is licensed under the GPLv2.

## Support Matrix

|                         | macOS | iOS  | iPadOS | Notes                                |
| ----------------------- | ----- | ---- | ------ | ------------------------------------ |
| macOS 15 <br/> iOS 18   | ✅    | ✅ | ⏱️⚠️   |                 |
| macOS 14 <br/> iOS 17   | ⚠️    | ⚠️ | ⏱️⚠️   | No plots, completion on macOS, and currencies |
| macOS <14 <br/> iOS <17 | ❌    | ❌   | ❌     | Never Supported                      |
