server {
	listen 80;
	server_name www.pixelhandler.com;

	rewrite ^/(.*)$ https://pixelhandler.com/$1 permanent;
}

server {
	listen 80;
	server_name pixelhandler.com;

	rewrite ^/(.*)$ https://pixelhandler.com/$1 permanent;
}

# HTTPS server
server {
	listen 443 ssl;

	set $rootUrl "/home/deploy/www/pixelhandler-blog/public";
	root $rootUrl;
	charset UTF-8;

	server_name pixelhandler.com;

	ssl_certificate /etc/letsencrypt/live/pixelhandler.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/pixelhandler.com/privkey.pem;

	location / {
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection 'upgrade';
		proxy_set_header Host $host;
		proxy_cache_bypass $http_upgrade;
		add_header Cache-Control "no-cache, no-store, max-age=0";
		proxy_pass http://127.0.0.1:4567;
	}

	location ~* ^/api/(.*) {
		set $api_host          "api.pixelhandler.com";
		set $url_full          "$1";
		proxy_http_version     1.1;
		proxy_set_header       X-Real-IP $remote_addr;
		proxy_set_header       X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header       X-NginX-Proxy true;
		proxy_set_header       Upgrade $http_upgrade;
		proxy_set_header       Connection 'upgrade';
		proxy_set_header       Host $api_host;
		proxy_cache_bypass     $http_upgrade;
		proxy_redirect off;
		proxy_ssl_session_reuse off;
		resolver               8.8.4.4 8.8.8.8 valid=300s;
		resolver_timeout       10s;
		proxy_pass             http://$host/api/$1$is_args$args;
	}

	location ~* ^/sitemap\.xml$ {
    set $s3_file 'sitemap.xml';
		set $s3_bucket 'cdn.pixelhandler.com.s3-website-us-east-1.amazonaws.com';
		proxy_http_version     1.1;
		proxy_set_header       Host $s3_bucket;
		proxy_set_header       Authorization '';
		proxy_hide_header      x-amz-id-2;
		proxy_hide_header      x-amz-request-id;
		proxy_hide_header      Set-Cookie;
		proxy_ignore_headers   "Set-Cookie";
		proxy_buffering        off;
		proxy_intercept_errors on;

		resolver               8.8.4.4 8.8.8.8 valid=300s;
		resolver_timeout       10s;
		proxy_pass             http://$s3_bucket/$s3_file;
	}

	location ~* ^/images/(.*) {
		set $s3_bucket 'cdn.pixelhandler.com.s3-website-us-east-1.amazonaws.com';
		set $url_full         '$1';

		proxy_http_version     1.1;
		proxy_set_header       Host $s3_bucket;
		proxy_set_header       Authorization '';
		proxy_hide_header      x-amz-id-2;
		proxy_hide_header      x-amz-request-id;
		proxy_hide_header      Set-Cookie;
		proxy_ignore_headers   "Set-Cookie";
		proxy_buffering        off;
		proxy_intercept_errors on;

		resolver               8.8.4.4 8.8.8.8 valid=300s;
		resolver_timeout       10s;
		proxy_pass             http://$s3_bucket/images/$1;
	}

	location ~* ^/uploads/(.*) {
		set $s3_bucket 'cdn.pixelhandler.com.s3-website-us-east-1.amazonaws.com';
		set $url_full         '$1';

		proxy_http_version     1.1;
		proxy_set_header       Host $s3_bucket;
		proxy_set_header       Authorization '';
		proxy_hide_header      x-amz-id-2;
		proxy_hide_header      x-amz-request-id;
		proxy_hide_header      Set-Cookie;
		proxy_ignore_headers   "Set-Cookie";
		proxy_buffering        off;
		proxy_intercept_errors on;

		resolver               8.8.4.4 8.8.8.8 valid=300s;
		resolver_timeout       10s;
		proxy_pass             http://$s3_bucket/uploads/$1;
	}

	location ~* ^/wp-content/(.*) {
		set $s3_bucket 'cdn.pixelhandler.com.s3-website-us-east-1.amazonaws.com';
		set $url_full         '$1';

		proxy_http_version     1.1;
		proxy_set_header       Host $s3_bucket;
		proxy_set_header       Authorization '';
		proxy_hide_header      x-amz-id-2;
		proxy_hide_header      x-amz-request-id;
		proxy_hide_header      Set-Cookie;
		proxy_ignore_headers   "Set-Cookie";
		proxy_buffering        off;
		proxy_intercept_errors on;

		resolver               8.8.4.4 8.8.8.8 valid=300s;
		resolver_timeout       10s;
		proxy_pass             http://$s3_bucket/wp-content/$1;
	}

	location ~* \.(?:ico|css|js|jge?g|png|woff)$ {
		set $s3_bucket 'cdn.pixelhandler.com.s3-website-us-east-1.amazonaws.com';
		set $url_full         '$1';

		expires 1y;
		add_header Vary Accept-Encoding;
		add_header Access-Control-Allow-Origin 'https://pixelhandler.com';
		access_log /dev/null;

		proxy_http_version     1.1;
		proxy_set_header       Host $s3_bucket;
		proxy_set_header       Authorization '';
		proxy_hide_header      x-amz-id-2;
		proxy_hide_header      x-amz-request-id;
		proxy_hide_header      Set-Cookie;
		proxy_ignore_headers   "Set-Cookie";
		proxy_buffering        off;
		proxy_intercept_errors on;

		resolver               8.8.4.4 8.8.8.8 valid=300s;
		resolver_timeout       10s;
		proxy_pass             http://$s3_bucket/$1;
	}

	# missing vary header on zippable fonts
	location ~* \.(?:eot|ttf|svg)$ {
		set $s3_bucket 'cdn.pixelhandler.com.s3-website-us-east-1.amazonaws.com';
		set $url_full         '$1';

		expires 1y;
		add_header Vary Accept-Encoding;
		add_header Access-Control-Allow-Origin 'https://pixelhandler.com';
		access_log /dev/null;

		proxy_http_version     1.1;
		proxy_set_header       Host $s3_bucket;
		proxy_set_header       Authorization '';
		proxy_hide_header      x-amz-id-2;
		proxy_hide_header      x-amz-request-id;
		proxy_hide_header      Set-Cookie;
		proxy_ignore_headers   "Set-Cookie";
		proxy_buffering        off;
		proxy_intercept_errors on;

		resolver               8.8.4.4 8.8.8.8 valid=300s;
		resolver_timeout       10s;
		proxy_pass             http://$s3_bucket/$1;
	}

	location ~* \.(?:xml|txt)$ {
		set $s3_bucket 'cdn.pixelhandler.com.s3-website-us-east-1.amazonaws.com';
		set $url_full         '$1';

		add_header Access-Control-Allow-Origin 'https://pixelhandler.com';

		proxy_http_version     1.1;
		proxy_set_header       Host $s3_bucket;
		proxy_hide_header      x-amz-id-2;
		proxy_hide_header      x-amz-request-id;
		proxy_hide_header      Set-Cookie;
		proxy_ignore_headers   "Set-Cookie";
		proxy_buffering        off;
		proxy_intercept_errors on;

		resolver               8.8.4.4 8.8.8.8 valid=300s;
		resolver_timeout       10s;
		proxy_pass             http://$s3_bucket/$1;
	}

	# redirect server error pages to the static page /50x.html
	error_page 500 502 503 504 /50x.html;
	location = /50x.html {
		root /usr/share/nginx/www;
	}
}
