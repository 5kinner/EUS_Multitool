# EUS_Multitool
A tool using swiftdialog at it's core to enable End User Services technicians to perform daily tasks without the need to login to Jamf

Important Considerations: This solution has been developed to address a specific requirement within our environment, utilising the awesome tools and scripts provided by the macamdin community. We kindly request you to thoroughly examine the code and tailor it to suit your unique environment. It is worth mentioning that the code is currently undergoing active development and refinement. Your constructive feedback and courtesy are greatly appreciated.

The tool prompts for credentials that can be saved. If 'Save' is selected the credentials are saved locally in the following places:
  Username in ~/Library/Application Support/multitool
  Password in Keychain 'Multitool'

![Initial_Prompt](https://github.com/5kinner/EUS_Multitool/assets/33225587/2de70aad-5a0d-41ad-b9da-1aaea95baf1f)

After being authorised the tool allows for input of a Jamf managed serial. If an incorrect serial is entered an error message appears and you have the option to try again.

![Tool](https://github.com/5kinner/EUS_Multitool/assets/33225587/f6cfcff3-d14f-4722-ac15-42ae5ec86f41)

![Error](https://github.com/5kinner/EUS_Multitool/assets/33225587/6051c477-c67a-40b1-860d-0c9e5e004a3d)

Currently the options available are;

View LAPS password (from macOSLaps extension Attribute)
View PRK
Change LAPS password
Change PRK
  
The changing of LAPS/PRK really only adds the machine to a static group scoped to run once Jamf policy. I'd like to develeop this to flush and remove form the group once the policy has ran.
