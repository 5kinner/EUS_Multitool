#!/bin/bash
####################################################################################################
#
# DEVELOPEMENT
#
# Using Swiftdialog to help Technicians in daily duties without having to interact with Jamf
#
# Special Thanks to: Bart Reardon, Dan Snelson, Kyle Ericson, Rich Trouton
#
####################################################################################################

# Get current Logged in User needed for debugging
#loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
#echo $loggedInUser

# Stdout/Stderr redirect local logfile for debugging
#date=$(date +"%Y-%m-%d-%H:%M:%S")
#set -xv; exec 1>/Users/$loggedInUser/Desktop/jamfPolicy_$date.txt 2>&1


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogApp="/usr/local/bin/dialog"
dialogCommandFile="/var/tmp/dialog.log"
dialogTitle="EUS Multitool     ⚒️"
JSS_URL="https://yourJSSurl.com"
jamfEA="999"
mainIcon="SF=wand.and.stars,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
overlayIcon=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )
multitoolsettings="$HOME/Library/Application Support/multitool/multitoolsettings.plist"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for Swiftdialog installation
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ ! -f "$dialogApp" ]; then
echo "Installing Swiftdialog"
/usr/local/jamf/bin/jamf policy -event custom_trigger
else
echo "Swiftdialog installed, continuing ..."
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for EUS Multitool preferences, prompt if not found
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Check if the credentials are already saved
if [ -f "$multitoolsettings" ]; then
 # Credentials are saved, so read them from the file
 API_USER=$(/usr/bin/defaults read "$multitoolsettings" API_USER)
 API_PASS=$(security find-generic-password -w -s "Multitool" -a "$API_USER")

else
 # Credentials are not saved, so prompt the user for them 
 dialogInitial=$( $dialogApp \
  --title "$dialogTitle" \
  --icon "$mainIcon" \
  --overlayicon "SF=lock.circle.fill,Palette=red,white,white,bgcolor=none" \
  --message "Please enter authentication details for use with the Mutlitool Application" \
  --moveable \
  --button2 \
  --textfield "Username",required \
  --textfield "Password",required,secure \
  --checkbox "Save Credentials" -p)
  
 API_USER=$( echo "$dialogInitial" | grep "Username" | awk -F " : " '{print $NF}')
 API_PASS=$( echo "$dialogInitial" | grep "Password" | awk -F " : " '{print $NF}')
 checkbox=$( echo "$dialogInitial" | grep "Save Credentials" | awk -F " : " '{print $NF}')

 # If the user chose to save the credentials, write them to the file
  if [[ "$checkbox" == *true* ]]; then
    if [[ ! -d "$HOME/Library/Application Support/multitool" ]]; then
        mkdir "$HOME/Library/Application Support/multitool"
        if [[ ! -f "$multitoolsettings" ]]; then
            touch "$multitoolsettings"
        fi
    fi
    security add-generic-password -s "Multitool" -a "$API_USER" -w "$API_PASS" -T /usr/bin/security
    defaults write "$multitoolsettings" API_USER -string $API_USER
  fi
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Grab the API Bearer Token
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

