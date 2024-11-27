# Maculate

Maculate offers a Swift—native frontend for Qalculate, the ultimate desktop calculator. In observance of Qalculate's GPL license, Maculate is licensed freely under the GPLv2.

![SCR-20241126-rxsp](https://github.com/user-attachments/assets/e3e6bf65-f430-43dd-b890-8a762ba04e93)

<a href="https://toastcat.club/maculate/">![Mac App Store Badge](https://github.com/user-attachments/assets/4fd17854-b560-4e9e-803d-a5193e1a9a71)</a>

It supports just about anything you could imagine, including hundreds of units and dozens of constants, unit conversions, solving for unknown values, factorizing equations, calculus: differentiate and integrate, calculate in different base systems, calculate with time, account for uncertainty, economics, matrices and vectors, combinatorics, complex Numbers, variable assignment, and much much more

For a full list of features, refer to the Qalculate documentation. Please note that Maculate does not currently support the following features: plotting, loading & exporting datasets, real time currency conversion

Due to the reoccuring expenses associated with Apple development, Maculate builds will be made available on the App Store, for \$7.99. The current intent is to distribute 50\% of the proceeds to various open source projects, after \$600 in yearly expenses are covered.

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

## Support Matrix

|                         | macOS | iOS | iPadOS | Notes                   |
| ----------------------- | ----- | --- | ------ | ----------------------- |
| macOS 15 <br/> iOS 18   | ✅    | ⏱️  | ⏱️     |                         |
| macOS 14 <br/> iOS 17   | ⚠️    | ⏱️  | ⏱️     | No Plots, No Completion |
| macOS <14 <br/> iOS <17 | ❌    | ❌  | ❌     | Never Supported         |
