FROM ghcr.io/aaheiev/base/php-fpm-alpine:latest AS php-fpm

WORKDIR /app
COPY app .

COPY docker/php/conf/*.ini /usr/local/etc/php/
COPY docker/php/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf
COPY docker/php/docker-healthcheck.sh /usr/local/bin/docker-healthcheck
COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-healthcheck
RUN chmod +x /usr/local/bin/docker-entrypoint
HEALTHCHECK --interval=10s --timeout=5s --retries=10 CMD ["docker-healthcheck"]
ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]

FROM nginx:1.21-alpine AS nginx

COPY docker/nginx/conf/app.conf /etc/nginx/conf.d/default.conf

WORKDIR /app

COPY --from=php-fpm /app /app/
