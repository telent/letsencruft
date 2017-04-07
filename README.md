# Letsencruft - a simple TLS Nginx reverse proxy config

This Docker image allows you to add HTTPS support, using free
certificates issued by [Lets Encrypt](https://letsencrypt.org/), to
your web app with minimal fuss.  It was created mostly so that I could
easily stand up
a
[Mastodon](https://github.com/tootsuite/mastodon/blob/master/README.md) instance
without having to connect to it using plaintext; time will tell if it
proves more generally useful.

*This is alpha software and it may eat your keys*


## Features and points of note

* based on Debian Testing (9.0 at the time of writing)
* installs nginx (1.10.3) and [Certbot](https://certbot.eff.org/)
* knows how to proxy websocket connections (i.e. sends `Connection` and
  `Upgrade` headers when required) out of the box
* requires volumes for the certbot keys/secrets
* you provide the required nginx vhost definition as a volume
* environment variables can be interpolated into the config using `%{NAME}`
  syntax 

## Quick example using Docker Compose

Add a clause to `docker-compose.yml` that looks something like this.
Both of the environment variables are required for use when applying
for the certificate.

```
  nginx:
    image: telent/letsencruft:latest
    ports:
      - "80:80"
      - "443:443"
    environment:
      - EMAIL=you@example.com
      - DOMAIN=www.example.com
    volumes:
      - ./nginx/nginx.examplecom.site.conf.template:/etc/nginx/site-templates/examplecom.site.conf.template
      - ./data/letsencrypt/wks:/var/lib/letsencrypt/.well-known
      - ./data/letsencrypt/etc:/etc/letsencrypt
    command: /bin/sh /sbin/rc
```

If you mount your vhost config in `/etc/nginx/sites-enabled` it will
be used as-is.  If you mount it in `/etc/nginx/site-templates` _and ensure it has a `.template` suffix_, as is
done here, it will be preprocessed when the container starts: this is a
real-life example for my Mastodon instance:


```
server {
  listen 443 default ssl;
  listen [::]:443 default ssl;
  server_name %{DOMAIN};
  ssl_certificate /etc/ssl/%{DOMAIN}.crt;
  ssl_certificate_key /etc/ssl/%{DOMAIN}.key;

  location / {
    proxy_pass http://web:3000;
  }

  location /api/v1/streaming {
    proxy_pass http://streaming:4000;
  } 

}
```

Your vhost can assume it has SSL key and certificate (including any
necessary intermediate certificates) in `/etc/ssl/%{DOMAIN}.{key,crt}`
respectively.


### First time run

You need to run `/sbin/request-cert` inside the container (or more
precisely, inside another container started from this image that uses
the same volume).  So for example

    $ docker-compose run nginx /sbin/request-cert

Until you do this it will use a self-signed certificate, so anybody
connecting to your server will see scary warning from their browser.

### Other things

* Presently your service cannnot listen to port 80 because the default
vhost already does that, and it is needed to respond to the challenges
that Lets Encrypt makes.  At some point I will probably add an
HTTP->HTTPS redirect rule so that at least your users will be
redirected to the real site.

* I haven't needed to try renewals yet, but it should be something like
`docker-compose run nginx certbot --renew`

* Don't forget to back up your key and certificate somewhere safe.

* These instructions assume basic prior knowledge of nginx, docker and
  letsencrypt, but with that in mind, if you find them unclear please
  let me know.  Open a Github issue and let me know what you had
  trouble with and what you would like to see included.

* Find me in the "Fediverse" (Mastodon/GNU Social/Ostatus/whatever we
call it tomorrow)
at [@dan@toot.telent.net](https://toot.telent.net/@dan) if I haven't broken it
