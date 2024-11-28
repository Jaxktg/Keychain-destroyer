# Keychain-destroyer
This is a simple iOS tweak developed using Theos-jailed that provides a floating button to delete all keychain items in an app. It demonstrates hooking into a UIViewController’s lifecycle to display the button and interact with keychain data.

## Features
+ Adds a draggable, floating button to the app’s main view.
+ Deletes all keychain items when the button is tapped.

## Installation and Building
1.	Clone or download this repository.
2.	Ensure you have Theos-jailed set up on your system. Follow the guide here.
3.	Modify the tweak’s Makefile if necessary to match your project setup.
4.	Build the tweak using Theos:
```bash
CODESIGN_IPA=0 make package
```

## Code Overview
+ **KeychainDeletionButton**: A custom UIButton subclass that handles:
  + Displaying and styling the floating button.
  + Deleting keychain items via SecItemDelete.
  + Providing draggable functionality using UIPanGestureRecognizer.
+ **UIViewController Hook**: Hooks into viewDidAppear to add the floating button to the main app’s root view.

## Disclaimer
Use this tweak responsibly. Deleting keychain items can remove sensitive user data, such as saved passwords and tokens, potentially causing apps to malfunction.

## Credits
Vegard on stackoverflow https://stackoverflow.com/questions/7142774/how-do-you-reset-an-iphone-apps-keychain/16136513#16136513 

---
For detailed steps on building jailed tweaks using Theos, refer to the official [Theos-jailed Wiki](https://github.com/kabiroberai/theos-jailed/wiki).
