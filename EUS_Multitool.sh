#!/bin/bash
####################################################################################################
#
# Using Swiftdialog to help Technicians in daily duties without having to interact with Jamf
#
# Special Thanks to: Bart Reardon, Dan Snelson, Kyle Ericson, Rich Trouton
#
####################################################################################################

# Get current Logged in User
#loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
#echo $loggedInUser

# Stdout/Stderr redirect local logfile
#date=$(date +"%Y-%m-%d-%H:%M:%S")
#set -xv; exec 1>/Users/$loggedInUser/Desktop/jamfPolicy_$date.txt 2>&1

#Set verbose output
#set -xv; exec 3>&1

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogApp="/usr/local/bin/dialog"
dialogCommandFile="/var/tmp/dialog.log"
dialogTitle="EUS Multitool     ⚒️"
JSS_URL="https://jssurl.com"
client_id="ClientID here"
client_secret="ClientSecret here"
mainIcon="SF=wand.and.stars,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
overlayIcon=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for Swiftdialog installation
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ ! -f "$dialogApp" ]; then
echo "Installing Swiftdialog"
/usr/local/jamf/bin/jamf policy -event SwiftDialog_Install
else
echo "Swiftdialog installed, continuing ..."
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Grab the API Bearer Token
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

getAccessToken() {
	response=$(curl --silent --location --request POST "${JSS_URL}/api/oauth/token" \
 	 	--header "Content-Type: application/x-www-form-urlencoded" \
 		--data-urlencode "client_id=${client_id}" \
 		--data-urlencode "grant_type=client_credentials" \
 		--data-urlencode "client_secret=${client_secret}")
 	access_token=$(echo "$response" | plutil -extract access_token raw -)
 	token_expires_in=$(echo "$response" | plutil -extract expires_in raw -)
 	#token_expiration_epoch=$(($current_epoch + $token_expires_in - 1))
}

checkTokenExpiration() {
 	current_epoch=$(date +%s)
    if [[ token_expiration_epoch -ge current_epoch ]]
    then
        echo "Token valid until the following epoch time: " "$token_expiration_epoch"
    else
        echo "No valid token available, getting new token"
        getAccessToken
    fi
}

invalidateToken() {
	responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer ${access_token}" $url/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
	if [[ ${responseCode} == 204 ]]
	then
		echo "Token successfully invalidated"
		access_token=""
		token_expiration_epoch="0"
	elif [[ ${responseCode} == 401 ]]
	then
		echo "Token already invalid"
	else
		echo "An unknown error occurred invalidating the token"
	fi
}

