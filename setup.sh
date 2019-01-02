#!/bin/bash

. common.sh

exec 3>&1
 
# Generate the dialog box
result=$(dialog --title "Setup Actions" \
  --clear  --no-tags \
  --checklist "Choose setup actions to take:" 0 0 8 \
  "user-name" "Create an unprivileged application user" on \
  "nginx-vhost-port-name-domain" "Setup an Nginx VirtualHost" on \
  "certbot-nginx-domain" "Certbot Setup" on \
  "postgres-name" "Set up a PostgreSQL database" on \
  "git-name-repo" "Clone a git repository" on \
  "systemd-name-port" "Set up a systemd unit" on \
  2>&1 1>&3)

# Get dialog's exit status
return_value=$?

# Close file descriptor 3
exec 3>&-

if [[ $return_value == $DIALOG_OK ]]; then
    clear
    packages=""
    pipages=""
    if [[ "$result" == *"name"* ]]; then
	name=$(dialog --clear --stdout --title "Application Identifier" \
		      --inputbox "Please enter an identifier for the application you are setting up.\n\nThis will be the system username, the sql database, etc, as needed." 0 0)
	cancel $?
    fi
    if [[ "$result" == *"systemd"* ]]; then
	unitf="/etc/systemd/system/$name.service"
	if [[ -f "$unitf" ]]; then
	    dialog --title "systemd Unit File Exists" \
		   --yesno "systemd Unit file $unitf already exists, overwrite?" 0 0
	    cancel $?
	fi
    fi
    if [[ "$result" == *"domain"* ]]; then
	domain=$(dialog --clear --stdout --title "Virtual Host Domain" \
		 --inputbox "Please enter the fully-qualified domain name for this virtualhost." 0 0)
	cancel $?
    fi
    if [[ "$result" == *"vhost"* ]]; then
	vhost="/etc/nginx/sites-available/$domain"
	if [[ -f "$vhost" ]]; then
	    dialog --title "Virtual Host Exists" \
		   --yesno "Virtual host file $vhost already exists, overwrite?" 0 0
	    cancel $?
	fi
    fi
    if [[ "$result" == *"port"* ]]; then
	port=$(dialog --clear --stdout --title "Application/Proxy Port" \
	       --inputbox "Please enter the port the application server should
 run on." 0 0)
	cancel $?
    fi
    if [[ "$result" == *"repo"* ]]; then
	repo=$(dialog --clear --stdout --title "Git Remote" \
	       --inputbox "Please enter the remote URL for the github repository you wish to clone:" 0 0)
	cancel $?
    fi
    if [[ "$result" == *"systemd"* ]]; then
	cmd=$(dialog --clear --stdout --title "Application Command" \
	       --inputbox "Please enter the full path and arguments for the command to start at boot.\n\nThe following substitutions will be made:\n##name##\tthe user for the application\n##port##\tthe specified port\n##dir##\tthe application's repository" 0 0)
	cancel $?
	desc=$(dialog --clear --stdout --title "Application Unit Description" \
	       --inputbox "Please enter a description for the systemd unit file:" 0 0)
	cancel $?
    fi
    if [[ "$result" == *"nginx"* ]]; then
	packages="$packages nginx ssl-cert"
    fi
    if [[ "$result" == *"git"* ]]; then
	packages="$packages git"
    fi
    if [[ "$result" == *"certbot"* ]]; then
	packages="$packages software-properties-common"
    fi
    if [[ "$result" == *"postgres"* ]]; then
	packages="$packages postgresql"
	pipages="$pipages psycopg2"
    fi
    if [[ "$packages" != "" ]]; then
	dosudo apt install -y $packages
    fi
    if [[ "$pipages" != "" ]]; then
	dosudo pip3 install $pipages
    fi
    if [[ "$result" == *"certbot"* ]]; then
	apt show python-certbot-nginx >/dev/null 2>/dev/null
	if [[ $? != 0 ]]; then
	    dosudo add-apt-repository -y -s -u ppa:certbot/certbot
	fi
	dosudo apt install -y python-certbot-nginx
    fi
    if [[ "$result" == *"user"* ]]; then
	dosudo mkdir -p /apps
	id -u "$name" >/dev/null 2>/dev/null
	if [[ $? == 1 ]]; then
	    dosudo adduser --system --home "/apps/$name" "$name"
	fi
    fi
    if [[ "$result" == *"vhost"* ]]; then
	dosudo cp virtualhost "$vhost"
	dosudo mkdir -p "/var/log/nginx/$domain"
	dosudo mkdir -p "/var/www/$domain"
	dosudo chown "$name": "/var/log/nginx/$domain"
	dosudo chown "$name": "/var/www/$domain"
	dosudo ln -s "$vhost" "/etc/nginx/sites-enabled/$domain" 2>/dev/null

	dosudo sed -i "s/##domain_name##/$domain/g" "$vhost"
	dosudo sed -i "s/##app_port##/$port/g" "$vhost"
	
	dosudo nginx -t
	while [[ $? != 0 ]]; do
	    echo "Nginx test failed...opening editor."
	    dosudo -e "$vhost"
	    echo
	    dosudo nginx -t
	done
	dosudo systemctl restart nginx
    fi
    if [[ "$result" == *"certbot"* ]]; then
	dosudo systemctl stop nginx
	dosudo certbot --authenticator=standalone --installer=nginx -d "$domain"
	dosudo systemctl start nginx
    fi
    if [[ "$result" == *"postgres"* ]]; then
	sqlfile="$(mktemp)"
	sed "s/##user##/$name/g" postgres_db.sql > "$sqlfile"
	dosudo su postgres -c psql < "$sqlfile"
    fi
    if [[ "$result" == *"git"* ]]; then
	dosudo su - "$name" -s /bin/sh -c "echo | ssh-keygen"
	echo
	echo "$name's public key:"
	echo
	dosudo cat "/apps/$name/.ssh/id_rsa.pub"
	echo
	echo "Press enter to continue..."
	read
       	dosudo su - "$name" -s /bin/sh -c "ssh-keygen -R github.com"
       	dosudo su - "$name" -s /bin/sh -c "ssh-keyscan -H github.com >> /apps/$name/.ssh/known_hosts"
	dosudo su - "$name" -s /bin/sh -c "git clone --recurse-submodules '$repo' /apps/$name/repo"
    fi
    if [[ "$result" == *"systemd"* ]]; then
	dosudo cp unit.service "$unitf"

	dosudo sed -i "s/##cmd##/${cmd//\//\\\/}/g" "$unitf"
	dosudo sed -i "s/##name##/$name/g" "$unitf"
	dosudo sed -i "s/##port##/$port/g" "$unitf"
	dosudo sed -i "s/##description##/$desc/g" "$unitf"
	dosudo sed -i "s/##dir##/\/apps\/$name\/repo/g" "$unitf"

	dosudo systemctl daemon-reload
	dosudo systemctl enable "$name.service"
    fi
fi

killrefresh

echo

clear

echo "Done..."
