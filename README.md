# Maculate

Maculate offers a Swift—native frontend for Qalculate, the ultimate desktop calculator. In observance of Qalculate's GPL license, Maculate is licensed freely under the GPLv2.

Due to the reoccuring expenses associated with Apple development, Maculate builds will be made available on the App Store, for \$7.99. The current intent is to distribute 50\% of the proceeds to various open source projects, after \$600 in yearly expenses are covered.

## Building

Maculate is divided into two parts: the Swift frontend, and the C++ backend. The backend is built using CMake, and the frontend is built using Xcode. The backend is built as a static library, and the frontend links against it.

Due to the fact the backend was intended to be built on Linux, the backend is built using nix, which creates a reproducible build environment.

After nix has been installed, run `./build.sh` inside the libqalc directory.
