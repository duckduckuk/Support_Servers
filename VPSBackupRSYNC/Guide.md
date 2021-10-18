# Backing up and Restoring a VPS Server Using Rsync

## This guide aims to show you steps required for setting up your very own file based backup folder between two SiteHost servers that you have root access on. This can be useful for performing backup restores, or migrating a VPS from one region to another without rebuilding the VPS.

By the end of this tutorial you should have a current backup of your server and knowledge of how you can restore this backup through Rescue Mode.

Requirements:

    2 x VPS servers with root access
    The destination VPS must have enough space available to accommodate the files from the source server
    An understanding of how to use SSH
    Both the source and the destination server must have rsync installed.

##Backing Up Your VPS

Firstly, SSH to the server that you’ll be using to store your backups on.

Create a directory for your backup files. In this example, I’ll be creating mine in the root directory.

mkdir /root/server_backup

Next, run the rsync command required to backup your remote server.

rsync -vaxHl --numeric-ids --delete root@IPADDRESS_OF_MYSERVER:/ --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} /root/server_backup/

You’ll need to swap out IPADDRESS_OF_MYSERVER for the actual IP address or Hostname of your remote server. You’ll also need to substitute the SSH user if you are not using the root user.

The flags used with this rsync command should retain the correct file ownership and permissions.

Once the rsync has finished, we’d recommend running some checks to determine whether the backup has been successful.

A couple of checks you can do are to check the disk space used by your backup directory.

du -sh /root/server_backup

And check whether the backup directory contains a copy of the files you copied.

ls -latr /root/server_backup

## Restoring your VPS

Firstly, put the VPS that you’d like to restore your backup onto into Rescue Mode from the SiteHost Control Panel. Make sure to note the temporary root password that’s displayed to you during this process. You will need to SSH to the server using these credentials.

After you log in using SSH, you will be shown the path to your server's disk, along with the commands needed to mount and chroot into your server's disk. In this example, the block device of my VPS is /dev/xvda3, but you can always confirm yours by running lsblk from the terminal.

            Note that we will not be chrooting into our server disk for this restore.

Run mount /dev/xvda3 /mnt in order to mount your existing filesystem.

By default rsync is not installed in Rescue Mode, but you can install it by running the following apt-get update; apt-get install rsync

Using rsync, transfer the backed up files from your storage VPS to the /mnt mount. Please note the following command will delete any files on the destination side that are not on the source side. It is always a good idea to perform a dry run first using the flag -n to see what files rsync will modify or delete.

rsync -vaxHl --numeric-ids --delete root@Storage_VPS:/root/server_backup/ /mnt/

Replacing Storage_VPS with the IP address of where your rsync backups are stored.

Run umount /dev/xvda3 to unmount the previously added block device.

Remove your server from Rescue mode and log in to your server with your credentials.

            You may find that you need to use an old password to log in to your server if you have changed your password since the backup was taken. If you’re cloning a server, rather than doing a backup restore, you may also need to change the network configuration and any existing firewalling in place.

