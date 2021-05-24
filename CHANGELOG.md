# CHANGELOG

## 20210520 - Zhang

- `AppDelegaate.swift` modified 
    - Use `ProductCommunicationService` directly from class.
- `Service/MCCommunicationService.swift` added.
    - Manage 2 TCPClient: `controlClient` and `streamClient`.
    - Setup handlers of TCPClient.
    - Some methods available to control
        - `connect`, `disconnect`
        - `toggleStreaming`
        - `startRec`, `stopRec`
        - `switchStreamingCamera`
- `Utilities/Preferences.swift` modified.
- `Utilities/TCPClient.swift` modified.
    - The type of Member `port` is changed from `UInt32` to `UInt16`.
    - Add multiple `send` methods to send raw data, a `UInt32` code or a `String` message.
- `ViewController/MainLayoutViewController.swift` modified.
    - Add a `UIImageView` to display streaming images.
    - Wrap  `UIImageView` and `FPVWidget` with widgets in order to toggle display.
    - Add a `MapWidget`.
    - Delegate to `MCStreamer` to receive streaming images.
    - Tapping the streaming window can exchange it with the main view.
- `ViewController/RootViewController.swift` modified.
    - Add a connect/disconnect button to mini-computer.
    - Add text fields to edit the IP address and the port of the mini-computer.
- `Widgets/FPVWidgets.swift` modified.
    -  Add a class `MCCameraFeedWidget` to switch between multiple cameras in the mini-computer.

## 20210318 - Zhang

- Re-initialize the whole application with `DJI-UXSDK-iOS-Beta`.

## 20210113 - Zhang

- Add this `CHANGELOG.md`
- The app now can connect to the server, record the images and display the streaming.
- Problems may occur if buttons are clicked in a wrong way.
