This installation method is for advanced users only
Make sure you understand the requirements
Install Home Assistant Supervised
This installation method provides the full Home Assistant experience on a regular operating system. This means, all components from the Home Assistant method are used, except for the Home Assistant Operating System. This system will run the Home Assistant Supervisor. The Supervisor is not just an application, it is a full appliance that manages the whole system. It will clean up, repair or reset settings to default if they no longer match expected values.

By not using the Home Assistant Operating System, the user is responsible for making sure that all required components are installed and maintained. Required components and their versions will change over time. Home Assistant Supervised is provided as-is as a foundation for community supported do-it-yourself solutions. We only accept bug reports for issues that have been reproduced on a freshly installed, fully updated Debian with no additional packages.

This method is considered advanced and should only be used if one is an expert in managing a Linux operating system, Docker and networking.

Installation
Run the following commands as root (su - or sudo su - on machines with sudo installed):

Step 1: Install the following dependencies with this command:

apt-get install \
apparmor \
jq \
wget \
curl \
udisks2 \
libglib2.0-bin \
network-manager \
dbus \
systemd-journal-remote -y
Step 2: Install Docker-CE with the following command:

curl -fsSL get.docker.com | sh
Step 3: Install the OS-Agent:

Instructions for installing the OS-Agent can be found here

Step 4: Install the Home Assistant Supervised Debian Package:

wget https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
dpkg -i homeassistant-supervised.deb
Supported Machine types
generic-x86-64
odroid-c2
odroid-n2
odroid-xu
qemuarm
qemuarm-64
qemux86
qemux86-64
raspberrypi
raspberrypi2
raspberrypi3
raspberrypi4
raspberrypi3-64
raspberrypi4-64
tinker
khadas-vim3
Troubleshooting
If something's going wrong, use journalctl -f to get your system logs. If you are not familiar with Linux and how you can fix issues, we recommend to use our Home Assistant OS.
