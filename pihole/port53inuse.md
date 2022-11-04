Pi-hole port 53 “address already in use” (Portainer/Docker)
17th April 2022
I’ve been setting up Portainer (Docker) on an Intel NUC running Ubuntu but came across an issue when trying to get Pi-hole installed with a port 53 error.

This post is mostly for my own future reference but I thought I’d put it here in case it helps anyone else.

When deploying Pi-hole in docker (in my case through Portainer), if you get an error along the lines of “pihole 53 portainer bind: address already in use” then this may help.

First off, you can check if anything is running on port 53 with the following:

sudo lsof -i tcp:53
in my case I could see “systemd-resolved” was listening on this port (I’m assuming this is the systems internal DNS resolver?) and after some digging I found you can disable it with the following:

sudo systemctl disable systemd-resolved.service
sudo systemctl stop systemd-resolved
This solved my issue with deploying Pi-hole….but created another one, I could no longer resolve any Docker tags as I’d get a DNS error (“Temporary failure in name resolution”).

Turns out, disabling the internal DNS resolver will break DNS resolution, who would have guessed?! My solution was to set the nameserver to be my local DNS server (my Pi-hole in this case), I’d imagine you could set this to be Cloudflare (1.1.1.1) or Google (8.8.8.8) etc. too.

sudo nano /etc/resolv.conf
Mine was set to 127.0.0.53 by default, you can then change “nameserver” to the address of your choice.
