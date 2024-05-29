#!/bin/bash

#Обновляем пакеты ОС
sudo apt update&& apt upgrade -y

#Добавляем репозиторий Bullseye

echo -e "#Debian 11 (Bullseye)

deb http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye main contrib non-free

deb http://deb.debian.org/debian-security/ bullseye-security main contrib non-free
deb-src http://deb.debian.org/debian-security/ bullseye-security main contrib non-free

deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free" >> ./sources.list

#Устанавливаем БД mariadb
sudo apt install mariadb-server -y
sudo systemctl enable mariadb
sudo systemctl start mariadb

#Настраиваем БД

echo -n "Введите имя базы данных для создания: "
read name_base
echo "name_base = $name_base" >> /home/debian/db_nextcloud_info.txt
mysql -u root -e "CREATE DATABASE $name_base DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
echo "БД создана!"

echo -n "Введите имя пользователя  для базы данных: "
read  name_user_base
echo -n "Введите пароль для пользователя созданного выше. Пароль будет скрыт: "
read -s password_user_base
echo "name_user_base = $name_user_base" >> /home/debian/db_nextcloud_info.txt
echo "password_user_base = $password_user_base" >> /home/debian/db_nextcloud_info.txt
mysql -u root -e "CREATE USER ${name_user_base}@localhost IDENTIFIED BY '$password_user_base';"
echo "Пользователь создан!"

echo "Раздача всех прав пользователю на созданную базу данных"
mysql -u root -e "GRANT ALL PRIVILEGES ON $name_base.* TO $name_user_base@localhost IDENTIFIED BY '$password_user_base';"
mysql -u root -e "FLUSH PRIVILEGES;"
echo "БД готова для продолжения установки"

#Настраиваем репозиторий для установки. На момент создания скрипта, актуальный - 8.3

#Устанавливаем пакеты для использования репозиториев по https
sudo apt install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg2
#Добавляем репозиторий
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
#Для нового репозитория загружаем специальный ключ безопасности
wget -qO - https://packages.sury.org/php/apt.gpg | apt-key add -
#Обновляем список пакетов
sudo apt update

#Устанавливаем php и дополнительные модули для взаимодействия PHP-Nextcloud
export PHP_VER=8.3
apt install php${PHP_VER}-fpm php${PHP_VER}-common php${PHP_VER}-zip php${PHP_VER}-xml php${PHP_VER}-intl php${PHP_VER}-gd php${PHP_VER}-mysql php${PHP_VER}-mbstring php${PHP_VER}-curl php${PHP_VER}-imagick php${PHP_VER}-gmp php${PHP_VER}-bcmath libmagickcore-6.q16-6-extra -y

#Настройка php для nextcloud

PHP_WWW_CONF="/etc/php/8.3/fpm/pool.d/www.conf"

PATH_CONF="env\[PATH\] = \/usr\/local\/bin:\/usr\/bin:\/bin"
HOSTNAME_CONF="env\[HOSTNAME\] = \$HOSTNAME"
TMP_CONF="env\[TMP\] = \/tmp"
TMPDIR_CONF="env\[TMPDIR\] = \/tmp"
TEMP_CONF="env\[TEMP\] = \/tmp"

sudo sed -i "s/;${PATH_CONF}/${PATH_CONF}/g" $PHP_WWW_CONF
sudo sed -i "s/;${HOSTNAME_CONF}/${HOSTNAME_CONF}/g" $PHP_WWW_CONF
sudo sed -i "s/;${TMP_CONF}/${TMP_CONF}/g" $PHP_WWW_CONF
sudo sed -i "s/;${TMPDIR_CONF}/${TMPDIR_CONF}/g" $PHP_WWW_CONF
sudo sed -i "s/;${TEMP_CONF}/${TEMP_CONF}/g" $PHP_WWW_CONF


