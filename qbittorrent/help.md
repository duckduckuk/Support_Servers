Use qBitTorrent for Linux ISO's where possible. Only use direct download when you cant. Torrent is quicker.
(no - it's not illegal to torrent... but you can use torrents illegally!)
If you download an a linux distro ISO - its normally completely legal but check licenses first!
  

Login qbittorrent

Password reset:

systemctl stop qbittorrent.service
nano /home/qbittorrent/.config/qBittorrent/qBittorrent.conf

Once you are in the file, delete the entire line starting WebUI\Password_ha1. Should be somewhere at the bottom.
Restart the service afterwards

systemctl start qbittorrent.service

Default password would be adminadmin. Don’t forget to change once you are login.
