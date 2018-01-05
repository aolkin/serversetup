#!/bin/bash

. common.sh

exec 3>&1
 
# Generate the dialog box
result=$(dialog --title "Setup Actions" \
  --clear  \
  --checklist "Choose setup actions to take:" 0 0 3 \
  "Install Updates" "apt update, upgrade, autoremove" on \
  "Install Tools" "emacs, byobu, git, pip3" on \
  "Reboot" "reboot" off \
  2>&1 1>&3)

# Get dialog's exit status
return_value=$?

# Close file descriptor 3
exec 3>&-

# Act on the exit status
if [[ $return_value == $DIALOG_OK ]]; then
    clear
    if [[ "$result" == *"Updates"* ]]; then
	dosudo apt -y update
	dosudo apt -y upgrade
	dosudo apt -y autoremove
    fi
    if [[ "$result" == *"Tools"* ]]; then
	dosudo apt install -y emacs byobu git python3-pip
    fi
    if [[ "$result" == *"Install"* ]]; then
	echo "Press enter to continue..."
	read
    fi
    if [[ "$result" == *"Reboot"* ]]; then
	dialog --yesno "Reboot now?" 0 0
	if [[ $? == $DIALOG_OK ]]; then
	    dosudo reboot
	fi
    fi
fi

killrefresh

echo

clear
