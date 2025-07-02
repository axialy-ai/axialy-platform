#!/usr/bin/env bash
set -euo pipefail
docker build -t ghcr.io/axiamax/axialy-admin-php:latest -f docker/php/Dockerfile .
