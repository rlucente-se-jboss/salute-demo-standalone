#!/usr/bin/env bash

. $(dirname $0)/demo.conf

[[ $EUID -ne 0 ]] && exit_on_error "Must run as root"

##
## verify that a video device is connected to the server
##

ERRMSG="No video device (/dev/video0) found. Container creation will fail."
[[ ! -e /dev/video0 ]] && exit_on_error "$ERRMSG"

##
## make sure the local registry is ready
##

systemctl restart container-registry.service

##
## generate systemd unit file for edge device container application
##

podman create --rm --name howsmysalute \
    --security-opt label=disable --device /dev/video0 -p 8080:8080 \
    --label io.containers.autoupdate=registry $MY_SERVER:5000/howsmysalute:prod
podman generate systemd --files --new --name howsmysalute
cp container-howsmysalute.service /etc/systemd/system/
podman rm -f howsmysalute

##
## create firefox startup script for web application
##

mkdir -p $CURRENT_HOME/bin
cat > $CURRENT_HOME/bin/redhat-kiosk << EOF
#!/bin/sh
MY_SERVER=${MY_SERVER}

EOF

mkdir -p $CURRENT_HOME/bin
cat >> $CURRENT_HOME/bin/redhat-kiosk << 'EOF'
while true; do
    if [ -n "$(curl -s --head --request GET http://$MY_SERVER:8080 | grep '200 OK')" ]
    then
    	firefox -kiosk http://$MY_SERVER:8080
    fi
    sleep 1
done
EOF

chmod 755 $CURRENT_HOME/bin/redhat-kiosk
chown -R $CURRENT_USER:$CURRENT_USER /home/$CURRENT_USER

##
## override podman auto-update service to run every 30 seconds
##

mkdir -p /etc/systemd/system/podman-auto-update.timer.d
cat > /etc/systemd/system/podman-auto-update.timer.d/override.conf << EOF
[Timer]
OnCalendar=
RandomizedDelaySec=0
OnBootSec=30
OnUnitActiveSec=30
EOF

##
## enable firewall permissions to access web application
##

firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload

##
## enable auto-login for the current user
##

sed -i.bak '/^\[daemon\]/a AutomaticLoginEnable=True\nAutomaticLogin='${CURRENT_USER}'\n' /etc/gdm/custom.conf

##
## allow containers to use devices
##

setsebool -P container_use_devices=1

##
## Fix SELinux contexts
##

restorecon -vFr /etc

##
## make sure local registry is running
##

systemctl restart container-registry.service

##
## enable systemd services
##

systemctl daemon-reload
systemctl enable --now podman-auto-update.timer container-howsmysalute.service

##
## enable salute browser autostart on login
##

mkdir -p $CURRENT_HOME/.config/autostart
cat > $CURRENT_HOME/.config/autostart/salute.sh.desktop <<EOF
[Desktop Entry]
Type=Application
Exec=${CURRENT_HOME}/bin/redhat-kiosk
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=salute
Name=salute
Comment[en_US]=Launch salute application on log in
Comment=Launch salute application on log in
EOF
chown -R $CURRENT_USER:$CURRENT_USER $CURRENT_HOME/.config
chmod 755 $CURRENT_HOME/.config/autostart/salute.sh.desktop

