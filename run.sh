#!/bin/bash

/usr/sbin/php-fpm --daemonize

rm -f /var/run/httpd/httpd.pid

/usr/sbin/httpd -DFOREGROUND