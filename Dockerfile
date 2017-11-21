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
 
RUN apk add curl nano nginx supervisor openssh-client yarn nodejs-current git \
    php5 \
    php5-common \
    php5-intl \
    php5-gd \
    php5-mcrypt \
    php5-openssl \
    php5-opcache \
    php5-gmp \
    php5-json \
    php5-dom \
    php5-pdo \
    php5-zip \
    php5-zlib \
    php5-pgsql \
    php5-mysqli \
    php5-bcmath \
    php5-pdo_mysql \
    php5-gettext \
    php5-xmlreader \
    php5-xmlrpc \
    php5-bz2 \
    php5-iconv \
    php5-curl \
    php5-ctype \
    php5-fpm \
#    php5-mbstring \
#    php5-session \
    php5-phar \
    php5-soap \
    php5-pear \
    php5-dev
#    php5-simplexml \
#    php5-tokenizer \
#    php5-xmlwriter

RUN ln -s /usr/bin/php5 /usr/sbin/php
RUN ln -s /usr/bin/php-fpm5 /usr/sbin/php-fpm
RUN ln -s /etc/php5 /etc/php

# install php5-mongodb 
#RUN echo "http://dl-3.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories
#RUN apk update && apk add php-mongodb

RUN curl -sL https://getcomposer.org/installer | php \
    && mv composer.phar /usr/bin/composer

RUN mkdir /run/php-fpm /run/nginx

# Copy supervisor configs
COPY ./configs/supervisor/supervisor.d/ /etc/supervisor.d/

# Add www-data user and group for nginx php5-fpm
RUN set -x ; \
  addgroup -g 82 -S www-data ; \
  adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1

# COPY nginx configs 
COPY ./configs/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./configs/nginx/sites-enabled/ /etc/nginx/sites-enabled/
COPY ./configs/nginx/conf.d/ /etc/nginx/conf.d/
RUN rm /etc/nginx/conf.d/default.conf

# COPY php configs
COPY ./configs/php/php.ini /etc/php/php.ini
COPY ./configs/php/php-fpm.conf /etc/php/php-fpm.conf
COPY ./configs/php/php-fpm.d/www.conf /etc/php/fpm.d/www.conf

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
