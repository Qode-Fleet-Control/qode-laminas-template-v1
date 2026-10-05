# Built by .github/workflows/deploy.yml (context ., file Dockerfile) and pushed
# to Artifact Registry.
#
# Laminas MVC skeleton on FrankenPHP (a Caddy-based PHP app server), PHP 8.3: the
# skeleton's composer.json allows only ~8.1 || ~8.2 || ~8.3. Production mode (the
# skeleton's development mode is not enabled in the image), docroot public/, served
# on 0.0.0.0:$PORT with the PORT read from the environment when the container STARTS.
# Replaces the skeleton's stock php:8.3-apache Dockerfile, which serves on a fixed :80.
FROM dunglas/frankenphp:1-php8.3-bookworm AS runtime
RUN install-php-extensions intl zip pdo_pgsql
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction
COPY . .
RUN composer dump-autoload --optimize --no-dev --no-interaction \
 && useradd -r -u 10001 -d /app app \
 && mkdir -p data/cache && chown -R app:app data /config/caddy /data/caddy
ARG BUILD_ID=""
ENV PORT=8080 SERVER_ROOT=/app/public BUILD_ID=$BUILD_ID
USER app
EXPOSE 8080
CMD ["sh", "-c", "SERVER_NAME=\":${PORT}\" exec frankenphp run --config /etc/frankenphp/Caddyfile"]
