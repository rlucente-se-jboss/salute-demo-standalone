#!/usr/bin/env bash

. $(dirname $0)/demo.conf

[[ $EUID -ne 0 ]] && exit_on_error "Must run as root"

##
## Install the packages
##

dnf -y install cockpit jq bash-completion container-tools gnome-tweaks

##
## Start the socket listeners
##

systemctl enable --now cockpit.socket

