# EUS_Multitool
A tool using swiftdialog at it's core to enable End User Services technicians to perform daily tasks without the need to login to Jamf

Important Considerations: This solution has been developed to address a specific requirement within our environment, utilising the awesome tools and scripts provided by the macamdin community. We kindly request you to thoroughly examine the code and tailor it to suit your unique environment. It is worth mentioning that the code is currently undergoing active development and refinement. Your constructive feedback and courtesy are greatly appreciated.

The tool prompts for credentials that can be saved. If 'Save Credentials' is selected the credentials are saved locally in the following places:

  * Username in ~/Library/Application Support/multitool
  * Password in Keychain 'Multitool'

![Initial_Prompt](https://github.com/5kinner/EUS_Multitool/assets/33225587/d517b227-728c-40b1-a592-659efe7356cc)


After being authorised the tool allows for input of a Jamf managed serial. If an incorrect serial is entered an error message appears and you have the option to try again.

![Tool](https://github.com/5kinner/EUS_Multitool/assets/33225587/c5494f62-eff8-46ed-9f8c-2d418cc651fd)

Incorrect serial entered message

![Error](https://github.com/5kinner/EUS_Multitool/assets/33225587/454bd74f-f0c4-48d6-bdb6-2eb21156b6c1)

Currently the options available are:

  * View LAPS password (from macOSLaps extension Attribute).
  * View PRK.
  * Change LAPS password.
  * Change PRK.

![Options](https://github.com/5kinner/EUS_Multitool/assets/33225587/f83a77d1-3fa4-47cb-a5d4-c611e51a76b6)

The changing of LAPS/PRK really only adds the machine to a static group scoped to run once Jamf policy. I'd like to develeop this to flush and remove from the group once the policy has ran.
