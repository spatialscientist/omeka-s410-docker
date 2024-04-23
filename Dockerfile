FROM php:7.4-apache
#FROM php:apache

# Omeka-S web publishing platform for digital heritage collections (https://omeka.org/s/)
# Initial maintainer: Godwin Yeboah - Warwick Research Computing
LABEL maintainer_name="Godwin Yeboah"
LABEL maintainer_email="g.yeboah@warwick.ac.uk"
LABEL maintainer_email2="yeboahgodwin@gmail.com"
LABEL description="Docker for Omeka-S (version 4.1.0) \
web publishing platform for digital heritage collections (https://omeka.org/s/)."

RUN a2enmod rewrite

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update && apt-get -qq -y upgrade
RUN apt-get -qq update && apt-get -qq -y --no-install-recommends install \
    unzip \
    zip \
    curl \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libwebp-dev \
    libmcrypt-dev \
    nano \
    libpng-dev \
    libjpeg-dev \
    libmemcached-dev \
    zlib1g-dev \
    imagemagick \
    libmagickwand-dev

# Install the PHP extensions we need
RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/
RUN docker-php-ext-install -j$(nproc) iconv pdo pdo_mysql mysqli gd xml xmlrpc xmlwriter calendar json
RUN pecl install mcrypt-1.0.4 && docker-php-ext-enable mcrypt && pecl install imagick && docker-php-ext-enable imagick 
RUN docker-php-ext-install exif && docker-php-ext-enable exif

# Download Omeka S 4.0.4 and move to appropriate folder and change ownership
RUN curl -J -L -s -k \
    'https://github.com/omeka/omeka-s/releases/download/v4.1.0/omeka-s-4.1.0.zip' \
    -o /var/www/omeka.zip \
&&  unzip -q /var/www/omeka.zip -d /var/www/ \
&&  rm /var/www/omeka.zip \
&&  rm -rf /var/www/html \
&&  mv /var/www/omeka-s/ /var/www/html \
&&  chown -R www-data:www-data /var/www/html

COPY ./.htaccess /var/www/html/.htaccess
COPY ./imagemagick-policy.xml /etc/ImageMagick/policy.xml
COPY ./imagemagick-policy.xml /etc/ImageMagick/policy.xml
COPY ./.htaccess /var/www/html/.htaccess

# Add Omeka-S-module-common which is required for installing EasyAdmin (next install after this)
RUN curl -J -L -s -k \
    'https://gitlab.com/Daniel-KM/Omeka-S-module-Common/-/archive/3.4.54/Omeka-S-module-Common-3.4.54.zip' \
    -o /var/www/common.zip \
&&  unzip -q /var/www/common.zip -d /var/www/ \
&&  rm /var/www/common.zip \
&&  mv /var/www/Omeka-S-module-Common-3.4.54/ /var/www/html/modules/Common \
&&  chown -R www-data:www-data /var/www/html/modules

# Install EasyAdmin module so that you can use that module to install other modules/themes.
RUN curl -J -L -s -k \
    'https://github.com/Daniel-KM/Omeka-S-module-EasyAdmin/releases/download/3.4.16/EasyAdmin-3.4.16.zip' \
    -o /var/www/easyadmin.zip \
&&  unzip -q /var/www/easyadmin.zip -d /var/www/ \
&&  rm /var/www/easyadmin.zip \
&&  mv /var/www/EasyAdmin /var/www/html/modules \
&&  chown -R www-data:www-data /var/www/html/modules

#Copy modified .htaccess
COPY ./.htaccess /var/www/html/.htaccess

# Create one volume for files and config
RUN mkdir -p /var/www/html/volume/config/ && mkdir -p /var/www/html/volume/files/
COPY ./database.ini /var/www/html/volume/config/
RUN rm /var/www/html/config/database.ini \
&& ln -s /var/www/html/volume/config/database.ini /var/www/html/config/database.ini \
&& rm -Rf /var/www/html/files \
&& ln -s /var/www/html/volume/files /var/www/html/files \
&& chown -R www-data:www-data /var/www/html \
&& chown -R www-data:www-data /var/www/html/ \
&& chmod 600 /var/www/html/volume/config/database.ini \
&& chmod 600 /var/www/html/.htaccess

VOLUME /var/www/html/volume/

CMD ["apache2-foreground"]
