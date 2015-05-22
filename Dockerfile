FROM debian:wheezy

RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl

ENV DEBIAN_FRONTEND noninteractive

RUN useradd -u 1000 docker && apt-get update && apt-get install -y wget

RUN echo "deb http://packages.dotdeb.org wheezy all" > /etc/apt/sources.list.d/dotdeb.list \
    && echo "deb-src http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list.d/dotdeb.list \
    && wget -O - http://www.dotdeb.org/dotdeb.gpg | apt-key add - \
    && echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list \
    && wget --no-check-certificate -O - https://download.newrelic.com/548C16BF.gpg | apt-key add -


RUN apt-get update && apt-get install -y vim make git whiptail mlocate net-tools curl procps \
    re2c php5-cli php5-fpm php5-mysql mysql-client php5-intl php5-recode \
    php5-snmp php5-mcrypt php5-memcache php5-memcached php5-imagick php5-curl php5-xsl php5-snmp \
    php5-dev php5-tidy php5-xmlrpc php5-gd php5-pspell php-pear php-apc nginx pkg-config newrelic-php5

RUN sed -i "s/;date.timezone =/date.timezone = America\/Sao_Paulo/" /etc/php5/cli/php.ini \
    && sed -i "s/;date.timezone =/date.timezone = America\/Sao_Paulo/" /etc/php5/fpm/php.ini \
    && sed -i "s/short_open_tag = On/short_open_tag = Off/" /etc/php5/cli/php.ini \
    && sed -i "s/short_open_tag = On/short_open_tag = Off/" /etc/php5/fpm/php.ini \
    && sed -i "s/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/" /etc/php5/cli/php.ini \
    && sed -i "s/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/" /etc/php5/fpm/php.ini \
    && sed -i "s/display_errors = Off/display_errors = On/" /etc/php5/cli/php.ini \
    && sed -i "s/display_errors = Off/display_errors = On/" /etc/php5/fpm/php.ini \
    && sed -i "s/display_startup_errors = Off/display_startup_errors = On/" /etc/php5/cli/php.ini \
    && sed -i "s/display_startup_errors = Off/display_startup_errors = On/" /etc/php5/fpm/php.ini \
    && sed -i "s/www-data/docker/g" /etc/php5/fpm/pool.d/www.conf \
    && sed -i "s/pm.max_children = 5/pm.max_children = 35/" /etc/php5/fpm/pool.d/www.conf \
    && sed -i "s/pm.start_servers = 2/pm.start_servers = 10/" /etc/php5/fpm/pool.d/www.conf \
    && sed -i "s/pm.min_spare_servers = 1/pm.min_spare_servers = 10/" /etc/php5/fpm/pool.d/www.conf \
    && sed -i "s/pm.max_spare_servers = 3/pm.max_spare_servers = 17/" /etc/php5/fpm/pool.d/www.conf \
    && sed -i "s/;pm.max_requests = 500/pm.max_requests = 250/" /etc/php5/fpm/pool.d/www.conf \
    && sed -i "s/www-data;/docker;\\ndaemon off;/g" /etc/nginx/nginx.conf \
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/bin/composer


# COPY xdebug.ini /etc/php5/mods-available/xdebug.ini
RUN pecl install xdebug-2.3.2
RUN echo "zend_extension=/usr/lib/php5/20100525/xdebug.so" > /etc/php5/mods-available/xdebug.ini \
    && echo "\n\nxdebug.remote_enable=1" >> /etc/php5/mods-available/xdebug.ini \
    && echo "xdebug.remote_handler=dbgp" >> /etc/php5/mods-available/xdebug.ini \
    && echo "xdebug.remote_mode=req" >> /etc/php5/mods-available/xdebug.ini \
    && echo "xdebug.remote_port=9001" >> /etc/php5/mods-available/xdebug.ini \
    && echo "xdebug.remote_autostart=1" >> /etc/php5/mods-available/xdebug.ini \
    && echo "xdebug.remote_connect_back=1" >> /etc/php5/mods-available/xdebug.ini \
    && echo "\n\nxdebug.var_display_max_depth = -1 " >> /etc/php5/mods-available/xdebug.ini \
    && echo "xdebug.var_display_max_children = -1" >> /etc/php5/mods-available/xdebug.ini \
    && echo "xdebug.var_display_max_data = -1 " >> /etc/php5/mods-available/xdebug.ini \
    && echo "\n\nxdebug.remote_host="`/sbin/ip route|awk '/default/ { print $3 }'` >> /etc/php5/mods-available/xdebug.ini \
    && php5enmod xdebug

RUN apt-get clean

COPY run.sh /run.sh
RUN chmod a+x /run.sh

EXPOSE 80

ENTRYPOINT ["/run.sh"]
