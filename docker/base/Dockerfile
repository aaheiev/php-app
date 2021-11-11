FROM php:7.4-fpm-alpine

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
