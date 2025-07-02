FROM php:8.3-fpm-alpine

# ── Build deps ────────────────────────────────────────────────────────────────
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
        icu-dev zlib-dev libzip-dev curl && \
    docker-php-ext-install intl pdo_mysql zip && \
    apk del .build-deps

# ── Runtime directory expected by AdminDBConfig ───────────────────────────────
RUN mkdir -p /home/i17z4s936h3j/private_axialy

# ── PHP config ────────────────────────────────────────────────────────────────
COPY php.ini /usr/local/etc/php/conf.d/99-custom.ini

# ── Copy application source into image ────────────────────────────────────────
COPY axialy-admin-product /var/www/html

WORKDIR /var/www/html

HEALTHCHECK CMD curl -f http://localhost:9000/health || exit 1
