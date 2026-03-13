Create or edit /etc/cockpit/cockpit.conf:

Bash
sudo nano /etc/cockpit/cockpit.conf
Add the following content (replace your-domain.com with your actual domain):

Ini, TOML
[WebService]
Origins = https://your-domain.com wss://your-domain.com
ProtocolHeader = X-Forwarded-Proto
AllowUnencrypted = true
Note: AllowUnencrypted = true tells Cockpit it's okay to receive plain HTTP from Caddy (since Caddy handles the SSL). This prevents the "Unexpected error" caused by an internal HTTPS redirect loop.

2. Update your Caddyfile
Caddy handles WebSockets automatically, but you should ensure your block looks like this to handle the upstream properly:

Code snippet
your-domain.com {
    reverse_proxy localhost:9090 {
        # Optional: Use this if you didn't set AllowUnencrypted = true 
        # transport http {
        #    tls_insecure_skip_verify
        # }
    }
}
3. Restart the services
Apply the changes by restarting both:

Bash
sudo systemctl restart cockpit.socket
sudo systemctl restart caddy
