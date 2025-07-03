# ──────────────────────────────────────────────────────────────────────────────
# PHP-FPM image for Axialy Admin
#   • Keeps the image small and stateless – source code is bind-mounted
# ──────────────────────────────────────────────────────────────────────────────
FROM php:8.3-fpm-alpine

# ── Required PHP extensions ───────────────────────────────────────────────────
RUN apk add --no-cache \
      mysql-client \
      libzip-dev \
    && docker-php-ext-install pdo pdo_mysql zip

# ── Empty document root (code mounted by docker-compose) ──────────────────────
RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html

EXPOSE 9000
CMD ["php-fpm"]
