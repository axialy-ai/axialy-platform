# ──────────────────────────────────────────────────────────────────────────────
# PHP-FPM image for Axialy Admin (source mounted at runtime, so no COPY here)
# ──────────────────────────────────────────────────────────────────────────────
FROM php:8.3-fpm-alpine

# Required PHP extensions
RUN apk add --no-cache \
      mysql-client \
      libzip-dev \
    && docker-php-ext-install pdo pdo_mysql zip

# Create document root (empty – code will be bind-mounted)
RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html

EXPOSE 9000
CMD ["php-fpm"]
