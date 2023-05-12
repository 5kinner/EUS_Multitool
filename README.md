# EUS_Multitool
A tool using swiftdialog at it's core to enable End User Services technicians to perform daily tasks without the need to login to Jamf

Caveats - This has been created for a specific need in our environment using tools/scripts the awesome macamdin community has created. Please review the code and adjust for your environment. I'm still actively developing (and correcting) this code. Please be nice ;-)

The tool prompts for credentials that can be saved. If 'Save' is selected the credentials are saved locally.
  Username in ~/Library/Application Support/multitool
  Password in Keychain 'Multitool'

![Initial_Prompt](https://github.com/5kinner/EUS_Multitool/assets/33225587/f2430ff8-7475-4114-a113-c99014cb5189)

After authorised the tool allows for input of a Jamf managed serial. If an incorrect Serial is entered an error message appears and you have the option to try again.

![Tool](https://github.com/5kinner/EUS_Multitool/assets/33225587/f6cfcff3-d14f-4722-ac15-42ae5ec86f41)

![Error](https://github.com/5kinner/EUS_Multitool/assets/33225587/6051c477-c67a-40b1-860d-0c9e5e004a3d)

Currently the options available are;

  View LAPS password (from macOSLaps extension Attribute)
  View PRK
  Change LAPS password
  Change PRK
  
 The changing of LAPS/PRK really only adds the machine to a static group scoped to run once Jamf policy. I'd like to develeop this to flush and remove form the group once the policy has ran.
