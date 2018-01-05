
: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_HELP=2}
: ${DIALOG_EXTRA=3}
: ${DIALOG_ITEM_HELP=4}
: ${DIALOG_ESC=255}

function dosudo {
    if [[ "$(whoami)" != "root" ]]; then
	sudo -n -H $@
	return $?
    else
	$@
	return $?
    fi
}

function refreshsudo {
    while true; do
	sudo -v
	sleep 600
    done
}

function killrefresh {
    kill $REFRESHPID
}

function docancel {
    killrefresh
    
    clear
    echo
    echo Canceled...
    echo
    exit
}

function cancel {
    if [[ $1 != $DIALOG_OK ]]; then
	docancel
    fi
}

if [[ "$(whoami)" != "root" ]]; then
    echo Not running as root. Please authenticate to sudo:
    echo
    sudo -v
    if [[ $? != 0 ]]; then
	exit
    fi
    refreshsudo &
    REFRESHPID=$!
fi
