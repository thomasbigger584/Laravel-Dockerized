# FOR PRODUCTION

# intermediatory container for building for production
FROM composer:1.7 as build

# needs to be here for composer to work properly even though we arent using a database
COPY database/ database/

COPY composer.json composer.json

# install dependencies for production
RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist \
    --no-ansi \
    --no-dev \
    --no-progress \
    --optimize-autoloader

# image with php and nginx
FROM webdevops/php-nginx:alpine

# copy the nginx configuration through
COPY nginx.conf /opt/docker/etc/nginx/vhost.conf

# copy the project through with www-data user owner permissions
COPY . /var/www/html
RUN rm /var/www/html/bootstrap/cache/*

# copy dependencies from build intermediatory container
COPY --from=build  /app/vendor/ /var/www/html/vendor/

# Read + Write + Execute
RUN chmod 755 -R /var/www/html

RUN chown nginx:nginx -R /var/www/html 

# set the working directory to be where the project is sitting
WORKDIR /var/www/html

# rename the .env.example file to .env if it hasnt been already created, for next step
RUN if [ -f .env.example ] && [ ! -f .env ]; then \
		cp .env.example .env; \
	fi

RUN sed -i.bak "s|APP_ENV=local|APP_ENV=production|g" .env

# generate key thats to be set within .env and clear cache
# wWithout this the page wont load
RUN php artisan key:generate \
	&& php artisan config:cache

USER nginx
