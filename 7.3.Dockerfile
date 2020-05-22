FROM php:7.3-fpm

# Set Timezone
ENV TZ=Asia/Shanghai

 # Change application source from deb.debian.org to aliyun source
RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list && \
    sed -i 's/security-cdn.debian.org/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list

# 系统扩展依赖
RUN apt-get update; \
    apt-get upgrade -y; \
    apt autoremove -y lsb-base; \
    apt-get install -y \
    procps \
    git \
    zip unzip \
    libzip-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev

# 安装php扩展
RUN docker-php-ext-install mysqli; \
    docker-php-ext-install pdo_mysql; \
    docker-php-ext-configure gd --with-jpeg-dir=/usr/lib --with-freetype-dir=/usr/include/freetype2 && docker-php-ext-install gd; \
    docker-php-ext-install bcmath; \
    docker-php-ext-configure zip --with-libzip && docker-php-ext-install zip; \
    pecl install -o -f redis &&  rm -rf /tmp/pear && docker-php-ext-enable redis; \
    pecl install swoole && docker-php-ext-enable swoole; \
    pecl install mongodb && docker-php-ext-enable mongodb; \
    pecl install memcached-3.1.3 && docker-php-ext-enable memcached; \
    docker-php-ext-install opcache

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm /var/log/lastlog /var/log/faillog

# Install composer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
	&& curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
	&& php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
	&& php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=1.10.6 \
	&& rm -rf /tmp/composer-setup.php \
	&& composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
	&& composer global require hirak/prestissimo

COPY config/7.3/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
ADD config/7.3/www.conf /usr/local/etc/php-fpm.d/www.conf

CMD ["php-fpm"]

EXPOSE 9000



