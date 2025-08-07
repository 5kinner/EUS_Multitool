# EUS Multitool ⚒️

## Overview

EUS Multitool is a Bash-based utility designed to assist IT technicians in managing Apple devices through Jamf Pro without directly interacting with the Jamf console. It leverages SwiftDialog for user interaction and Jamf Pro's API for device management tasks.

## Features

- **Serial Number Lookup**: Prompt users to input a serial number and select device type (Computer or Mobile Device).
- **ABM Check**: Verify if a device is present in Apple Business Manager. (currently via ADE in Jamf, ABM API to coming soon)
- **Prestage Assignment Check**: Identify the prestage configuration assigned to a device.
- **LAPS Management**:
  - View current LAPS password and expiration.
  - Schedule a LAPS password change.
- **Personal Recovery Key (PRK) Management**:
  - View the current PRK.
  - Schedule a PRK change.
- **Remote Desktop**: Enable Remote Desktop on a specified computer.
- **Mobile Device Management**:
  - Assign device to a user.
  - Update inventory.
  - Clear passcode.
  - Restart device.

<img width="932" height="520" alt="EUS_Multitool_1" src="https://github.com/user-attachments/assets/d75ff67a-5f64-440b-a7da-021e11598483" />

<img width="932" height="660" alt="EUS_Multitool_2" src="https://github.com/user-attachments/assets/0f7640e4-af06-4445-a92a-645aa97043f3" />

## Dependencies

- **SwiftDialog**: Used for GUI prompts and user interaction.
- **Jamf Pro**: Requires access to Jamf Pro API with appropriate credentials and permissions.
- **jq**: Command-line JSON processor.
- **xmllint**: Used for parsing XML responses.

## Setup Instructions

1. **Install SwiftDialog**:
   Ensure SwiftDialog is installed at `/usr/local/bin/dialog`. If not, the script will attempt to install it using a Jamf policy trigger `SwiftDialog_Install`.

2. **Configure API Credentials**:
   Update the following variables with your Jamf Pro instance details:
   - `JSS_URL`: URL of your Jamf Pro server.
   - `client_id`: OAuth client ID.
   - `client_secret`: OAuth client secret.

3. **Install Required Tools**:
   Ensure `jq` and `xmllint` are installed on the system for JSON and XML parsing.

## Notes

- Ensure the Jamf Pro API credentials have sufficient permissions to perform the required actions.
- The script uses bearer tokens for authentication and invalidates them after execution.
- The LAPS and PRK management features rely on specific extension attribute IDs and static group IDs. Update these values as needed for your environment.
- The script includes error handling and user prompts to guide technicians through the process.
