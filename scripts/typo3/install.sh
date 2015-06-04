#!/bin/bash
set -eo pipefail
DEBIAN_FRONTEND=noninteractive

echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --no-check-certificate --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

echo "deb http://ftp.hosteurope.de/mirror/mariadb.org/repo/10.0/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/mariadb.list
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db

echo "deb http://nginx.org/packages/ubuntu/ $(lsb_release -cs) nginx" > /etc/apt/sources.list.d/nginx.list
wget --no-check-certificate --quiet -O - http://nginx.org/keys/nginx_signing.key | sudo apt-key add -

mkdir -p /var/cache/local/preseeding
cat > /var/cache/local/preseeding/mariadb-server.seed <<EOF
mariadb-server-10.0	mysql-server/root_password_again	password vagrant
mariadb-server-10.0	mysql-server/root_password	password vagrant
mariadb-server-10.0	mariadb-server-10.0/really_downgrade	boolean	false
mariadb-server-10.0	mysql-server-5.1/start_on_boot	boolean	true
mariadb-server-10.0	mysql-server-5.1/postrm_remove_databases	boolean	false
EOF
debconf-set-selections -v /var/cache/local/preseeding/mariadb-server.seed

apt-get update
apt-get dist-upgrade -y
apt-get install -y \
  build-essential \
  curl \
  ghostscript \
  git \
  graphicsmagick \
  gsfonts \
  mariadb-client \
  mariadb-server \
  memcached \
  nginx \
  nodejs \
  phantomjs\
  php5 \
  php5-apcu \
  php5-cli \
  php5-common \
  php5-curl \
  php5-dev \
  php5-fpm \
  php5-gd \
  php5-gmp \
  php5-imap \
  php5-intl \
  php5-json \
  php5-mcrypt \
  php5-memcached \
  php5-mysqlnd \
  php5-pgsql \
  php5-pspell \
  php5-readline \
  php5-recode \
  php5-sqlite \
  php5-xmlrpc \
  php5-xsl \
  postgresql-9.4 \
  postgresql-contrib-9.4 \
  libpq-dev \
  libxml2-dev \
  libxslt1-dev \
  redis-server \
  vim-tiny \
  #

# configure nginx
cat >/etc/nginx/conf.d/php5-fpm.conf <<EOF
upstream php {
    server unix:/var/run/php5-fpm.sock;
}
EOF

cat >/etc/nginx/nginx.conf <<EOF
user vagrant;
worker_processes 1;
pid /var/run/nginx.pid;

events {
  worker_connections 1024;
}

http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;

  sendfile  on;

  gzip on;
  gzip_disable "msie6";

  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;
}
EOF

mkdir -p /etc/nginx/sites-enabled
cat >/etc/nginx/sites-enabled/local.typo3.org <<'EOF'
server {
  server_name .local.typo3.org;

  listen 80 default_server;
  listen [::]:80 default_server;

  client_max_body_size 64M;

  root /var/www;
  index index.html index.php;

  location / {
    try_files $uri $uri/ @rewrite;
  }

  location ~ [^/]\.php(/|$) {
    include /etc/nginx/fastcgi_params;
    fastcgi_split_path_info ^(.+?\.php)(/.*)$;
    if (!-f $document_root$fastcgi_script_name) {
      return 404;
    }
    fastcgi_pass php;
    fastcgi_index index.php;
    fastcgi_read_timeout 240;
    fastcgi_param SCRIPT_FILENAME $request_filename;
    fastcgi_param SERVER_NAME $http_host;
  }

  location @rewrite {
    rewrite ^ /index.php;
  }
}
EOF

cat >/etc/php5/fpm/pool.d/www.conf <<'EOF'
[www]
user = vagrant
group = vagrant
listen = /var/run/php5-fpm.sock
listen.owner = vagrant
listen.group = vagrant
listen.mode = 0660
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.process_idle_timeout = 30s
pm.max_requests = 1000
pm.status_path = /fpm-status
chdir = /
security.limit_extensions = .php .php3 .php4 .php5
env[TMP] = /tmp/
env[TMPDIR] = /tmp/
env[TEMP] = /tmp/
php_admin_value[session.save_path] = /tmp/
php_admin_value[upload_tmp_dir] = /tmp/
php_admin_value[date.timezone] = Europe/Berlin
php_value[max_execution_time] = 240
php_admin_value[max_input_time] = 240
php_admin_value[memory_limit] = 256M
php_admin_value[post_max_size] = 64M
php_value[upload_max_filesize] = 64M
EOF

# make the vagrant user a postgres admin
sudo -i -u postgres psql postgres <<EOF
CREATE ROLE vagrant WITH SUPERUSER LOGIN;
ALTER USER vagrant WITH PASSWORD 'vagrant';
EOF

# make the vagrant user a postgres admin
mysql -uroot -pvagrant mysql <<EOF
GRANT ALL PRIVILEGES ON *.* TO vagrant@'%' IDENTIFIED BY 'vagrant' WITH GRANT OPTION;
EOF