authToken=$(curl -s -u "$API_USER:$API_PASS" $JSS_URL/api/v1/auth/token -X POST)
api_token=$(plutil -extract token raw - <<< "$authToken")

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Functions
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function show_dialog_msg() {
 
  local dialogMSG="$dialogApp --ontop --title \"$dialogTitle\" \
  --message \"$message\" \
  --icon \"$mainIcon\" \
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

######## ABM CHECK ############################# ABM CHECK ########

function ABM_Check() {

ABMserial="$serial"

ABMList=$(curl -s -H "accept: application/json" -H "Authorization: Bearer $api_token" $JSS_URL/api/v1/device-enrollments/1/devices)
echo "$ABMList"

  if echo "$ABMList" | grep -q $serial; then
    echo "Serial number: $serial is present in ABM."
    Alerticon="SF=checkmark,color=green,bgcolor=none"
    message="The Computer with Serial : "$serial"\n\n ... was found in ABM."
  else
    echo "Error: Serial number is not in ABM"
    Alerticon="SF=xmark,color=red,bgcolor=none"
    message="The Computer with Serial : "$serial"\n\n ... wasn't found in ABM. Please try again incase of mistyped serial characters."  
  fi
# Display the info to the user
$dialogApp --title "$dialogTitle" --button1text "OK" --mini --message "$message" --icon "$Alerticon" -p

exit

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Initial Dialog prompt with check for serial in Jamf
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

while [[ -z ${computerCheck} ]]; do

dialogCMD="$dialogApp --ontop --title \"$dialogTitle\" \
--message \"Please enter the computers serial you need information on.\" \
--icon \"$mainIcon\" \
--moveable \
--button1text \"OK\" \
--button2text \"Quit\" \
--overlayicon \"$overlayIcon\" \
--titlefont 'size=28' \
--messagefont 'size=28' \
--textfield \"Serial\",required=true,prompt=\"Please enter the Serial Number\" \
--selecttitle \"Select an Option\" \
--selectvalues \"View LAPS Password,View Personal Recovery Key,––––––––––––––––––––––––––––,Change LAPS Password,Change Personal Recovery Key,––––––––––––––––––––––––––––,Enable Remote Desktop,Check device in ABM\" \
--position 'centre' \
--quitkey k"

# First Prompt of Swift_dialog is here and waits for user input
userInput=$( eval "$dialogCMD" )
# Grab the exit code result
result=$?

serial=$( echo "$userInput" | grep "Serial" | awk -F " : " '{print $NF}' )
option=$( echo "$userInput" | grep "SelectedOption" | awk -F " : " '{print $NF}' | tr -d '"')
echo "Serial : ${serial}"
echo "Option : ${option}"
echo "Result: $result"

if [ "$option" == "Check device in ABM" ]; then

#Run ABM_Check Function
ABM_Check

else

  if [[ ${result} -ne 0 ]]; then

    echo "Cancelled by User"
    exit 0

  else

    computerCheck=$(/usr/bin/curl -s -H "Authorization: Bearer $api_token" -H "Accept: application/xml" "${JSS_URL}/JSSResource/computers/serialnumber/${serial}/subset/general" | xpath -e '//computer/general/id/text()' )

    if [[ -z ${computerCheck} ]]; then
      echo "Error: Serial number is not in Jamf"
      $dialogApp --title "$dialogTitle" --button1text "Try Again" --mini --message "\nComputer not found in Jamf. Please check serial number and try again." --icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns -p
    else
      echo "Serial number: $serial is valid."
    fi

  fi

fi

done

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# User selection actions. View/Change LAPS/PRK
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

######## VIEW LAPS PASSWORD ############################# VIEW LAPS PASSWORD ########
######## VIEW LAPS PASSWORD ############################# VIEW LAPS PASSWORD ########

if [ "$option" == "View LAPS Password" ]; then

# API command to grab the LAPS password for the given serial 
LAPS=$(curl -s -H "accept: text/xml" -H "Authorization: Bearer $api_token" $JSS_URL/JSSResource/computers/serialnumber/$serial | xmllint --xpath '//extension_attribute[id='$jamfEA']/value/text()' - | awk '{print $2 " : Expires " $5}')
echo $LAPS | awk '{print $1}' | pbcopy

message="The LAPS password for\n\n"$serial" is:\n\n"$LAPS""

# Display the info to the user
show_dialog_msg

fi

######## CHANGE LAPS PASSWORD ############################# CHANGE LAPS PASSWORD ########
######## CHANGE LAPS PASSWORD ############################# CHANGE LAPS PASSWORD ########

if [ "$option" == "Change LAPS Password" ]; then

GroupID="9999"
GroupName="Change LAPS Password"

# API endpoint
API_URL="JSSResource/computergroups/id/${GroupID}"
echo $API_URL

# XML header
xmlHeader="<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  
# API data adding to the endpoint
apiData="<computer_group><id>${GroupID}</id><name>${GroupName}</name><computer_additions><computer><name>$serial</name></computer></computer_additions></computer_group>"
echo $apiData

curl -s \
	--header "Authorization: Bearer ${api_token}" --header "Content-Type: text/xml" \
	--url "${JSS_URL}/${API_URL}" \
	--data "${apiData}" \
  --request PUT \
echo "The Computer with Serial $serial has been added to the static group"
    
message="The LAPS password for "$serial"\n\n ... is scheduled for change.\n\nThis may take a few hours."

# Display the info to the user
show_dialog_msg

fi

######## VIEW RECOVERY KEY ############################# VIEW LAPS PASSWORD ########
######## VIEW RECOVERY KEY ############################# VIEW LAPS PASSWORD ########

if [ "$option" == "View Personal Recovery Key" ]; then
  
machineID=$(curl -s -H "accept: text/xml" -H "Authorization: Bearer $api_token" $JSS_URL/JSSResource/computers/serialnumber/$serial | xmllint --xpath '/computer/general/id/text()' - )
echo $machineID

PRK=$(curl -X GET -s -H "accept: application/json" -H "Authorization: Bearer $api_token" $JSS_URL/api/v1/computers-inventory/$machineID/filevault | grep "personalRecoveryKey" | awk -F ": " '{print $NF}' | tr -d '"'\, )
echo $PRK

message="The Personal Recovery Key for\n\n"$serial" is:\n\n"$PRK""

# Display the info to the user
show_dialog_msg
  
fi

######## CHANGE RECOVERY KEY ############################# CHANGE RECOVERY KEY ########
######## CHANGE RECOVERY KEY ############################# CHANGE RECOVERY KEY ########

if [ "$option" == "Change Personal Recovery Key" ]; then
  
GroupID="9999"
GroupName="Change Personal Recovery Key"

# API endpoint
API_URL="JSSResource/computergroups/id/${GroupID}"
echo $API_URL

# XML header
xmlHeader="<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  
# API data adding to the endpoint
apiData="<computer_group><id>${GroupID}</id><name>${GroupName}</name><computer_additions><computer><name>$serial</name></computer></computer_additions></computer_group>"
echo $apiData

curl -s \
	--header "Authorization: Bearer ${api_token}" --header "Content-Type: text/xml" \
	--url "${JSS_URL}/${API_URL}" \
	--data "${apiData}" \
  --request PUT \
echo "The Computer with Serial $serial has been added to the static group"
    
message="The PRK for "$serial"\n\n ... is scheduled for change.\n\nThis may take a few hours."

# Display the info to the user
show_dialog_msg

fi

######## ENABLE REMOTE DESKTOP ############################# ENABLE REMOTE DESKTOP ########
######## ENABLE REMOTE DESKTOP ############################# ENABLE REMOTE DESKTOP ########

if [ "$option" == "Enable Remote Desktop" ]; then

RemoteCommand="EnableRemoteDesktop"

machineID=$(curl -s -H "accept: text/xml" -H "Authorization: Bearer $api_token" $JSS_URL/JSSResource/computers/serialnumber/$serial | xmllint --xpath '/computer/general/id/text()' - )
echo $machineID

# API endpoint
API_URL="JSSResource/computercommands/command/$RemoteCommand/id/${machineID}"
echo $API_URL

curl -s \
	--header "Authorization: Bearer ${api_token}" --header "Content-Type: text/xml" \
	--url "${JSS_URL}/${API_URL}" \
  --request POST \

echo "The Computer with Serial $serial has had Remote Desktop Enabled"
    
message="The Computer with "$serial"\n\n ... has had Remote Desktop Enabled"

# Display the info to the user
show_dialog_msg
  
fi

# Invalidate the Bearer Token
api_token=$(/usr/bin/curl "${JSS_URL}/api/v1/auth/invalidate-token" --silent --header "Authorization: Bearer ${api_token}" -X POST)
echo "Token invalidated"

exit 0