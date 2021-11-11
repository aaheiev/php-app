#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
  set -- php-fpm "$@"
fi

if [ "$1" = 'php-fpm' ] || [ "$1" = 'bin/console' ] || { [ "$1" = 'php' ] && [ "$2" = 'bin/console' ]; }; then
  echo "starting php app"
fi

exec docker-php-entrypoint "$@"
