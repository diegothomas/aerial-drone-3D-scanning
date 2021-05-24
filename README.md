# aerial-drone-3D-scanning
This project is about 3D scanning of outdoor scenes with an aerial drone

## Quick Start

### Prerequisites

- Xcode (Install from AppStore)

    After Xcode is installed, remember to run

    ```bash
    $ xcode-select --install
    ```

    to install command line tools.

- ruby

    Install [Homebrew](https://brew.sh/).
    
    After Homebrew is installed, run the following to install ruby

    ```bash
    $ brew install ruby
    ```

- cocoapods

    After ruby is installed, run the following to install cocoapods

    ```bash
    $ sudo gem install cocoapods
    ```

### Build and Run

First, `cd` to the the root directory and execute

```bash
$ pod install
```

If everything goes right, the dependencies will be successfully installed and a directory `pods` will show up.

Then, open `DJISDKSwiftDemo.xcworkspace` with Xcode, build and run the project.

## FAQ

1. Error when trying to run the project with simulators.

    Navigate to `Build Settings` of `DJISDKSwiftDemo`, change the value of `VALID_ARCHS` to `x86_64` in `User-Defined` at the bottom.