STRING1="\;opcache.enable_cli=0"
STRING1_1="\;opcache.enable_cli=1"
STRING2="\;opcache.interned_strings_buffer=8"
STRING2_2="\;opcache.interned_strings_buffer=32"
STRING3="\;opcache.revalidate_freq=2"
STRING3_1="\;opcache.revalidate_freq=1"
PHP_INI="/etc/php/8.3/fpm/php.ini"

sudo sed -i "s/$STRING1/$STRING1_1/g" $PHP_INI
sudo sed -i "s/$STRING2/$STRING2_2/g" $PHP_INI
sudo sed -i "s/$STRING3/$STRING3_1/g" $PHP_INI

sudo systemctl enable php8.3-fpm
sudo systemctl restart php8.3-fpm

#Установка и настройка nginx

sudo apt install nginx -y

echo -n "Введите имя вашего будущего облачного сервера типа: nextcloud.domain.ru "
read FQDN

echo -n "Введите краткое имя вашего будущего облачного сервера типа: nextcloud "
read SHORT_FQDN

sudo cat > /etc/nginx/sites-enabled/nextcloud.conf <<EOF

server {
        listen 80;
        listen 443 ssl;
        server_name ${FQDN};

        if (\$scheme = 'http') {
            return 301 https://\$host\$request_uri;
        }

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/cert.key;

        root /var/www/nextcloud;

        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        client_max_body_size 10G;
        fastcgi_buffers 64 4K;

        rewrite ^/caldav(.*)\$ /remote.php/caldav\$1 redirect;
        rewrite ^/carddav(.*)\$ /remote.php/carddav\$1 redirect;
        rewrite ^/webdav(.*)\$ /remote.php/webdav\$1 redirect;

        index index.php;
        error_page 403 = /core/templates/403.php;
        error_page 404 = /core/templates/404.php;

        location = /robots.txt {
            allow all;
            log_not_found off;
            access_log off;
        }

        location ~ ^/(data|config|\.ht|db_structure\.xml|README) {
                deny all;
        }

        location ^~ /.well-known {
                location = /.well-known/carddav { return 301 /remote.php/dav/; }
                location = /.well-known/caldav  { return 301 /remote.php/dav/; }
                location = /.well-known/webfinger  { return 301 /index.php/.well-known/webfinger; }
                location = /.well-known/nodeinfo  { return 301 /index.php/.well-known/nodeinfo; }
                location ^~ /.well-known{ return 301 /index.php/\$uri; }
                try_files \$uri \$uri/ =404;
        }

        location / {
                rewrite ^/.well-known/host-meta /public.php?service=host-meta last;
                rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json last;
                rewrite ^(/core/doc/[^\/]+/)\$ \$1/index.html;
                try_files \$uri \$uri/ index.php;
        }

        location ~ ^(.+?\.php)(/.*)?$ {
                try_files \$1 = 404;
                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME \$document_root\$1;
                fastcgi_param PATH_INFO \$2;
                fastcgi_param HTTPS on;
                fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        }

        location ~* ^.+\.(jpg|jpeg|gif|bmp|ico|png|css|js|swf)$ {
                expires modified +30d;
                access_log off;
        }
}
EOF

sudo mkdir /etc/nginx/ssl
cd /etc/nginx/ssl

openssl req -new -x509 -days 1461 -nodes -out cert.pem -keyout cert.key -subj "/C=RU/ST=SPb/L=SPb/O=Global Security/OU=IT Department/CN=${FQDN}/CN=${SHORT_FQDN}"

sudo systemctl stop apache2
sudo systemctl disable apache2
sudo systemctl restart nginx
sudo systemctl enable nginx

#Скачиваем unzip
sudo apt install unzip -y

#Скачиваем и распаковываем послндюю версию nextcloud
sudo wget https://download.nextcloud.com/server/releases/latest.zip -P /tmp/
sudo unzip /tmp/latest.zip -d /tmp/
sudo mv /tmp/nextcloud /var/www
sudo chown -R www-data:www-data /var/www/nextcloud
