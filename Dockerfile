FROM amazonlinux:2
LABEL maintainer="jdiala@keymind.com"

RUN amazon-linux-extras install php7.2

RUN yum -y update \
    && yum --setopt=tsflags=nodocs -y install \
    httpd \
#    mod_ssl \
    rsync \
    which \
    patch \
    zip \
    unzip \
    git \
    php-opcache \
    php-mysqlnd \
    php-mbstring \
    php-xml \
    php-gd \
    php-fpm \
    && rm -rf /var/cache/yum/* \
    && yum clean all

RUN sed -i '{ s/memory_limit = 128M/memory_limit = -1/i}' /etc/php.ini

RUN sed -i '/<IfModule mime_module>/i <FilesMatch \\.php\$>\n\ \ \ \ SetHandler "proxy:fcgi://127.0.0.1:9000"\n<\/FilesMatch>\n' /etc/httpd/conf/httpd.conf

RUN echo 'IncludeOptional sites-enabled/*.conf' >> /etc/httpd/conf/httpd.conf 

RUN mkdir /etc/httpd/sites-available \
    && mkdir /etc/httpd/sites-enabled \
    && echo $'<VirtualHost *:80>\n\
    ServerName localhost\n\
    DocumentRoot /var/www/html/web/\n\
    <Directory /var/www/html/web>\n\
        Options Indexes FollowSymLinks\n\
	AllowOverride All\n\
    </Directory>\n\
</VirtualHost>' > /etc/httpd/sites-available/www.conf

RUN ln -s /etc/httpd/sites-available/www.conf /etc/httpd/sites-enabled/www.conf

EXPOSE 80 443

RUN chown -R apache:apache /var/www/html \
    && chmod 770 -R /var/www/html \
    && chmod -R g+w /var/www/html

ENV PATH "/composer/vendor/bin:$PATH"
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /composer
ENV COMPOSER_VERSION 1.9.3

RUN curl -s -f -L -o /tmp/installer.php https://raw.githubusercontent.com/composer/getcomposer.org/da290238de6d63faace0343efbdd5aa9354332c5/web/installer \
 && php -r " \
    \$signature = '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410'; \
    \$hash = hash('SHA384', file_get_contents('/tmp/installer.php')); \
    if (!hash_equals(\$signature, \$hash)) { \
        unlink('/tmp/installer.php'); \
        echo 'Integrity check failed, installer is either corrupt or worse.' . PHP_EOL; \
        exit(1); \
    }" \
 && php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSION} \
 && rm /tmp/installer.php \
 && composer --ansi --version --no-interaction

RUN mkdir /var/www/html/web/ \
    && echo '<?php phpinfo();' > /var/www/html/web/index.php

COPY run.sh /run.sh
RUN chmod a+rx /run.sh

ENTRYPOINT ["/run.sh"]