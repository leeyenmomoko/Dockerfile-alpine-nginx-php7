FROM alpine

MAINTAINER leeyen <leeyenwork@gmail.com>

ENV TIMEZONE Asia/Taipei
ENV PHP_MEMORY_LIMIT 512M
ENV MAX_UPLOAD 50M
ENV PHP_MAX_FILE_UPLOAD 20
ENV PHP_MAX_POST 100M

RUN apk update
RUN apk add tzdata
RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && echo "${TIMEZONE}" > /etc/timezone
 
RUN apk add bash curl nano nginx supervisor openssh-client yarn nodejs git \
    php7 \
    php7-common \
    php7-intl \
    php7-gd \
    php7-mcrypt \
    php7-openssl \
    php7-opcache \
    php7-gmp \
    php7-json \
    php7-dom \
    php7-pdo \
    php7-zip \
    php7-zlib \
    php7-pgsql \
    php7-mysqli \
    php7-bcmath \
    php7-pdo_mysql \
    php7-gettext \
    php7-xmlreader \
    php7-xmlrpc \
    php7-bz2 \
    php7-iconv \
    php7-curl \
    php7-ctype \
    php7-fpm \
    php7-mbstring \
    php7-session \
    php7-phar \
    php7-soap \
    php7-pear \
    php7-dev \
    php7-simplexml \
    php7-tokenizer \
    php7-xmlwriter \
    php7-fileinfo

# install php7-mongodb 
RUN echo "http://dl-3.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories
RUN apk update && apk add php7-mongodb

RUN curl -sL https://getcomposer.org/installer | php \
    && mv composer.phar /usr/bin/composer

RUN mkdir /run/php-fpm /run/nginx

# Copy supervisor configs
COPY ./configs/supervisor/supervisor.d/ /etc/supervisor.d/

# Add www-data user and group for nginx php-fpm
RUN set -x ; \
  addgroup -g 82 -S www-data ; \
  adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1

# COPY nginx configs 
COPY ./configs/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./configs/nginx/sites-enabled/ /etc/nginx/sites-enabled/
COPY ./configs/nginx/conf.d/ /etc/nginx/conf.d/
RUN rm /etc/nginx/conf.d/default.conf

# COPY php configs
RUN ln -s /etc/php7 /etc/php
RUN ln -s /usr/sbin/php-fpm7 /usr/sbin/php-fpm
COPY ./configs/php/php.ini /etc/php/php.ini
COPY ./configs/php/php-fpm.d/www.conf /etc/php/php-fpm.d/www.conf

# Setting php env
RUN sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /etc/php/php.ini && \
    sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /etc/php/php.ini && \
    sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /etc/php/php.ini && \
    sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /etc/php/php.ini && \
    sed -i "s|post_max_size =.*|max_file_uploads = ${PHP_MAX_POST}|" /etc/php/php.ini

# create default root folder
RUN mkdir /var/www/html && chown nginx:nginx /var/www/html

# clean 
RUN apk del tzdata && rm -rf /var/cache/apk/*

RUN echo "<?php echo 'ok'; ?>" > /var/www/html/ok.php

EXPOSE 80

CMD ["/usr/bin/supervisord", "--nodaemon", "-c", "/etc/supervisord.conf"]