getAccessToken
#echo $response
#echo $access_token

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Functions
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function show_dialog_msg() {
 
  local dialogMSG="$dialogApp --ontop --title \"$dialogTitle\" \
  --message \"$message\" \
  --icon \"$mainIcon\" \
  --appearance 'light' \
  --moveable \
  --button1text \"OK\" \
  --overlayicon \"$overlayIcon\" \
  --titlefont 'size=28' \
  --messagefont 'size=28' \
  --messagealignment 'centre' \
  --messageposition 'centre' \
  --position 'centre' \
  --quitkey k"

output=$( eval "$dialogMSG" )

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Initial Dialog prompt with check for serial in ABM
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogCMD="$dialogApp --ontop --title \"$dialogTitle\" \
--message \"Please enter the Serial you need information on.\" \
--icon \"$mainIcon\" \
--appearance 'light' \
--moveable \
--checkbox \"Computer\" \
--checkbox \"Mobile Device\" \
--button1text \"OK\" \
--button2text \"Quit\" \
--overlayicon \"$overlayIcon\" \
--titlefont 'size=28' \
--messagefont 'size=24' \
--textfield \"Serial\",required=true,prompt=\"Please enter the Serial Number\" \
--messagealignment 'centre' \
--messageposition 'centre' \
--position 'centre' \
--quitkey k"

# First Prompt of Swift_dialog is here and waits for user input
userInput=$( eval "$dialogCMD" )
# Grab the exit code result
result=$?
echo $result

# Check if the user canceled the dialog
if [[ ${result} -ne 0 ]]; then
    echo "Cancelled by User"
    exit 0
fi

# Extract the device type and serial number from the user input
computer=$(echo "$userInput" | grep '"Computer"' | awk -F " : " '{print $NF}' | tr -d '"')
mobile=$(echo "$userInput" | grep '"Mobile Device"' | awk -F " : " '{print $NF}' | tr -d '"')
serial=$(echo "$userInput" | grep 'Serial' | awk -F " : " '{print $NF}')

# Check if both options are selected
if [[ "$computer" == "true" && "$mobile" == "true" ]]; then
    echo "Error: Both Computer and Mobile Device selected"
    Alerticon="SF=xmark,color=red,bgcolor=none"
    message="Please run the tool again and select only one device type (Computer or Mobile Device)."
    show_dialog_msg
    exit 0
fi

# Set the deviceType variable based on the user's input
if [[ "$computer" == "true" ]]; then
      deviceType="computer"
      checkPrestageAPI="v3/computer-prestages"
      checkPrestageAPIscope="v2/computer-prestages"
      selectOptions="\"ABM Check,Check Prestage Assignment,––––––––––––––––––––––––––––,View LAPS Password,View Personal Recovery Key,––––––––––––––––––––––––––––,Change LAPS Password,Change Personal Recovery Key,––––––––––––––––––––––––––––,Enable Remote Desktop\" "
elif [[ "$mobile" == "true" ]]; then
      deviceType="mobile"
      checkPrestageAPI="v2/mobile-device-prestages"
      checkPrestageAPIscope="v2/mobile-device-prestages"
      selectOptions="\"ABM Check,Check Prestage Assignment,––––––––––––––––––––––––––––,Assign Device to User,––––––––––––––––––––––––––––,Update Inventory,Clear Passcode,Restart Device\" "
else
      echo "Error: No Device Type Checked"
      Alerticon="SF=xmark,color=red,bgcolor=none"
      message="Please run the tool again ensuring you select a device type checkbox." 
      # Display the info to the user
      show_dialog_msg
      exit 0
fi

echo "Device Type Selected: $deviceType"
echo "Serial : ${serial}"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Option Dialog prompt, User to select relevant Options
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogCMD="$dialogApp --ontop --title \"$dialogTitle\" \
--message \"What action would you like to perform on the device with\n\nSerial: **$serial**.\" \
--icon \"$mainIcon\" \
--appearance 'light' \
--moveable \
--button1text \"OK\" \
--button2text \"Quit\" \
--overlayicon \"$overlayIcon\" \
--titlefont 'size=28' \
--messagefont 'size=24' \
--selecttitle \"Select an Option\" \
--selectvalues ${selectOptions} \
--messagealignment 'centre' \
--messageposition 'centre' \
--position 'centre' \
--quitkey k"

# Prompt of Swift_dialog is here and waits for user input
userInput=$( eval "$dialogCMD" )
# Grab the exit code result
result=$?

option=$( echo "$userInput" | grep "SelectedOption" | awk -F " : " '{print $NF}' | tr -d '"')

echo "Option : ${option}"
echo "Result: $result"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# User selection actions. View/Change LAPS/PRK
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

######## ABM CHECK ############################# ABM CHECK ########
######## ABM CHECK ############################# ABM CHECK ########

if [[ "$option" == "ABM Check" ]]; then

ABMList=$(curl -s -H "accept: application/json" -H "Authorization: Bearer $access_token" $JSS_URL/api/v1/device-enrollments/1/devices)
  echo "$ABMList"

  if echo "$ABMList" | grep -q $serial; then
    echo "Serial number: $serial is present in ABM."
    message="The Serial : **"$serial"**\n\n ... is present in ABM." 
    # Display the info to the user
    show_dialog_msg
  else
    echo "Error: Serial number is not in ABM"
    Alerticon="SF=xmark,color=red,bgcolor=none"
    message="The Computer with Serial : **"$serial"**\n\n ... wasn't found in ABM. Please try again incase of mistyped serial characters." 
    # Display the info to the user
    show_dialog_msg
    exit 0
  fi

fi

######## CHECK PRESTAGE ASSIGNMENT ############################# CHECK PRESTAGE ASSIGNMENT ########
######## CHECK PRESTAGE ASSIGNMENT ############################# CHECK PRESTAGE ASSIGNMENT ########

if [[ "$option" == "Check Prestage Assignment" ]]; then

  # Function to get the prestage ID for a given serial number
  get_prestage_id() {
    response=$(curl -s -H "accept: application/json" -H "Authorization: Bearer $access_token" $JSS_URL/api/$checkPrestageAPIscope/scope)
    prestage_id=$(echo "$response" | jq -r --arg serial "$serial" '.serialsByPrestageId[$serial]')
    echo "$prestage_id"
  }

  # Function to get the prestage name for a given prestage ID
  get_prestage_name() {
    response=$(curl -s -H "accept: application/json" -H "Authorization: Bearer $access_token" "$JSS_URL/api/$checkPrestageAPI?page=0&page-size=100&sort=id%3Adesc")
    prestage_name=$(echo "$response" | jq -r --arg id "$prestage_id" '.results[] | select(.id == $id) | .displayName')
    echo "$prestage_name"
  }

  prestage_id=$(get_prestage_id)

    if [[ -n "$prestage_id" ]]; then
      prestage_name=$(get_prestage_name "$prestage_id")
        if [[ -n "$prestage_name" ]]; then
          message="The assigned prestage for\n\n **$serial**\n\nis **$prestage_name**."
        else
          message="Prestage ID $prestage_id not found."
        fi
    else
      message="Serial number **$serial** not found."
    fi

# Display the info to the user
  show_dialog_msg

fi

######## VIEW LAPS PASSWORD ############################# VIEW LAPS PASSWORD ########
######## VIEW LAPS PASSWORD ############################# VIEW LAPS PASSWORD ########

if [[ "$option" == "View LAPS Password" ]]; then

  # API command to grab the LAPS password for the given serial 
  LAPS=$(curl -v -s -H "accept: application/json" -H "Authorization: Bearer $access_token" "$JSS_URL/api/v1/computers-inventory?section=EXTENSION_ATTRIBUTES&page=0&page-size=100&filter=hardware.serialNumber==$serial")
  
  LAPS_Details=$(echo $LAPS | jq -r '.results[0].extensionAttributes[] | select(.definitionId == "103") | .values[0]')
  LAPS_Password=$(echo "$LAPS_Details" | awk -F'|' '{print $1}' | awk -F': ' '{print $2}' )
  LAPS_Expiration=$(echo "$LAPS_Details" | awk -F'|' '{print $2}' | awk -F': ' '{print $2}')
  echo "Password: $LAPS_Password"
  echo "Expiration: $LAPS_Expiration"

  # Copy the password to the clipboard
  echo "$LAPS_Password" | pbcopy

  message="The LAPS password for\n\n**"$serial"** is:\n\n"$LAPS_Password"\n\n Expiration: "$LAPS_Expiration""

  # Display the info to the user
  show_dialog_msg

fi

######## CHANGE LAPS PASSWORD ############################# CHANGE LAPS PASSWORD ########
######## CHANGE LAPS PASSWORD ############################# CHANGE LAPS PASSWORD ########

if [[ "$option" == "Change LAPS Password" ]]; then

GroupID="1271"
GroupName="Change LAPS Password"

# API endpoint
API_URL="JSSResource/computergroups/id/${GroupID}"
echo $API_URL
  
# API data adding to the endpoint
apiData="<computer_group><id>${GroupID}</id><name>${GroupName}</name><computer_additions><computer><name>$serial</name></computer></computer_additions></computer_group>"
echo $apiData

curl -s \
	--header "Authorization: Bearer $access_token" --header "Content-Type: text/xml" \
	--url "${JSS_URL}/${API_URL}" \
	--data "${apiData}" \
  --request PUT \
echo "The Computer with Serial **$serial** has been added to the static group"
    
message="The LAPS password for **"$serial"**\n\n ... is scheduled for change.\n\nThis may take a few hours."

# Display the info to the user
show_dialog_msg

fi

######## VIEW RECOVERY KEY ############################# VIEW LAPS PASSWORD ########
######## VIEW RECOVERY KEY ############################# VIEW LAPS PASSWORD ########

if [[ "$option" == "View Personal Recovery Key" ]]; then
  
#machineID=$(curl -s -H "accept: text/xml" -H "Authorization: Bearer $access_token" $JSS_URL/JSSResource/computers/serialnumber/$serial | xmllint --xpath '/computer/general/id/text()' - )
#echo $machineID

# API command to grab the LAPS password for the given serial 
machineID=$(curl -s -H "accept: application/json" -H "Authorization: Bearer $access_token" "$JSS_URL/api/v1/computers-inventory?section=GENERAL&page=0&page-size=100&filter=hardware.serialNumber==$serial" | jq -r '.results[0].id')
echo "machineID :"$machineID

PRK=$(curl -s -H "accept: application/json" -H "Authorization: Bearer $access_token" "$JSS_URL/api/v1/computers-inventory/$machineID/filevault" | jq -r '.personalRecoveryKey' )
echo $PRK

    if [[ $PRK == "null" ]]; then
          message="The computer with serial : $serial \n\n doesn't have a recovery key in Jamf."
        else
          message="The Personal Recovery Key for\n\n"$serial" is:\n\n"$PRK""
    fi

# Display the info to the user
show_dialog_msg
  
fi

######## CHANGE RECOVERY KEY ############################# CHANGE RECOVERY KEY ########
######## CHANGE RECOVERY KEY ############################# CHANGE RECOVERY KEY ########

if [[ "$option" == "Change Personal Recovery Key" ]]; then
  
GroupID="1272"
GroupName="Change LAPS Password"

# API endpoint
API_URL="JSSResource/computergroups/id/${GroupID}"
echo $API_URL
  
# API data adding to the endpoint
apiData="<computer_group><id>${GroupID}</id><name>${GroupName}</name><computer_additions><computer><name>$serial</name></computer></computer_additions></computer_group>"
echo $apiData

curl -s \
	--header "Authorization: Bearer $access_token" --header "Content-Type: text/xml" \
	--url "${JSS_URL}/${API_URL}" \
	--data "${apiData}" \
  --request PUT \
echo "The Computer with Serial **$serial** has been added to the static group"
    
message="The LAPS password for "$serial"\n\n ... is scheduled for change.\n\nThis may take a few hours."

# Display the info to the user
show_dialog_msg

fi

######## ENABLE REMOTE DESKTOP ############################# ENABLE REMOTE DESKTOP ########
######## ENABLE REMOTE DESKTOP ############################# ENABLE REMOTE DESKTOP ########

if [[ "$option" == "Enable Remote Desktop" ]]; then

  RemoteCommand="EnableRemoteDesktop"

  section="GENERAL"
  computerDetails=$(curl -s -H "accept: application/json" -H "Authorization: Bearer $access_token" "$JSS_URL/api/v1/computers-inventory?section=$section&page=0&page-size=100&filter=hardware.serialNumber==$serial")
  echo $computerDetails

  # Parse the necessary details from the response
  computerJSSID=$(echo "$computerDetails" | jq -r '.results[0].id')
  computerUdid=$(echo "$computerDetails" | jq -r '.results[0].udid')
  managementId=$(echo "$computerDetails" | jq -r '.results[0].general.managementId')

  echo "Computer JSS ID: $computerJSSID"
  echo "Computer UDID: $computerUdid"
  echo "Management ID: $managementId"

  # API endpoint
  API_URL="JSSResource/computercommands/command/$RemoteCommand/id/${computerJSSID}"
  echo $API_URL

  curl -s \
    --header "Authorization: Bearer ${access_token}" --header "Content-Type: text/xml" \
    --url "${JSS_URL}/${API_URL}" \
    --request POST \

  echo "The Computer with Serial $serial has had Remote Desktop Enabled"
      
  message="The Computer with **"$serial"**\n\n ... has had Remote Desktop Enabled"

  # Display the info to the user
  show_dialog_msg

fi

######## MOBILE DEVICE COMMANDS ############################# MOBILE DEVICE COMMANDS ########
######## MOBILE DEVICE COMMANDS ############################# MOBILE DEVICE COMMANDS ########

if [[ "$deviceType" == "mobile" && "$option" != "Check Prestage Assignment" ]]; then


  if [[ "$option" == "Update Inventory" ]]; then
    MDMCommand="DEVICE_INFORMATION"
  elif [[ "$option" == "Clear Passcode" ]]; then
    MDMCommand="CLEAR_PASSCODE"
  elif [[ "$option" == "Restart Device" ]]; then
    MDMCommand="RESTART_DEVICE"
  elif [[ "$option" == "Assign Device to User" ]]; then


      dialogCMD="$dialogApp --ontop --title \"$dialogTitle\" \
      --message \"Please enter the Username to assign the device too.  \n\nEnsure you are using the correct format for username.  \nIf you are unsure, search in SNOW or AD for the user.\" \
      --icon \"$mainIcon\" \
      --appearance 'light' \
      --moveable \
      --button1text \"OK\" \
      --button2text \"Quit\" \
      --overlayicon \"$overlayIcon\" \
      --titlefont 'size=28' \
      --messagefont 'size=24' \
      --textfield \"Username\",required=true,prompt=\"Please enter the Username.\" \
      --position 'centre' \
      --quitkey k"

      # First Prompt of Swift_dialog is here and waits for user input
      userInput=$( eval "$dialogCMD" )
      # Grab the exit code result
      result=$?
      echo $result

      # Check if the user canceled the dialog
      if [[ ${result} -ne 0 ]]; then
          echo "Cancelled by User"
          exit 0
      fi

      echo "$userInput" 
      # Extract the username from the user input
      username=$(echo "$userInput" | grep -i '^Username' | awk -F ' : ' '{print $2}' | xargs)
      echo "$username"
      updateUsername=true
  fi

  # API commands to grab details of a mobile device
#section of mobile device details, if not specified, General section data is returned. Multiple section parameters are supported, e.g. section=GENERAL&section=HARDWARE
#Available values : GENERAL, HARDWARE, USER_AND_LOCATION, PURCHASING, SECURITY, APPLICATIONS, EBOOKS, NETWORK, SERVICE_SUBSCRIPTIONS, CERTIFICATES, PROFILES, USER_PROFILES, PROVISIONING_PROFILES, SHARED_USERS, EXTENSION_ATTRIBUTES
section="GENERAL"
mobileDetails=$(curl -s -H "accept: application/json" -H "Authorization: Bearer $access_token" "$JSS_URL/api/v2/mobile-devices/detail?section=$section&page=0&page-size=100&filter=serialNumber==$serial")
echo $mobileDetails

# Parse the necessary details from the response
mobileJSSID=$(echo "$mobileDetails" | jq -r '.results[0].mobileDeviceId')
mobileUdid=$(echo "$mobileDetails" | jq -r '.results[0].general.udid')
managementId=$(echo "$mobileDetails" | jq -r '.results[0].general.managementId')

echo "Mobile JSS ID: $mobileJSSID"
echo "Mobile UDID: $mobileUdid"
echo "Management ID: $managementId"

  if [[ "$updateUsername" == true ]]; then
    updatePayload=$(cat <<EOF
{
  "location": {
    "username": "$username"
  }
}
EOF
)
    updateResponse=$(curl --request PATCH \
      --url "$JSS_URL/api/v2/mobile-devices/$mobileJSSID" \
      --header "Authorization: Bearer $access_token" \
      --header 'Content-Type: application/json' \
      --data "$updatePayload")
    #echo "Username update response: $updateResponse"

    message="The selected device has been assigned to : **"$username"**"

    # Display the info to the user
    show_dialog_msg
  else
    json_data=$(cat <<EOF
{
  "commandData": {
    "commandType": "$MDMCommand"
  },
  "clientData": [
    {
      "managementId": "$managementId"
    }
  ]
}
EOF
)
    curl_response=$(curl --request POST \
      --url "$JSS_URL/api/v2/mdm/commands" \
      --header "Authorization: Bearer $access_token" \
      --header 'accept: application/json' \
      --header 'content-type: application/json' \
      --data "$json_data")
    #echo "Curl Response: $curl_response"
    
    message="The selected commands have been sent to the device with\n\nSerial: **"$serial"**"

    # Display the info to the user
    show_dialog_msg
  fi

fi

# Invalidate the Bearer Token
access_token=$(/usr/bin/curl "${JSS_URL}/api/v1/auth/invalidate-token" --silent --header "Authorization: Bearer ${access_token}" -X POST)
echo "Token invalidated"

exit 0