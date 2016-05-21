server {
	listen 80 default_server;
	listen [::]:80 default_server ipv6only=on;

	listen 443 ssl;
	ssl_certificate /etc/letsencrypt/live/pixelhandler.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/pixelhandler.com/privkey.pem;

	passenger_enabled on;
	rails_env	production;

	root /home/deploy/www/blog-api/current/public;

	server_name api.pixelhandler.com;

	# redirect server error pages to the static page /50x.html
	error_page 500 502 503 504 /50x.html;
	location = /50x.html {
		root html;
	}
}
