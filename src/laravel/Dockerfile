# https://codeberg.org/gmhafiz/php-fpm-8-debian
FROM gmhafiz/php-8-debian:latest

RUN apt update && apt install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libldb-dev \
        libpq-dev \
        libzip-dev \
        supervisor \
        libjpeg-dev \
        libgif-dev \
        libcurl4-gnutls-dev \
        libonig-dev \
        libxml2-dev
RUN docker-php-ext-install calendar exif gettext intl pcntl pdo_pgsql pdo_mysql
RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ -with-webp=/usr/include
RUN docker-php-ext-install -j$(nproc) gd

RUN apt clean && rm -rf /var/lib/apt/lists/*

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN mkdir -p /home/www-data/.composer && \
    chown -R www-data:www-data /home/www-data

WORKDIR /var/www

# Run dependencies in its own layer to take advantage of caching
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-scripts

COPY . .

RUN chown -R www-data:www-data /var/www

RUN mkdir -p /var/log

COPY ./server/vhost.conf /etc/nginx/conf.d/default.conf
COPY ./server/nginx.conf /etc/nginx/nginx.conf
COPY ./server/www.conf /usr/local/etc/php-fpm.d/zz-www.conf

# PHP extensions
#COPY ./server/php.ini /usr/local/etc/php/php.ini

COPY ./server/supervisord.conf /etc/supervisord.conf

# COPY --from=grafana/promtail:latest /usr/bin/promtail /usr/bin/promtail

USER www-data
RUN php artisan migrate
RUN php artisan db:seed
RUN mkdir -p storage/framework/{sessions,views,cache} storage/logs bootstrap/cache

#RUN php artisan optimize

USER root
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
