Step 1: Update Your System

Before you begin installing Cockpit, ensure your Ubuntu system is up to date. Open your terminal and run the following command:
ADVERTISEMENT

sudo apt update && sudo apt upgrade 

This command updates the package list and upgrades your existing software packages to the latest versions.
Step 2: Install Cockpit

Once your system is up-to-date, you can proceed to install Cockpit. Enter the following command:
ADVERTISEMENT

sudo apt install cockpit 

This command will install the Cockpit package on your system.
Step 3: Enable Cockpit

Once the installation process completes, Cockpit service should be up and running automatically. To ensure Cockpit starts on boot, run the following command:

sudo systemctl enable --now cockpit.socket 

You can also check if the service is running by typing:
ADVERTISEMENT

sudo systemctl status cockpit 

If Cockpit is running properly, you’ll see an active (running) status.
Step 4: Adjust Firewall Settings

If you have UFW (Uncomplicated Firewall) activated, you need to adjust your firewall settings to allow Cockpit. Run the following command to enable Cockpit on UFW:

sudo ufw allow Cockpit 

Step 5: Accessing Cockpit Web Interface

Now that Cockpit is installed and running, you can access its web interface by opening your web browser and navigating to the following address:

    https://your_server_ip:9090 

Replace ‘your_server_ip’ with your actual server IP address. Note the ‘s’ in ‘https’; Cockpit uses a secure connection and you must specify this in the address.

You will be greeted by a login screen. Use your server credentials to log in.
