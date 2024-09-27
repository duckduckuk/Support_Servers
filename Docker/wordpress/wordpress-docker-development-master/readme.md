# Local WordPress Dev Environment on Docker

## Install Environment

Simply download the *docker-compose.yml* and *wordpress/Dockerfile* files, then run:

```bash
docker-compose up -d
```

You may need to wait a moment for all of the WordPress files to get built.

Log in as *root* and set **group write** permissions on the website files:

```bash
docker exec -it $(docker ps -lq) /bin/bash
chown -R www-data:www-data .
chmod g+w . -R
exit
```

Log into the WordPress container with the following command (as the *docker* user).  **Composer** and **wp-cli** are both already installed.

```bash
docker exec -it -u docker $(docker ps -lq) /bin/bash
```

## Install WordPress

```bash
wp core install --title="WP Local on Docker" --admin_user="admin" --admin_password="password" --admin_email="email@test.com" --url="localhost:1337"
```
## Update themes and plugins (*optional*)

```bash
wp theme update --all
wp plugin update --all
```

## Install development plugins (*optional*)

```bash
wp plugin install debug-bar --activate
wp plugin install query-monitor --activate
wp plugin install theme-check --activate 
wp plugin install user-switching --activate
```

## Launch WordPress

Visit [localhost:1337](http://localhost:1337) and start working on your local WordPress running on Docker!