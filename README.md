# Laminas template

Provisioned from [`Qode-Fleet-Control/fleet-template-v1`](https://github.com/Qode-Fleet-Control/fleet-template-v1) — the fleet
lifecycle contract (`bin/`, `fleet.conf`, `compose.yaml`, deploy workflows) with the
official Laminas MVC skeleton (ex Zend Framework) laid on top, served by FrankenPHP on
PHP 8.3.

> Laminas MVC is in maintenance mode upstream, and the skeleton's `composer.json`
> allows only PHP `~8.1 || ~8.2 || ~8.3` — hence PHP 8.3 here, not 8.4.

## Origin

    docker run --rm -u $(id -u):$(id -g) -v "$PWD":/w -w /w <php8.4 + composer:2 image> \
      composer create-project -s dev laminas/laminas-mvc-skeleton qode-laminas-template-v1 \
        --prefer-dist --no-interaction --ignore-platform-req=php

Generated 2026-10-05 (laminas/laminas-mvc-skeleton 2.5.x-dev, laminas-mvc ^3.7). The
generator ran on PHP 8.4, so `--ignore-platform-req=php` was needed to get past the
skeleton's own PHP ceiling; every locked package allows PHP 8.3, and the image installs
the lock on PHP 8.3 without that flag. `--no-interaction` answered "no" to every optional
package. `vendor/`, and the development-mode files the generator enabled
(`config/development.config.php`, `config/autoload/development.local.php`, both
gitignored), were removed; `composer.lock` is kept.

## Run it

**On the fleet** — nothing to do: `bin/run` (docker runtime) does `docker compose build`
then `docker compose up --remove-orphans` in the foreground. The app listens on
`0.0.0.0:$PORT`; `HEALTH_PATH=/` (the skeleton's welcome page — Laminas MVC has no
built-in health route).

**With docker**

    PORT=8080 bin/run              # or: docker compose up --build
    curl localhost:8080/

**Without docker** (PHP 8.1–8.3 with intl, composer):

    FLEET_RUNTIME=process PORT=8080 bin/run
    # = composer install; php -S 0.0.0.0:$PORT -t public  (the skeleton's `composer serve`)
    composer development-enable   # optional: the skeleton's development mode

| step | process runtime | docker runtime |
|---|---|---|
| install | `composer install --no-interaction` | — |
| build | — | `docker compose build` |
| start | `php -S 0.0.0.0:$PORT -t public` | `docker compose up --remove-orphans` |

## How the container works

- `Dockerfile`: `dunglas/frankenphp:1-php8.3-bookworm` (+ intl, zip, pdo_pgsql),
  `composer install --no-dev`, production mode (config + module-map caches in
  `data/cache/`), non-root user `app`.
- The command serves with FrankenPHP's stock Caddyfile on `SERVER_NAME=":$PORT"` (plain
  HTTP on the `$PORT` read when the container starts), document root `public/`.

## Deviations from the stock generator output, and why

- `Dockerfile` replaced: the skeleton's is `php:8.3-apache` on a fixed port 80 with no
  dependencies installed (it expects a bind mount). This one bakes the app in and serves
  the runtime `$PORT`.
- The skeleton's `docker-compose.yml` (fixed `8080:80`, bind mount) was removed:
  `compose.yaml` replaces it.
- This README replaces the skeleton's (installation and web-server notes; see
  https://docs.laminas.dev/tutorials/getting-started/skeleton-application/).
- Added `compose.yaml`, `.dockerignore`, `fleet.conf`, the fleet scripts in `bin/`
  (beside the skeleton's `clear-config-cache.php`), `.github/workflows/`,
  `docs/fleet-lifecycle.md`; `.gitignore` gained `.fleet/`, `.fleet-deploy.log`, `*.log`.

## Verified

**Not verified yet.** The `docker compose build` / `verify.sh` run was never reached: on
2026-10-05 the shared docker host's disk sat at 0-2 GB free (98 GB volume at 99-100%)
for more than three hours, below the 6 GB gate builds wait for. Before trusting this
template, run `verify.sh <dir> <port>` (run, restart and stop must all pass).

What *was* checked: `migrate.py audit` → READY; `php -l` on every PHP file this template
added or changed, and `sh -n` on its shell scripts → clean.

See `docs/fleet-lifecycle.md` for the lifecycle scripts.
