FROM php:7.4-fpm-alpine AS php-fpm

# persistent / runtime deps
RUN apk add --no-cache \
        acl \
        fcgi \
        file \
        gettext \
        git \
        openssh \
        openssh-client \
        libcurl \
        curl-dev \
        curl \
        libxml2-dev \
        libc-dev \
        build-base \
        gcc \
        gnu-libiconv \
        autoconf \
        rabbitmq-c-dev \
        libssh2-dev \
    ;

ARG APCU_VERSION=5.1.18

RUN set -eux; \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        icu-dev \
        libzip-dev \
        postgresql-dev \
        zlib-dev \
    ; \
    \
    docker-php-ext-configure zip; \
    docker-php-ext-install -j$(nproc) \
        intl \
        pdo \
        pdo_pgsql \
        json \
        curl \
        bcmath \
        sockets \
        zip \
    ; \
    pecl install \
        apcu-${APCU_VERSION} \
        amqp \
    ; \
    pecl clear-cache; \
    docker-php-ext-enable \
        apcu \
        opcache \
        amqp \
    ; \
    \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-cache --virtual .api-phpexts-rundeps $runDeps; \
    \
    apk del .build-deps

COPY --from=composer:2.0.4 /usr/bin/composer /usr/local/bin/composer

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

#
## "nginx" stage
## depends on the "php" stage above
FROM nginx:1.21-alpine AS nginx

COPY docker/nginx/conf/app.conf /etc/nginx/conf.d/default.conf

WORKDIR /app

COPY --from=php-fpm /app /app/
