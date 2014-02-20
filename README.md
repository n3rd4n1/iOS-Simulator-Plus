iOS Simulator Plus
==================

A background utility that aims to simplify and improve interaction with the iOS Simulator through the trackpad.

Hardware Interaction
--------------------

Trackpad gestures to trigger Hardware menu items.

| Menu option    | Trackpad gesture                |
| -------------- | :-----------------------------: |
| Rotate left    | Left rotate                     |
| Rotate right   | Right rotate                    |
| Shake gesture  | Back-and-forth rotate or pinch  |
| Home           | Pinch in                        |
| Lock           | Pinch out                       |

User Gestures
-------------

Trackpad gestures to simplify interaction with the iOS Simulator screen (touchscreen). This does not interfere with the original way iOS Simulator is operated; this merely augments it. All gestures are simulated using a single touch, combined with modifier keys.

+ Hold the `shift` key before touching the trackpad to make the trackpad behave like a real touchscreen, i.e. the trackpad area is scaled to the iOS Simulator screen, and touch is tracked and translated.
+ Position the mouse cursor as desired. Hold the `control` key before touching the trackpad to easily simulate pinch and rotate gestures. The pivot point will be the mouse cursor location.
+ Hold the `control` and `shift` keys before touching the trackpad to simulate a two-finger drag gesture. The trackpad area is scaled to the iOS Simulator screen, and touch is tracked and translated.

Limitation
----------

Because simulating the pinch, rotate, and two-finger drag gestures is normally a two-step process (i.e. holding the `option` and `shift` keys initiates these gestures centered at the iOS Simulator's screen, then moving the center at the desired location), and because the iOS Simulator Plus does these steps automatically, when the iOS Simulator's screen is not maximized and scroll bars are not centered, the translation that iOS Simulator Plus applies will be incorrect. Therefore, when simulating pinch, rotate, and two-finger drag gestures, iOS Simulator Plus is recommended only if the iOS Simulator window is maximized.

Usage
-----

Simply execute `iOS Simulator Plus.app`. Once running, a status item (shown as a phone with a plus sign) for iOS Simulator Plus will become available in the status bar. Selecting `Activate iOS Simulator...` will activate the iOS Simulator -- for convenience. iOS Simulator Plus is only really active when iOS Simulator is active, that is to say that functionalities of iOS Simulator Plus is only enabled once iOS Simulator becomes active.

Download
--------

[iOS-Simulator-Plus-1.0.zip](http://n3rd4n1.github.io/bin/iOS-Simulator-Plus-1.0.zip)


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/n3rd4n1/ios-simulator-plus/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

