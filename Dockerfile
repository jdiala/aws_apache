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
    php72 \
    php72-opcache \
    php72-mysqlnd \
    php72-mbstring \
    php72-xml \
    php72-gd \
    php72-fpm \
    && rm -rf /var/cache/yum/* \
    && yum clean all

RUN sed -i '/<IfModule mime_module>/i <FilesMatch \\.php\$>\n\ \ \ \ SetHandler "proxy:fcgi://127.0.0.1:9000"\n<\/FilesMatch>\n' /etc/httpd/conf/httpd.conf

RUN echo 'IncludeOptional sites-enabled/*.conf' >> /etc/httpd/conf/httpd.conf 

RUN mkdir /etc/httpd/sites-available \
    && mkdir /etc/httpd/sites-enabled \
    && echo $'<VirtualHost *:80>\n\
    ServerName localhost\n\
    DocumentRoot /var/www/html/web/\n\
</VirtualHost>' > /etc/httpd/sites-available/www.conf

RUN ln -s /etc/httpd/sites-available/www.conf /etc/httpd/sites-enabled/www.conf

EXPOSE 80 443

RUN chown -R apache:apache /var/www/html \
    && chmod 770 -R /var/www/html \
    && chmod -R g+w /var/www/html

RUN mkdir /var/www/html/web/ \
    && echo '<?php phpinfo();' > /var/www/html/web/index.php

COPY run.sh /run.sh
RUN chmod a+rx /run.sh

ENTRYPOINT ["/run.sh"]