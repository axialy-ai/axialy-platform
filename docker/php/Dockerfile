FROM php:8.3-fpm-alpine

# Needed extensions
RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS icu-dev zlib-dev libzip-dev \
    && docker-php-ext-install intl pdo_mysql zip \
    && apk del .build-deps

# Config & health-check
COPY php.ini /usr/local/etc/php/conf.d/99-custom.ini
HEALTHCHECK CMD curl -f http://localhost:9000/ || exit 1

WORKDIR /var/www/html
