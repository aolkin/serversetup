# Server Setup
Scripts to automate common server installation and setup tasks.

This script was written and tested in a recent Ubuntu environment,
and probably won't work as well elsewhere.

It can be run as a normal user, and will attempt to manage sudo access
to minimize required intervention.

## install.sh

Allows easy upgrading of existing packages, as well as installing tools I use.

## setup.sh

Automates actions including:

1. Creating an unpriviledged application user
2. Creating an nginx virtualhost
3. Setting up certbot
4. Setting up a postgresql database for this user
5. Cloning a git repository
6. Setting up a systemd unit for a service

It will also automatically install system and python packages as needed.

Some actions, especially the last two, could use some work.

### Action Notes

#### Cloning a git repository

This will also generate an SSH key for the given user,
which can be configured as a deploy key on Github.
