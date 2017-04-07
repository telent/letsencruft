FROM debian:testing
RUN apt-get -y update
RUN apt-get -y install \
 certbot\
 nginx \
 python-certbot-nginx
RUN rm /etc/nginx/sites-enabled/*
RUN mkdir -p /etc/letsencrypt /var/lib/letsencrypt/.well-known
COPY nginx.80.conf.template /etc/nginx/site-templates/certbot.site.conf.template
COPY rc request-cert /sbin/
EXPOSE 80
EXPOSE 443
COPY nginx.*.conf /etc/nginx/conf.d/
