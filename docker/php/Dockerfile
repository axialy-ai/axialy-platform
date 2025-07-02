# ──────────────────────────────────────────────────────────────────────────────
# PHP-FPM image for Axialy Admin
# ──────────────────────────────────────────────────────────────────────────────
FROM php:8.3-fpm-alpine

# Needed PHP extensions
RUN apk add --no-cache \
      mysql-client \
      libzip-dev \
    && docker-php-ext-install pdo pdo_mysql zip

# ── COPY application source ──────────────────────────────────────────────────
COPY axialy-admin-product /var/www/html

# Tighten perms
RUN chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html

EXPOSE 9000
CMD ["php-fpm"]
