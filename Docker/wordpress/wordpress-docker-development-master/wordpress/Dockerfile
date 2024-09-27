FROM wordpress:latest

# Update and install
RUN apt-get update
RUN apt-get install less git vim -y

# Install the development user, add them to the www-data group so they have permissions to run wp-cli commands
RUN useradd -ms /bin/bash docker; usermod -a -G www-data docker

# Install wp-cli
RUN curl -o /bin/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x /bin/wp-cli.phar
RUN cd /bin && mv wp-cli.phar wp
RUN mkdir -p /var/www/.wp-cli/cache && chown www-data:www-data /var/www/.wp-cli/

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Note: Use docker-compose up -d --force-recreate --build when Dockerfile has changed.
