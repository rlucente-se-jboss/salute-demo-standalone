# How's My Salute standalone demo
This demonstrates the [How's My
Salute](https://github.com/tedbrunell/HowsMySalute) application and
a timer to periodically check for application updates. You'll need
a USB webcam and monitor for this demonstration.

## Install a RHEL instance
Start with a workstation install of RHEL 9. Make sure this repository
is copied to your RHEL host. During the RHEL installation, configure
a regular user with `sudo` privileges.

### Adjust demo settings
These instructions assume that the `salute-demo-standalone` git repository
is copied to your own home directory on the RHEL host.

You'll need to customize the settings in the `demo.conf` script to
include your Red Hat Subscription Manager (RHSM) credentials to
login to the [customer support portal](https://access.redhat.com)
to pull updated content. The `MY_SERVER` setting should be an IP
address assigned to the host that is stable.  My DHCP server is
configured to give predictable IP addresses to the RHEL host.  Make
sure to do something similar for your environment.

## Configure the RHEL host
The shell scripts included in this repository handle setting up all
the dependencies to support the demo. To begin, go to the directory
hosting this repository.

    cd ~/salute-demo-standalone

The first script registers with the [Red Hat Customer Portal](https://access.redhat.com)
using the credentials provided in the `demo.conf` file. All packages
are updated. It's a good idea to reboot after as the kernel may
have been updated.

    sudo ./01-setup-rhel.sh
    reboot

The second script installs several packages including enabling the
web console. The web console can be accessed via the https://MY_SERVER:9090
URL where `MY_SERVER` is the IP address or name of the RHEL host.
Please make sure to log out and then log in again to enable bash
command completion.

    cd ~/salute-demo-standalone
    sudo ./02-install-cockpit.sh
    exit

The third script configures a docker v2 registry to enable edge
devices to pull container images without requiring external network
access. Once this demo is installed, I can easily run it without
relying on external connectivity.

    sudo ./03-config-registry.sh

Test that the container registry is up and running using the following
command (where `MY_SERVER` is the IP address or name of the RHEL host):

    curl -s http://MY_SERVER:5000/v2/_catalog | jq

The fourth script builds the [How's My Salute](https://github.com/tedbrunell/HowsMySalute)
demo as a containerized application. The Army version is tagged as
`prod` with the intent of moving that tag from one version to another
to trigger application updates on the RHEL host. This is discussed
later.

    sudo ./04-build-containers.sh

Verify that the application is in the registry using the following
command (where `MY_SERVER` is the IP address or name of the RHEL host):

    curl -s http://MY_SERVER:5000/v2/_catalog | jq

The fifth and final script configures the container web application to run as a service, enables a timer to check for updates every thirty seconds, and configures automatic login to the UI with firefox launching on login to browse to the web application.

NB: Generating the systemd service file for the application requires
creating a container. The container creation will fail if no webcam
device is attached to the RHEL host. Make sure when running this
script that a webcam is attached and the `/dev/video0` device exists.

    sudo ./05-config-auto-updates.sh

At this point, the needed software components have been installed
to support the demo.

## Test the demo
Reboot the RHEL host. After booting, the user should auto-login to
the UI and the firefox browser should be launched automatically to
display the web application.

## Demonstrate podman auto-update
There are actually two versions of the container web application
that can run on the RHEL host. Both versions reside in the local
container registry running on the RHEL host.
The RHEL host has a slightly modified podman-auto-update
systemd service that checks the container registry every thirty
seconds and then, if the application is different than what's
currently running, downloads the new container image and restarts
the application.

To initiate this, use the following commands in a terminal window
on the RHEL host:

    podman pull --all-tags MY_SERVER:5000/howsmysalute
    podman tag MY_SERVER:5000/howsmysalute:usmc MY_SERVER:5000/howsmysalute:prod
    podman push MY_SERVER:5000/howsmysalute:prod

where `MY_SERVER` is the IP address or name of the RHEL host.

In the console, you should see the How's My Salute application
restart within thirty seconds. You may need to kill the firefox
application so it automatically restarts using the following command
in a terminal:

    pkill firefox

The application should now be checking a US Marine Corps salute
instead of an Army one.

